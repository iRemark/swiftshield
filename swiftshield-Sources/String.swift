//
//  Regex.swift
//  swiftprotector
//
//  Created by Bruno Rocha on 1/18/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Foundation

typealias RegexClosure = ((NSTextCheckingResult) -> String?)

extension String {
    var isNotAnEmptyCharacter: Bool {
        return self != " " && self != "\n"
    }
    var isNotUsingClassAsAParameterNameOrProtocol: Bool {
        return self != "`" && self != "{" && self != ":" && self != "_"
    }
    var isNotScopeIdentifier: Bool {
        return self != "public" && self != "open" && self != "private" && self != "dynamic" && self != "internal" && self != "var" && self != "let" && self != "final" && self != "func" && self != "lazy"
    }
    var noSpaces: String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}

extension String {
    func matchRegex(regex: String, mappingClosure: RegexClosure) -> [String] {
        let regex = try! NSRegularExpression(pattern: regex, options: [])
        let nsString = self as NSString
        let results = regex.matches(in: self, options: [], range: NSMakeRange(0, nsString.length))
        return results.map(mappingClosure).flatMap{$0}
    }
    
    static func random(length: Int) -> String {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numbers : NSString = "0123456789"
        let len = UInt32(letters.length)
        var randomString = ""
        for i in 0 ..< length {
            let rand = arc4random_uniform(len)
            let characters: NSString = i == 0 ? letters : letters.appending(numbers as String) as NSString
            var nextChar = characters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        return randomString
    }
}

let standardSwiftClasses: [String:Bool] = ["AnyBidirectionalCollection":true,"AnyCollection":true,"AnyHashable":true,"AnyIndex":true,"AnyIterator":true,"AnyRandomAccessCollection":true,"AnySequence":true,"Array":true,"ArraySlice":true,"AutoreleasingUnsafeMutablePointer":true,"BidirectionalSlice":true,"Bool":true,"CVaListPointer":true,"Character":true,"ClosedRange":true,"ClosedRangeIndex":true,"ClosedRangeIterator":true,"CollectionOfOne":true,"ContiguousArray":true,"CountableClosedRange":true,"CountableRange":true,"DefaultBidirectionalIndices":true,"DefaultIndices":true,"DefaultRandomAccessIndices":true,"Dictionary":true,"Dictionary.Index":true,"DictionaryIterator":true,"DictionaryLiteral":true,"Double":true,"EmptyCollection":true,"EmptyIterator":true,"EnumeratedIterator":true,"EnumeratedSequence":true,"FlattenBidirectionalCollection":true,"FlattenBidirectionalCollectionIndex":true,"FlattenCollection":true,"FlattenCollectionIndex":true,"FlattenIterator":true,"FlattenSequence":true,"Float":true,"Float80":true,"IndexingIterator":true,"Int":true,"Int16":true,"Int32":true,"Int64":true,"Int8":true,"IteratorOverOne":true,"IteratorSequence":true,"JoinedIterator":true,"JoinedSequence":true,"LazyBidirectionalCollection":true,"LazyCollection":true,"LazyDropWhileBidirectionalCollection":true,"LazyDropWhileCollection":true,"LazyDropWhileIndex":true,"LazyDropWhileIterator":true,"LazyDropWhileSequence":true,"LazyFilterBidirectionalCollection":true,"LazyFilterCollection":true,"LazyFilterIndex":true,"LazyFilterIterator":true,"LazyFilterSequence":true,"LazyMapBidirectionalCollection":true,"LazyMapCollection":true,"LazyMapIterator":true,"LazyMapRandomAccessCollection":true,"LazyMapSequence":true,"LazyPrefixWhileBidirectionalCollection":true,"LazyPrefixWhileCollection":true,"LazyPrefixWhileIndex":true,"LazyPrefixWhileIterator":true,"LazyPrefixWhileSequence":true,"LazyRandomAccessCollection":true,"LazySequence":true,"ManagedBufferPointer":true,"Mirror":true,"MutableBidirectionalSlice":true,"MutableRandomAccessSlice":true,"MutableRangeReplaceableBidirectionalSlice":true,"MutableRangeReplaceableRandomAccessSlice":true,"MutableRangeReplaceableSlice":true,"MutableSlice":true,"ObjectIdentifier":true,"OpaquePointer":true,"RandomAccessSlice":true,"Range":true,"RangeReplaceableBidirectionalSlice":true,"RangeReplaceableRandomAccessSlice":true,"RangeReplaceableSlice":true,"Repeated":true,"ReversedCollection":true,"ReversedIndex":true,"ReversedRandomAccessCollection":true,"ReversedRandomAccessIndex":true,"Set":true,"Set.Index":true,"SetIterator":true,"Slice":true,"StaticString":true,"StrideThrough":true,"StrideThroughIterator":true,"StrideTo":true,"StrideToIterator":true,"String":true,"String.CharacterView":true,"String.CharacterView.Index":true,"String.UTF16View":true,"String.UTF16View.Index":true,"String.UTF16View.Indices":true,"String.UTF8View":true,"String.UTF8View.Index":true,"String.UnicodeScalarView":true,"String.UnicodeScalarView.Index":true,"String.UnicodeScalarView.Iterator":true,"UInt":true,"UInt16":true,"UInt32":true,"UInt64":true,"UInt8":true,"UTF16":true,"UTF32":true,"UTF8":true,"UnfoldSequence":true,"UnicodeScalar":true,"UnicodeScalar.UTF16View":true,"Unmanaged":true,"UnsafeBufferPointer":true,"UnsafeBufferPointerIterator":true,"UnsafeMutableBufferPointer":true,"UnsafeMutablePointer":true,"UnsafeMutableRawBufferPointer":true,"UnsafeMutableRawBufferPointer.Iterator":true,"UnsafeMutableRawPointer":true,"UnsafePointer":true,"UnsafeRawBufferPointer":true,"UnsafeRawBufferPointer.Iterator":true,"UnsafeRawPointer":true,"Zip2Iterator":true,"Zip2Sequence":true,"ManagedBuffer":true,"ArithmeticOverflow":true,"CommandLine":true,"FloatingPointClassification":true,"FloatingPointRoundingRule":true,"FloatingPointSign":true,"ImplicitlyUnwrappedOptional":true,"MemoryLayout":true,"Mirror.AncestorRepresentation":true,"Mirror.DisplayStyle":true,"Never":true,"Optional":true,"PlaygroundQuickLook":true,"UnicodeDecodingResult":true,"AbsoluteValuable":true,"AnyObject":true,"Arithmetic":true,"BidirectionalCollection":true,"BinaryFloatingPoint":true,"BinaryInteger":true,"BitwiseOperations":true,"CVarArg":true,"Collection":true,"Comparable":true,"CustomDebugStringConvertible":true,"CustomLeafReflectable":true,"CustomPlaygroundQuickLookable":true,"CustomReflectable":true,"CustomStringConvertible":true,"Equatable":true,"Error":true,"ExpressibleByArrayLiteral":true,"ExpressibleByBooleanLiteral":true,"ExpressibleByDictionaryLiteral":true,"ExpressibleByExtendedGraphemeClusterLiteral":true,"ExpressibleByFloatLiteral":true,"ExpressibleByIntegerLiteral":true,"ExpressibleByNilLiteral":true,"ExpressibleByStringLiteral":true,"ExpressibleByUnicodeScalarLiteral":true,"FixedWidthInteger":true,"FloatingPoint":true,"Hashable":true,"Integer":true,"IntegerArithmetic":true,"IteratorProtocol":true,"LazyCollectionProtocol":true,"LazySequenceProtocol":true,"LosslessStringConvertible":true,"MirrorPath":true,"MutableCollection":true,"OptionSet":true,"RandomAccessCollection":true,"RangeReplaceableCollection":true,"RawRepresentable":true,"Sequence":true,"SetAlgebra":true,"SignedArithmetic":true,"SignedInteger":true,"SignedInteger_":true,"SignedNumber":true,"Strideable":true,"TextOutputStream":true,"TextOutputStreamable":true,"UnicodeCodec":true,"UnsignedInteger":true,"UnsignedInteger_":true,"_Incrementable":true,"NSDataAsset":true,"NSFileProviderExtension":true,"NSLayoutAnchor":true,"NSLayoutConstraint":true,"NSLayoutDimension":true,"NSLayoutManager":true,"NSLayoutXAxisAnchor":true,"NSLayoutYAxisAnchor":true,"NSMutableParagraphStyle":true,"NSParagraphStyle":true,"NSAttributedString":true,"NSShadow":true,"NSStringDrawingContext":true,"NSTextAttachment":true,"NSTextContainer":true,"NSTextStorage":true,"NSMutableAttributedString":true,"NSTextTab":true,"NSRulerView":true,"NSRulerMarker":true,"UIAccessibilityCustomAction":true,"UIAccessibilityCustomRotor":true,"UIAccessibilityCustomRotorItemResult":true,"UIAccessibilityCustomRotorSearchPredicate":true,"UIAccessibilityElement":true,"UIActionSheet":true,"UIAlertController":true,"preferredStyle":true,"actionSheet":true,"UIActivity":true,"UIActivityIndicatorView":true,"UIActivityItemProvider":true,"UIActivityViewController":true,"UIAlertAction":true,"UIAlertView":true,"present(_:animated:completion:)":true,"UIApplication":true,"UIApplicationMain(_:_:_:_:)":true,"shared":true,"UIApplicationShortcutIcon":true,"UIApplicationShortcutItem":true,"UIAttachmentBehavior":true,"UIBarButtonItem":true,"UIToolbar":true,"UINavigationBar":true,"UIBarItem":true,"UIBarButtonItemGroup":true,"UIButton":true,"UIBezierPath":true,"UIBlurEffect":true,"UIVisualEffectView":true,"UICloudSharingController":true,"UICollectionReusableView":true,"UICollectionView":true,"UICollectionViewCell":true,"UICollectionViewController":true,"UICollectionViewFlowLayout":true,"UICollectionViewFlowLayoutInvalidationContext":true,"UICollectionViewFocusUpdateContext":true,"UICollectionViewLayout":true,"UICollectionViewLayoutAttributes":true,"UICollectionViewLayoutInvalidationContext":true,"UICollectionViewTransitionLayout":true,"UICollectionViewUpdateItem":true,"prepare(forCollectionViewUpdates:)":true,"UICollisionBehavior":true,"UIDynamicItemBehavior":true,"UIColor":true,"UIControl":true,"UICubicTimingParameters":true,"UIDatePicker":true,"UIDevice":true,"UIDictationPhrase":true,"UIDocument":true,"UIDocumentInteractionController":true,"UIDocumentMenuViewController":true,"UIDocumentPickerExtensionViewController":true,"UIDocumentPickerViewController":true,"UIDynamicAnimator":true,"UIDynamicBehavior":true,"UIDynamicItemGroup":true,"UIEvent":true,"UIFeedbackGenerator":true,"UIFieldBehavior":true,"UIFocusAnimationCoordinator":true,"UIFocusGuide":true,"UILayoutGuide":true,"UIFocusUpdateContext":true,"UIFont":true,"UIFontDescriptor":true,"matchingFontDescriptors(withMandatoryKeys:)":true,"UIGestureRecognizer":true,"UIGraphicsImageRenderer":true,"UIGraphicsImageRendererContext":true,"UIGraphicsImageRendererFormat":true,"UIGraphicsPDFRenderer":true,"UIGraphicsPDFRendererContext":true,"UIGraphicsPDFRendererFormat":true,"UIGraphicsRenderer":true,"UIGraphicsRendererContext":true,"UIGraphicsRendererFormat":true,"UIGravityBehavior":true,"UIImage":true,"UIImageAsset":true,"UIImagePickerController":true,"UIImageView":true,"UIImpactFeedbackGenerator":true,"UIInputView":true,"UIInputViewController":true,"inputView":true,"UIInterpolatingMotionEffect":true,"UIKeyCommand":true,"UILabel":true,"UILexicon":true,"UILexiconEntry":true,"UILocalizedIndexedCollation":true,"UILocalNotification":true,"UNNotificationRequest":true,"UILongPressGestureRecognizer":true,"UIManagedDocument":true,"UIMarkupTextPrintFormatter":true,"UIMenuController":true,"UIMenuItem":true,"UIMotionEffect":true,"keyPathsAndRelativeValues(forViewerOffset:)":true,"UIMotionEffectGroup":true,"UIMutableApplicationShortcutItem":true,"UIMutableUserNotificationAction":true,"UNNotificationAction":true,"UIUserNotificationAction":true,"UIMutableUserNotificationCategory":true,"UNNotificationCategory":true,"UINavigationController":true,"UINavigationItem":true,"UINib":true,"UINotificationFeedbackGenerator":true,"UIPageControl":true,"UIPageViewController":true,"UIPanGestureRecognizer":true,"UIPasteboard":true,"UIPercentDrivenInteractiveTransition":true,"UIViewControllerAnimatedTransitioning":true,"UIPickerView":true,"UIPinchGestureRecognizer":true,"UIPopoverBackgroundView":true,"UIPopoverBackgroundViewMethods":true,"UIPopoverController":true,"UIViewController":true,"UIPopoverPresentationController":true,"popover":true,"UIPresentationController":true,"UIPress":true,"gestureRecognizers":true,"UIPressesEvent":true,"UIPreviewAction":true,"UIPreviewActionGroup":true,"UIPreviewInteraction":true,"UIPrinter":true,"UIPrinterPickerController":true,"UIPrintFormatter":true,"UIPrintInfo":true,"UIPrintInteractionController":true,"UIPrintPageRenderer":true,"UIPrintPaper":true,"UIProgressView":true,"UIPushBehavior":true,"UIReferenceLibraryViewController":true,"UIRefreshControl":true,"UIRegion":true,"UIResponder":true,"UIRotationGestureRecognizer":true,"UIScreen":true,"UIScreenEdgePanGestureRecognizer":true,"UIScreenMode":true,"UIScrollView":true,"UISearchBar":true,"UISearchBarDelegate":true,"UISearchContainerViewController":true,"UISearchController":true,"UISearchDisplayController":true,"UISearchDisplayDelegate":true,"UISegmentedControl":true,"UISelectionFeedbackGenerator":true,"UISimpleTextPrintFormatter":true,"UISlider":true,"UISnapBehavior":true,"UISplitViewController":true,"UISpringTimingParameters":true,"UIStackView":true,"UIStepper":true,"UIStoryboard":true,"UIStoryboardPopoverSegue":true,"popoverController":true,"UIStoryboardSegue":true,"UIStoryboardUnwindSegueSource":true,"UISwipeGestureRecognizer":true,"UISwitch":true,"UITabBar":true,"UITabBarItem":true,"UITabBarController":true,"UITableView":true,"UITableViewCell":true,"UITableViewController":true,"UITableViewFocusUpdateContext":true,"UITableViewHeaderFooterView":true,"UITableViewRowAction":true,"UITapGestureRecognizer":true,"UITextChecker":true,"UITextField":true,"UITextInputAssistantItem":true,"UITextInputMode":true,"UITextInputStringTokenizer":true,"UITextPosition":true,"UITextRange":true,"UITextSelectionRect":true,"UITextView":true,"UITouch":true,"UITraitCollection":true,"UIUserNotificationCategory":true,"UIUserNotificationSettings":true,"UNNotificationSettings":true,"UIVibrancyEffect":true,"contentView":true,"UIVideoEditorController":true,"UIVideoEditorControllerDelegate":true,"UIView":true,"UIViewPrintFormatter":true,"UIViewPropertyAnimator":true,"UIVisualEffect":true,"UIWebView":true,"UIWindow":true,"NSLayoutManagerDelegate":true,"NSTextAttachmentContainer":true,"NSTextLayoutOrientationProvider":true,"NSTextView":true,"horizontal":true,"vertical":true,"NSTextStorageDelegate":true,"UIAccelerometerDelegate":true,"UIAccessibilityIdentification":true,"UIAccessibilityReadingContent":true,"UIActionSheetDelegate":true,"UIActivityItemSource":true,"UIAdaptivePresentationControllerDelegate":true,"UIAlertViewDelegate":true,"UIAppearance":true,"UIAppearanceContainer":true,"UIApplicationDelegate":true,"UIBarPositioning":true,"UIBarPositioningDelegate":true,"UICloudSharingControllerDelegate":true,"UICollectionViewDataSource":true,"UICollectionViewDataSourcePrefetching":true,"UICollectionViewDelegate":true,"UICollectionViewDelegateFlowLayout":true,"UICollisionBehaviorDelegate":true,"UIContentContainer":true,"UIContentSizeCategoryAdjusting":true,"UICoordinateSpace":true,"coordinateSpace":true,"fixedCoordinateSpace":true,"UIDataSourceModelAssociation":true,"UIDocumentInteractionControllerDelegate":true,"UIDocumentMenuDelegate":true,"UIDocumentPickerDelegate":true,"UIDynamicAnimatorDelegate":true,"UIDynamicItem":true,"UIFocusEnvironment":true,"UIFocusItem":true,"UIGestureRecognizerDelegate":true,"UIGuidedAccessRestrictionDelegate":true,"UIImagePickerControllerDelegate":true,"UIInputViewAudioFeedback":true,"UIKeyInput":true,"UILayoutSupport":true,"topLayoutGuide":true,"bottomLayoutGuide":true,"UINavigationBarDelegate":true,"UINavigationControllerDelegate":true,"UIObjectRestoration":true,"UIPageViewControllerDataSource":true,"UIPageViewControllerDelegate":true,"UIPickerViewAccessibilityDelegate":true,"UIPickerViewDataSource":true,"UIPickerViewDelegate":true,"UIPopoverControllerDelegate":true,"UIPopoverPresentationControllerDelegate":true,"UIPreviewActionItem":true,"UIPreviewInteractionDelegate":true,"UIPrinterPickerControllerDelegate":true,"UIPrintInteractionControllerDelegate":true,"UIResponderStandardEditActions":true,"UIScrollViewAccessibilityDelegate":true,"UIScrollViewDelegate":true,"UISearchControllerDelegate":true,"UISearchResultsUpdating":true,"UISplitViewControllerDelegate":true,"UIStateRestoring":true,"UITabBarControllerDelegate":true,"delegate":true,"UITabBarDelegate":true,"UITableViewDataSource":true,"UITableViewDataSourcePrefetching":true,"UITableViewDelegate":true,"UITextDocumentProxy":true,"textDocumentProxy":true,"UITextFieldDelegate":true,"UITextInput":true,"UITextInputDelegate":true,"UITextInputTokenizer":true,"UITextInputTraits":true,"UITextViewDelegate":true,"UITimingCurveProvider":true,"UIToolbarDelegate":true,"UITraitEnvironment":true,"UIViewAnimating":true,"UIViewControllerContextTransitioning":true,"UIViewControllerInteractiveTransitioning":true,"UIViewControllerPreviewing":true,"UIViewControllerPreviewingDelegate":true,"UIViewControllerRestoration":true,"UIViewControllerTransitionCoordinator":true,"transitionCoordinator":true,"UIViewControllerTransitionCoordinatorContext":true,"UIViewControllerTransitioningDelegate":true,"modalPresentationStyle":true,"custom":true,"transitioningDelegate":true,"UIViewImplicitlyAnimating":true,"UIWebViewDelegate":true,"NSStringDrawingOptions":true,"UIContentSizeCategory":true,"UIFontDescriptorSymbolicTraits":true,"UIRectCorner":true,"CIColor":true,"CIImage":true,"IndexPath":true,"Bundle":true,"NSCoder":true,"NSExceptionName":true,"NSIndexPath":true,"NSNotification.Name":true,"NSObject":true,"RunLoopMode":true,"NSString":true,"NSMutableString":true,"NSValue":true,"NSArray":true,"NSSet":true,"URLResourceValues":true, "Encoding":true, "Element": true, "Key": true, "Value": true, "UIKit": true, "Foundation": true, "CoreGraphics": true]

extension String {
    var isNotASwiftStandardClass: Bool {
        return standardSwiftClasses[self] != true
    }
}
