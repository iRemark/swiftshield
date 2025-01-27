import Foundation

final class SourceKitObfuscator: ObfuscatorProtocol {
    let sourceKit: SourceKit
    let logger: LoggerProtocol
    let dataStore: SourceKitObfuscatorDataStore
    let ignorePublic: Bool
    let namesToIgnore: Set<String>
    weak var delegate: ObfuscatorDelegate?

    init(sourceKit: SourceKit, logger: LoggerProtocol, dataStore: SourceKitObfuscatorDataStore, namesToIgnore: Set<String>, ignorePublic: Bool) {
        self.sourceKit = sourceKit
        self.logger = logger
        self.dataStore = dataStore
        self.ignorePublic = ignorePublic
        self.namesToIgnore = namesToIgnore
    }

    var requests: sourcekitd_requests! {
        sourceKit.requests
    }

    var keys: sourcekitd_keys! {
        sourceKit.keys
    }
}

// MARK: Indexing

extension SourceKitObfuscator {
    func registerModuleForObfuscation(_ module: Module) throws {
        let compilerArguments = SKRequestArray(sourcekitd: sourceKit)
        module.compilerArguments.forEach(compilerArguments.append(_:))
        try module.sourceFiles.sorted { $0.path < $1.path }.forEach { file in
            logger.log("--- Indexing: \(file.name)")
            let req = SKRequestDictionary(sourcekitd: sourceKit)
            req[keys.request] = requests.indexsource
            req[keys.sourcefile] = file.path
            req[keys.compilerargs] = compilerArguments
            let response = try sourceKit.sendSync(req)
            logger.log("--- Preprocessing indexing result of: \(file.name)")
            response.recurseEntities { [unowned self] dict in
                self.preprocess(declarationEntity: dict, ofFile: file, fromModule: module)
            }
            logger.log("--- Processing indexing result of: \(file.name)")
            try response.recurseEntities { [unowned self] dict in
                if self.ignorePublic, dict.isPublic {
                    return
                }
                try self.process(declarationEntity: dict, ofFile: file, fromModule: module)
            }
            let indexedFile = IndexedFile(file: file, response: response)
            self.dataStore.indexedFiles.append(indexedFile)
        }
        dataStore.plists = dataStore.plists.union(module.plists)
    }

    func preprocess(
        declarationEntity dict: SKResponseDictionary,
        ofFile file: File,
        fromModule module: Module
    ) {
        guard let usr: String = dict[keys.usr] else {
            return
        }
        dataStore.fileForUSR[usr] = file
    }

    func process(
        declarationEntity dict: SKResponseDictionary,
        ofFile file: File,
        fromModule module: Module
    ) throws {
        let entityKind: SKUID = dict[keys.kind]!
        guard let kind = entityKind.declarationType() else {
            return
        }
        guard let rawName: String = dict[keys.name],
              let usr: String = dict[keys.usr] else
        {
            return
        }

        let name = rawName.removingParameterInformation

        if namesToIgnore.contains(name) {
            logger.log("* Ignoring \(name) (USR: \(usr)) because its included in ignore-names", verbose: true)
            return
        }
        
        if kind == .enumelement, let parentUSR: String = dict.parent[keys.usr] {
            let codingKeysUSR: Set<String> = ["s:s9CodingKeyP"]
            if try inheritsFromAnyUSR(
                parentUSR,
                anyOf: codingKeysUSR,
                inModule: module
            ) {
                logger.log("* Ignoring \(name) (USR: \(usr)) because its parent enum inherits from CodingKey.", verbose: true)
                return
            } else {
                logger.log("Info: Proceeding with \(name) (USR: \(usr)) because its parent enum does not appear to inherit from CodingKey.)", verbose: true)
            }
        }

        if kind == .property,
           dict.parent != nil,
           let parentKind: SKUID = dict.parent[keys.kind],
           parentKind.declarationType() == .object
        {
            guard let parentUSR: String = dict.parent[keys.usr] else {
                throw logger.fatalError(forMessage: "Parent of \(usr) is has no USR!")
            }
            let codableUSRs: Set<String> = ["s:s7Codablea", "s:SE", "s:Se"]
            if try inheritsFromAnyUSR(
                parentUSR,
                anyOf: codableUSRs,
                inModule: module
            ) {
                logger.log("* Ignoring \(name) (USR: \(usr)) because its parent inherits from Codable.", verbose: true)
                return
            } else {
                logger.log("Info: Proceeding with \(name) (USR: \(usr)) because its parent does not appear to inherit from Codable.)", verbose: true)
            }
        }

        logger.log("* Found declaration of \(name) (USR: \(usr))")
        dataStore.processedUsrs.insert(usr)

        let receiver: String? = dict[keys.receiver]
        if receiver == nil {
            dataStore.usrRelationDictionary[usr] = dict
        }
    }
}

// MARK: Obfuscating

extension SourceKitObfuscator {
    @discardableResult
    func obfuscate() throws -> ConversionMap {
        try dataStore.indexedFiles.forEach { index in
            try obfuscate(index: index)
        }
        try dataStore.plists.forEach { plist in
            try obfuscate(plist: plist)
        }
        return ConversionMap(obfuscationDictionary: dataStore.obfuscationDictionary)
    }

    func obfuscate(index: IndexedFile) throws {
        logger.log("--- Obfuscating \(index.file.name)")
        var referenceArray = [Reference]()
        index.response.recurseEntities { [unowned self] dict in
            guard let kindId: SKUID = dict[self.keys.kind],
                kindId.referenceType() != nil || kindId.declarationType() != nil,
                let rawName: String = dict[self.keys.name],
                let usr: String = dict[self.keys.usr],
                self.dataStore.processedUsrs.contains(usr),
                let line: Int = dict[self.keys.line],
                let column: Int = dict[self.keys.column],
                dict.isReferencingInternalFramework(dataStore: self.dataStore) == false else {
                return
            }

            let name = rawName.removingParameterInformation
            var obfuscatedName = self.obfuscate(name: name)
            
            let isUppercase = Array(name).first?.isUppercase ?? false;
            if isUppercase {
                obfuscatedName = capitalized(obfuscatedName)
            }
            
            self.logger.log("* Found reference of \(name) (USR: \(usr) at \(index.file.name) (\(line):\(column)) -> now \(obfuscatedName)")
            let reference = Reference(name: name, line: line, column: column)
            referenceArray.append(reference)
        }
        let originalContents = try index.file.read()
        let obfuscatedContents = obfuscate(fileContents: originalContents, fromReferences: referenceArray)
        if let error = delegate?.obfuscator(self, didObfuscateFile: index.file, newContents: obfuscatedContents) {
            throw error
        }
    }

    func obfuscate(plist: File) throws {
        var data = try plist.read()
        let regex = "\\$\\(PRODUCT_MODULE_NAME\\)\\.[^ \n]*<"
        let results = data.match(regex: regex)
        guard results.isEmpty == false else {
            return
        }
        logger.log("--- Obfuscating \(plist.name)")
        for result in results.reversed() {
            let value = String(result.captureGroup(0, originalString: data).dropLast())
            let range = result.captureGroupRange(0, originalString: data)
            let productModuleName = "$(PRODUCT_MODULE_NAME)"
            let currentName = value.components(separatedBy: "\(productModuleName).").last ?? ""
            let protectedName = dataStore.obfuscationDictionary[currentName] ?? currentName
            let newPlistValue = productModuleName + "." + protectedName + "<"
            data = data.replacingCharacters(in: range, with: newPlistValue)
        }
        let newPlist = data
        if let error = delegate?.obfuscator(self, didObfuscateFile: plist, newContents: newPlist) {
            throw error
        }
    }

    func obfuscate(name: String) -> String {
        let cachedResult = dataStore.obfuscationDictionary[name]
        guard cachedResult == nil else {
            return cachedResult!
        }
        
//        let size = 32
//        let letters: [Character] = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
//        let numbers: [Character] = Array("0123456789")
//        let lettersAndNumbers = letters + numbers
//        var randomString = ""
//        for i in 0 ..< size {
//            let characters: [Character] = i == 0 ? letters : lettersAndNumbers
//            let rand = Int.random(in: 0 ..< characters.count)
//            let nextChar = characters[rand]
//            randomString.append(nextChar)
//        }
        
        let randomString = ObfuscatorUtil.obfuscate(name)
        
        guard dataStore.obfuscatedNames.contains(randomString) == false else {
            return obfuscate(name: name)
        }
        dataStore.obfuscatedNames.insert(randomString)
        dataStore.obfuscationDictionary[name] = randomString
        return randomString
    }

    func obfuscate(fileContents: String, fromReferences references: [Reference]) -> String {
        let sortedReferences = references.sorted(by: <)

        var previousReference: Reference!
        var currentReferenceIndex = 0
        var line = 1
        var column = 1
        var currentCharIndex = 0

        var charArray: [String] = Array(fileContents).map(String.init)

        while currentCharIndex < charArray.count, currentReferenceIndex < sortedReferences.count {
            let reference = sortedReferences[currentReferenceIndex]
            if previousReference != nil,
                reference.line == previousReference.line,
                reference.column == previousReference.column {
                // Avoid duplicates.
                currentReferenceIndex += 1
            }
            let currentCharacter = charArray[currentCharIndex]
            if line == reference.line, column == reference.column {
                previousReference = reference
                let originalName = reference.name
                var obfuscatedName = obfuscate(name: originalName)
                
                let isUppercase = Array(reference.name).first?.isUppercase ?? false;
                if isUppercase {
                    obfuscatedName = capitalized(obfuscatedName)
                }
                
//                if reference.name.contains("SceneDelegate".lowercased()) ||
//                    reference.name.lowercased().contains("AppDelegate".lowercased()) ||
//                    reference.name.lowercased().contains("ViewController".lowercased()) ||
//                    reference.name.lowercased().contains("SomeStruct".lowercased()) ||
//                    reference.name.lowercased().contains("SomeEnum".lowercased()) {
//                    obfuscatedName = obfuscatedName.capitalized;
//                }
                
                let wasInternalKeyword = currentCharacter == "`"
                for i in 1 ..< (originalName.count + (wasInternalKeyword ? 2 : 0)) {
                    charArray[currentCharIndex + i] = ""
                }
                charArray[currentCharIndex] = obfuscatedName
                currentReferenceIndex += 1
                currentCharIndex += originalName.count
                column += originalName.utf8Count
                if wasInternalKeyword {
                    charArray[currentCharIndex] = ""
                }
            } else if currentCharacter == "\n" {
                line += 1
                column = 1
                currentCharIndex += 1
            } else {
                column += currentCharacter.utf8Count
                currentCharIndex += 1
            }
        }
        return charArray.joined()
    }
    
    private func capitalized(_ obfuscatedName: String) -> String {
        if obfuscatedName.count > 1 {
            let startIndex = obfuscatedName.index(obfuscatedName.startIndex, offsetBy:0)
            let endIndex = obfuscatedName.index(startIndex, offsetBy:1)
            let result = obfuscatedName.replacingCharacters(
                in: startIndex..<endIndex, with:obfuscatedName.prefix(1).uppercased()
            )
            return result
        }
        return ""
    }
}

extension SourceKitObfuscator {
    func inheritsFromAnyUSR(_ usr: String, anyOf usrs: Set<String>, inModule module: Module) throws -> Bool {
        let usrsKey = usrs.joined(separator: " ")
        if let cache = dataStore.inheritsFromX[usr, default: [:]][usrsKey] {
            return cache
        }

        func result(_ val: Bool) -> Bool {
            dataStore.inheritsFromX[usr, default: [:]][usrsKey] = val
            return val
        }

        let req = SKRequestDictionary(sourcekitd: sourceKit)
        req[keys.request] = requests.cursorinfo
        req[keys.compilerargs] = module.compilerArguments
        req[keys.usr] = usr
        // We have to store the file of the USR because it looks CursorInfo doesn"t returns USRs if you use the wrong one
        //, except if it"s a closed source framework. No idea why it works like that.
        // Hopefully this won"t break in the future.
        let file: File = dataStore.fileForUSR[usr] ?? module.sourceFiles.first!
        req[keys.sourcefile] = file.path
        let cursorInfo = try sourceKit.sendSync(req)
        guard let annotation: String = cursorInfo[keys.annotated_decl] else {
            logger.log("Pretending \(usr) inherits from Codable because SourceKit failed to look it up. This can happen if this USR belongs to an @objc class.", verbose: true)
            return result(true)
        }
        let regex = "usr=\\\"(.\\S*)\\\""
        let regexResult = annotation.match(regex: regex)
        for res in regexResult {
            let inheritedUSR = res.captureGroup(1, originalString: annotation)
            if usrs.contains(inheritedUSR) {
                return result(true)
            } else if try inheritsFromAnyUSR(inheritedUSR, anyOf: usrs, inModule: module) {
                return result(true)
            }
        }
        return result(false)
    }
}

// MARK: SKResponseDictionary Helpers

extension SKResponseDictionary {
    var isPublic: Bool {
        if let kindId: SKUID = self[sourcekitd.keys.kind], let type = kindId.declarationType(), type == .enumelement {
            return parent.isPublic
        }
        guard let attributes: SKResponseArray = self[sourcekitd.keys.attributes] else {
            return false
        }
        guard attributes.count > 0 else {
            return false
        }
        for i in 0 ..< attributes.count {
            guard let attr: SKUID = attributes[i][sourcekitd.keys.attribute] else {
                continue
            }
            guard attr.asString == AccessControl.public.rawValue || attr.asString == AccessControl.open.rawValue else {
                continue
            }
            return true
        }
        return false
    }

    func isReferencingInternalFramework(dataStore: SourceKitObfuscatorDataStore) -> Bool {
        guard let kindId: SKUID = self[sourcekitd.keys.kind] else {
            return false
        }
        let type = kindId.referenceType() ?? kindId.declarationType()
        guard type == .method || type == .property else {
            return false
        }
        guard let usr: String = self[sourcekitd.keys.usr] else {
            return false
        }
        let usrRelationDict = dataStore.usrRelationDictionary
        if let dict: SKResponseDictionary = usrRelationDict[usr], self.dict.data != dict.dict.data {
            return dict.isReferencingInternalFramework(dataStore: dataStore)
        }
        var isReference = false
        recurse(uid: sourcekitd.keys.related) { [unowned self] dict in
            guard isReference == false else {
                return
            }
            guard let usr: String = dict[self.sourcekitd.keys.usr] else {
                return
            }
            if dataStore.processedUsrs.contains(usr) == false {
                isReference = true
            } else if let dict: SKResponseDictionary = usrRelationDict[usr] {
                isReference = dict.isReferencingInternalFramework(dataStore: dataStore)
            }
        }
        return isReference
    }
}


class ObfuscatorUtil {
    
    public static func obfuscate(_ originalName: String) -> String {
        let randomWord = generateRandomWord();
        let result = addfeature(originalName: originalName, randomWord: randomWord)
        return result;
    }
    
    private static func generateRandomWord(_ oldRandomWord: String = "") -> String {
        if oldRandomWord.count > 20 {
            return oldRandomWord;
        }
        
        var randomWord = resoureWordList.randomElement()?.lowercased() ?? ""
        if oldRandomWord.count > 0 {
            randomWord = randomWord.capitalized
        }
        
        /**
             if obfuscatedName.count > 1 {
                 let startIndex = obfuscatedName.index(obfuscatedName.startIndex, offsetBy:0)
                 let endIndex = obfuscatedName.index(startIndex, offsetBy:1)
                 let result = obfuscatedName.replacingCharacters(
                     in: startIndex..<endIndex, with:obfuscatedName.prefix(1).lowercased()
                 )
                 obfuscatedName = result
             }
         */
        
        /**
         let deskTopPath = FileManager.default.urls(
             for: .desktopDirectory, in: .userDomainMask).map(\.path
             ).first ?? ""

         if let wordsFilePath = Bundle.main.path(forResource: deskTopPath+"/web2", ofType: ".txt") {
             do {
                 let wordsString = try String(contentsOfFile: wordsFilePath)
                 let wordLines = wordsString.components(separatedBy: .newlines)
                 let randomLine = wordLines[numericCast(arc4random_uniform(numericCast(wordLines.count)))]
                 randomWord = randomLine.capitalized;

             } catch {
                 print("⚠️ word get error")
             }
         } else {
             print("⚠️ word resource error")
         }

         if randomWord.count == 0 {
             randomWord = generateRandomString();
         }
         */
        
        if oldRandomWord.contains(randomWord) {
            return generateRandomWord(oldRandomWord);
            
        } else {
            return generateRandomWord(oldRandomWord + randomWord);
        }
    }
    
    private static func generateRandomString() -> String {
        let letters: [Character] = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
        let numbers: [Character] = Array("0123456789")
        let lettersAndNumbers = letters + numbers
        var randomString = ""

        let size = 32
        for i in 0 ..< size {
            let characters: [Character] = i == 0 ? letters : lettersAndNumbers
            let rand = Int.random(in: 0 ..< characters.count)
            let nextChar = characters[rand]
            randomString.append(nextChar)
        }
        return randomString
    }
    
    private static func addfeature(originalName: String, randomWord: String) -> String {
        var newName = randomWord;
        
        //model
        if originalName.contains("Models") {
            newName += "Models"
            
        } else if originalName.contains("Model") {
            newName += "Model"
        }
        
        //view
        if originalName.contains("Button") {
            newName += "Button"
            
        } else if originalName.contains("Label") {
            newName += "Label"
            
        } else if originalName.contains("Cell") {
            newName += "Cell"
            
        } else if originalName.contains("TableView") {
            newName += "TableView"
            
        } else if originalName.contains("CollectionView") {
            newName += "CollectionView"
            
        } else if originalName.contains("View") {
            newName += "View"
        }
        
        // controller
        else if originalName.contains("Controllers") {
            newName += "Controllers"
            
        } else if originalName.contains("Controller") {
            newName += "Controller"
            
        } else if originalName.contains("VC") {
            newName += "VC"
            
        }
        
        //other
        else if originalName.contains("Delegate") {
            newName += "Delegate"
            
        } else if originalName.contains("Protocol") {
            newName += "Protocol"
            
        }
        
        
        return newName;
    }
    
    // https://www.cnblogs.com/goodboy-heyang/p/4947321.html
    static let resoureWordList = [
        "send", "check", "upload", "refresh", "attenuation","rest", "change", "add", "remove", "feature",
        "bridge", "bandwidth", "rodcast", "byte", "Proxy","Local", "Server", "Notification", "Location", "Supper",
        "collision", "client", "Ethernet", "forward", "Proxy","flooding", "latency", "physical", "access", "broadcast",
        "newbie", "monitor", "poke", "social", "reliability","cabling", "topology", "Transfer", "multicast", "scalabity",
        "cipher", "ciphertext", "cleartext", "crack", "cryptanalysis","firmware", "filter", "encryption", "Usenet", "Bottle",
        "datagram", "whols", "trivial", "transfer", "gopher","uniform", "purpose", "Hypermedia", "Component", "Cluster",
        "smiley", "router", "tablet", "smtp", "spam","telnet", "uucp", "zeroize", "peace", "council",
        "majesty", "highess", "cable", "reply", "address","message", "switch", "plugin", "forward", "packet",
        "processor", "speed", "database", "letter", "assignment","batch", "bus", "cache", "operator", "concept",
        "explicit", "escape", "evaluate", "entity", "efficiency","demarshal", "declaration", "context", "container", "construct",
        
        
        "bitmap", "bitwise", "brace", "refresh", "bracket","chain", "declaration", "template", "partial", "deduction",
        "global", "generate", "fractal", "form", "facility","explicit", "encapsulation", "efficiency", "dispatch", "directive",
        "hierarchy", "Illinois", "laser", "library", "lvalue","nested", "ordinary", "palette", "pane", "parse",
        "pointer", "postfix", "preprocessor", "prime", "primitive","procedure", "radian", "rvalue", "signal", "splitter",
        "Gopher", "frequency", "expertise", "exhibit", "diagram","complement", "coaxial", "benchmark", "template", "subroutine",
        "independent", "judgment", "maintain", "matrix", "Map","Nyquist", "operand", "permit", "quality", "relay",
        "repeater", "semaphores", "specify", "spanning", "strict","subset", "suppose", "Systolic", "theta", "transaction",
        "update", "vertice", "through", "triggers", "transport","transmit", "phase", "Systolic", "statement", "starvation",
        "software", "sequence", "robustness", "represent", "programs","purpose", "punctuation", "projection", "proficient", "maintanence",
        "boundary", "capacity", "condition", "consist", "conform","cursor", "determine", "gather", "influence", "instruction",
   
//        "unkonwn", "unkonwn", "unkonwn", "unkonwn", "unkonwn","unkonwn", "unkonwn", "unkonwn", "unkonwn", "unkonwn",
//        "unkonwn", "unkonwn", "unkonwn", "unkonwn", "unkonwn","unkonwn", "unkonwn", "unkonwn", "unkonwn", "unkonwn",
//        "unkonwn", "unkonwn", "unkonwn", "unkonwn", "unkonwn","unkonwn", "unkonwn", "unkonwn", "unkonwn", "unkonwn",
//        "unkonwn", "unkonwn", "unkonwn", "unkonwn", "unkonwn","unkonwn", "unkonwn", "unkonwn", "unkonwn", "unkonwn",
//        "unkonwn", "unkonwn", "unkonwn", "unkonwn", "unkonwn","unkonwn", "unkonwn", "unkonwn", "unkonwn", "unkonwn",
//        "unkonwn", "unkonwn", "unkonwn", "unkonwn", "unkonwn","unkonwn", "unkonwn", "unkonwn", "unkonwn", "unkonwn",
//        "unkonwn", "unkonwn", "unkonwn", "unkonwn", "unkonwn","unkonwn", "unkonwn", "unkonwn", "unkonwn", "unkonwn",
//        "unkonwn", "unkonwn", "unkonwn", "unkonwn", "unkonwn","unkonwn", "unkonwn", "unkonwn", "unkonwn", "unkonwn",
//        "unkonwn", "unkonwn", "unkonwn", "unkonwn", "unkonwn","unkonwn", "unkonwn", "unkonwn", "unkonwn", "unkonwn",
//        "unkonwn", "unkonwn", "unkonwn", "unkonwn", "unkonwn","unkonwn", "unkonwn", "unkonwn", "unkonwn", "unkonwn",
        
        
        
    ]

}
