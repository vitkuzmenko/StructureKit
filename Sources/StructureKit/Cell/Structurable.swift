//
//  StructureObject.swift
//  StructureKit
//
//  Created by Vitaliy Kuzmenko on 01/11/2019.
//  Copyright © 2019 Vitaliy Kuzmenko. All rights reserved.
//

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif

// MARK: - Structurable

public protocol Structurable {
    
    static func reuseIdentifierForTableView() -> String
    
    static func reuseIdentifierForCollectionView() -> String
    
    static func bundleForTableViewCell() -> Bundle?
    
    static func bundleForCollectionViewCell() -> Bundle?
    
    func _configure(tableViewCell cell: NativeTableViewCell)
    
    func _configure(collectionViewCell cell: NativeCollectionViewCell)
    
}

public extension Structurable {

    static func reuseIdentifierForTableView() -> String {
        fatalError("Structurable: You should implement method reuseIdentifierForTableView")
    }
    
    static func reuseIdentifierForCollectionView() -> String {
        fatalError("Structurable: You should implement method reuseIdentifierForCollectionView")
    }
    
    static func bundleForTableViewCell() -> Bundle? {
        fatalError("Structurable: You should implement method bundleForTableViewCell")
    }
    
    static func bundleForCollectionViewCell() -> Bundle? {
        fatalError("Structurable: You should implement method bundleForCollectionViewCell")
    }
    
    func _configure(tableViewCell cell: NativeTableViewCell) {
        fatalError("Structurable: You should implement method _configure(tableViewCell:)")
    }
    
    func _configure(collectionViewCell cell: NativeCollectionViewCell) {
        fatalError("Structurable: You should implement method _configure(collectionViewCell:)")
    }
    
}

// MARK: - StructurableForTableView

public protocol StructurableForTableView: Structurable {
    
    associatedtype TableViewCellType: NativeTableViewCell
    
    static func reuseIdentifierForTableView() -> String
    
    static func bundleForTableViewCell() -> Bundle?
    
    func configure(tableViewCell cell: TableViewCellType)
    
}

public extension StructurableForTableView {
    
    static var tableViewCellType: NativeView.Type {
        return TableViewCellType.self
    }
        
    func _configure(tableViewCell cell: NativeTableViewCell) {
        if let cell = cell as? TableViewCellType {
            configure(tableViewCell: cell)
        } else {
            assertionFailure("StructurableForTableView: cell should be \(String(describing: TableViewCellType.self))")
        }
    }
    
    static func reuseIdentifierForTableView() -> String {
        return String(describing: tableViewCellType)
    }
    
    static func bundleForTableViewCell() -> Bundle? {
        return nil
    }
    
}

// MARK: - StructurableForCollectionView

public protocol StructurableForCollectionView: Structurable {
    
    associatedtype CollectionViewCellType: NativeCollectionViewCell
    
    static func reuseIdentifierForCollectionView() -> String
    
    static func bundleForCollectionViewCell() -> Bundle?
    
    func configure(collectionViewCell cell: CollectionViewCellType)
    
}

public extension StructurableForCollectionView {
    
    static var collectionViewCellType: CollectionViewCellType.Type {
        return CollectionViewCellType.self
    }
    
    func _configure(collectionViewCell cell: NativeCollectionViewCell) {
        if let cell = cell as? CollectionViewCellType {
            configure(collectionViewCell: cell)
        } else {
            assertionFailure("StructurableForTableView: cell should be \(String(describing: CollectionViewCellType.self))")
        }
    }
    
    static func bundleForCollectionViewCell() -> Bundle? {
        return nil
    }
    
    static func reuseIdentifierForCollectionView() -> String {
        return String(describing: collectionViewCellType)
    }
    
}

// MARK: - StructurableIdentifable

public protocol StructurableIdentifable {

    func identifyHash(into hasher: inout Hasher)
    
}

extension StructurableIdentifable {
    
    internal func identifyHasher(for structureView: StructureView) -> Hasher {
        var hasher = Hasher()
        let cell = self as! Structurable
        switch structureView {
        case .tableView:
            hasher.combine(type(of: cell).reuseIdentifierForTableView())
        case .collectionView:
            hasher.combine(type(of: cell).reuseIdentifierForCollectionView())
        }
        identifyHash(into: &hasher)
        return hasher
    }
    
}

// MARK: - StructurableContentIdentifable

public protocol StructurableContentIdentifable {
    
    func contentHash(into hasher: inout Hasher)
    
}

extension StructurableContentIdentifable {
    
    internal func contentHasher() -> Hasher {
        var hasher = Hasher()
        contentHash(into: &hasher)
        return hasher
    }
    
}

// MARK: - StructurableHeightable

public protocol StructurableHeightable {
    
    func height(for tableView: NativeTableView) -> CGFloat
    
}

// MARK: - StructurableSizable

public protocol StructurableSizable {
    
    func size(for parentView: NativeCollectionView) -> CGSize
    
}

public protocol StructurableAccessoryButtonTappable {
    
    typealias AccessoryButtonTappedAction = (NativeTableViewCell?) -> Void
    
    var accessoryButtonTapped: AccessoryButtonTappedAction? { get }
    
}

public protocol StructurableHighlightable {
    
    typealias DidHighlight = (NativeView) -> Void
    
    typealias DidUnhighlight = (NativeView) -> Void
    
    var shouldHighlight: Bool { get }
    
    var didHighlight: DidHighlight? { get }
    
    var didUnhighlight: DidUnhighlight? { get }
    
}

// MARK: - StructurableSelectable

public protocol StructurableSelectable {
    
    typealias WillSelect = (NativeView?) -> IndexPath?
    
    typealias WillDeselect = (NativeView?) -> IndexPath?
    
    #if os(iOS) || os(tvOS)
    /// return nil -> no deselction. return true -> deselect animted. return false -> deselect without animation
    typealias DidSelect = (NativeView?) -> Bool?
    
    typealias DidDeselect = (NativeView?) -> Void
    #elseif os(macOS)
    
    typealias DidSelect = () -> Bool?
    
    typealias DidDeselect = () -> Void
    
    #endif
    
    // Applicable for collectionView only
    var shouldSelect: Bool { get }
    
    // Applicable for collectionView only
    var shouldDeselect: Bool { get }
    
    // Applicable for tableView only
    var willSelect: WillSelect? { get }
    
    // Applicable for tableView only
    var willDeselect: WillDeselect? { get }
    
    var didSelect: DidSelect? { get }
    
    var didDeselect: DidDeselect? { get }
    
}

public extension StructurableSelectable {
    
    var shouldSelect: Bool {
        return true
    }
    
    var shouldDeselect: Bool {
        return true
    }
    
    var willSelect: WillSelect? {
        return nil
    }
    
    var willDeselect: WillDeselect? {
        return nil
    }
    
    var didDeselect: DidDeselect? {
        return nil
    }
    
}

// MARK: - Delete confirmation

public protocol StructurableDeletable {
    
    var titleForDeleteConfirmationButton: String? { get }
    
}

// MARK: - Swipe Actions

#if os(iOS)

@available(iOS 11.0, *)
public protocol StructurableSwipable {
    
    var leadingSwipeActions: UISwipeActionsConfiguration? { get }
    
    var trailingSwipeActions: UISwipeActionsConfiguration? { get }
    
}

#endif

// MARK: - StructurableEditable

#if os(iOS) || os(tvOS)

public protocol StructurableEditable {
        
    typealias CommitEditing = (NativeTableViewCell.EditingStyle) -> Void
    
    typealias WillBeginEditing = () -> Void
    
    typealias DidEndEditing = () -> Void
    
    var canEdit: Bool { get }

    var editingStyle: NativeTableViewCell.EditingStyle { get }
    
    var shouldIndentWhileEditing: Bool { get }

    var commitEditing: CommitEditing? { get }
    
    var willBeginEditing: WillBeginEditing? { get }
    
    var didEndEditing: DidEndEditing? { get }
    
}

public extension StructurableEditable {
    
    var shouldIndentWhileEditing: Bool {
        return true
    }
    
    var willBeginEditing: WillBeginEditing? {
        return nil
    }
    
    var didEndEditing: DidEndEditing? {
        return nil
    }
    
}

#endif

// MARK: - StructureViewWillDisplay

public protocol StructurableDisplayable {
    
    typealias WillDisplay = (NativeView) -> Void
    
    typealias DidEndDisplay = (NativeView) -> Void
    
    var willDisplay: WillDisplay? { get }
    
    var didEndDisplay: DidEndDisplay? { get }
    
}

public extension StructurableDisplayable {
    
    var didEndDisplay: DidEndDisplay? {
        return nil
    }
    
}


// MARK: - StructurableMovable

#if os(iOS)

public protocol StructurableMovable {
    
    typealias DidMove = (IndexPath, IndexPath) -> Void
    
    var canMove: Bool { get }
    
    var didMove: DidMove? { get }
    
}

#endif

#if os(macOS)

public protocol StructurableDraggable {
    
    var canDrag: Bool { get }
    
}

public protocol StructurablePasteboardWritable {
 
    func pasteboardWriting(srcIndexPath: IndexPath) -> NSPasteboardWriting?
    
}

#endif

// MARK: - StructurableFocusable

@available(iOS 9.0, *)
public protocol StructurableFocusable {
    
    typealias CanFocus = () -> Bool
    
    var canFocus: CanFocus? { get }
    
}

// MARK: - StructurableSpringLoadable

#if os(iOS)

@available(iOS 11.0, *)
public protocol StructurableSpringLoadable {
    
    typealias DidBeginMultipleSelection = (UISpringLoadedInteractionContext) -> Bool
    
    var shouldSpringLoad: DidBeginMultipleSelection? { get }
    
}

#endif

// MARK: - StructurableIndentable

public protocol StructurableIndentable {
    
    var indentationLevel: Int { get }
    
}

// MARK: - StructurableMultipleSelectable

@available(iOS 13.0, *)
public protocol StructurableMultipleSelectable {
    
    typealias DidBeginMultipleSelection = () -> Void
    
    var shouldBeginMultipleSelection: Bool { get }
    
    var didBeginMultipleSelection: DidBeginMultipleSelection? { get }
    
}

// MARK: - StructurableContextualMenuConfigurable

#if os(iOS)

@available(iOS 13.0, *)
public protocol StructurableContextualMenuConfigurable {
    
    typealias ContextMenuConfiguration = (CGPoint) -> UIContextMenuConfiguration?
    
    var contextMenuConfiguration: ContextMenuConfiguration? { get }
    
}

#endif

// MARK: - StructurableInvalidatable

public protocol StructurableInvalidatable {
    func invalidated()
}
