//
//  StructureObject.swift
//  StructureKit
//
//  Created by Vitaliy Kuzmenko on 01/11/2019.
//  Copyright © 2019 Vitaliy Kuzmenko. All rights reserved.
//

import UIKit

// MARK: - Structurable

public protocol Structurable {
    
    static func reuseIdentifierForTableView() -> String
    
    static func reuseIdentifierForCollectionView() -> String
    
    func _configure(tableViewCell cell: UITableViewCell)
    
    func _configure(collectionViewCell cell: UICollectionViewCell)
    
}

public extension Structurable {

    static func reuseIdentifierForTableView() -> String {
        fatalError("Structurable: You should implement method reuseIdentifierForTableView")
    }
    
    static func reuseIdentifierForCollectionView() -> String {
        fatalError("Structurable: You should implement method reuseIdentifierForCollectionView")
    }
    
    func _configure(tableViewCell cell: UITableViewCell) {
        fatalError("Structurable: You should implement method _configure(tableViewCell:)")
    }
    
    func _configure(collectionViewCell cell: UICollectionViewCell) {
        fatalError("Structurable: You should implement method _configure(collectionViewCell:)")
    }
    
}

// MARK: - StructurableForTableView

public protocol StructurableForTableView: Structurable {
    
    associatedtype TableViewCellType: UITableViewCell
    
    static func reuseIdentifierForTableView() -> String
    
    func configure(tableViewCell cell: TableViewCellType)
    
}

public extension StructurableForTableView {
    
    static var tableViewCellType: UIView.Type {
        return TableViewCellType.self
    }
        
    func _configure(tableViewCell cell: UITableViewCell) {
        if let cell = cell as? TableViewCellType {
            configure(tableViewCell: cell)
        } else {
            assertionFailure("StructurableForTableView: cell should be \(String(describing: TableViewCellType.self))")
        }
    }
    
    static func reuseIdentifierForTableView() -> String {
        return String(describing: tableViewCellType)
    }
    
}

// MARK: - StructurableForCollectionView

public protocol StructurableForCollectionView: Structurable {
    
    associatedtype CollectionViewCellType: UICollectionViewCell
    
    static func reuseIdentifierForCollectionView() -> String
    
    func configure(collectionViewCell cell: CollectionViewCellType)
    
}

public extension StructurableForCollectionView {
    
    static var collectionViewCellType: UIView.Type {
        return CollectionViewCellType.self
    }
    
    func _configure(collectionViewCell cell: UICollectionViewCell) {
        if let cell = cell as? CollectionViewCellType {
            configure(collectionViewCell: cell)
        } else {
            assertionFailure("StructurableForTableView: cell should be \(String(describing: CollectionViewCellType.self))")
        }
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
    
    func height(for tableView: UITableView) -> CGFloat
    
}

// MARK: - StructurableSizable

public protocol StructurableSizable {
    
    func size(for parentView: UICollectionView) -> CGSize
    
}

public protocol StructurableAccessoryButtonTappable {
    
    typealias AccessoryButtonTappedAction = (UITableViewCell?) -> Void
    
    var accessoryButtonTapped: AccessoryButtonTappedAction? { get }
    
}

public protocol StructurableHighlightable {
    
    typealias DidHighlight = () -> Void
    
    typealias DidUnhighlight = () -> Void
    
    var shouldHighlight: Bool { get }
    
    var didHighlight: DidHighlight? { get }
    
    var didUnhighlight: DidUnhighlight? { get }
    
}

// MARK: - StructurableSelectable

public protocol StructurableSelectable {
    
    typealias WillSelect = (UIView?) -> IndexPath?
    
    typealias WillDeselect = (UIView?) -> IndexPath?
    
    /// return nil -> no deselction. return true -> deselect animted. return false -> deselect without animation
    typealias DidSelect = (UIView?) -> Bool?
    
    typealias DidDeselect = (UIView?) -> Void
    
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

@available(iOS 11.0, *)
public protocol StructurableSwipable {
    
    var leadingSwipeActions: UISwipeActionsConfiguration? { get }
    
    var trailingSwipeActions: UISwipeActionsConfiguration? { get }
    
}

// MARK: - StructurableEditable

public protocol StructurableEditable {
        
    typealias CommitEditing = (UITableViewCell.EditingStyle) -> Void
    
    typealias WillBeginEditing = () -> Void
    
    typealias DidEndEditing = () -> Void
    
    var canEdit: Bool { get }

    var editingStyle: UITableViewCell.EditingStyle { get }
    
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

// MARK: - StructureViewWillDisplay

public protocol StructurableDisplayable {
    
    typealias WillDisplay = (UIView) -> Void
    
    typealias DidEndDisplay = (UIView) -> Void
    
    var willDisplay: WillDisplay? { get }
    
    var didEndDisplay: DidEndDisplay? { get }
    
}

public extension StructurableDisplayable {
    
    var didEndDisplay: DidEndDisplay? {
        return nil
    }
    
}


// MARK: - StructurableMovable

public protocol StructurableMovable {
    
    typealias DidMove = (IndexPath, IndexPath) -> Void
    
    var canMove: Bool { get }
    
    var didMove: DidMove? { get }
    
}

// MARK: - StructurableFocusable

@available(iOS 9.0, *)
public protocol StructurableFocusable {
    
    typealias CanFocus = () -> Bool
    
    var canFocus: CanFocus? { get }
    
}

// MARK: - StructurableSpringLoadable

@available(iOS 11.0, *)
public protocol StructurableSpringLoadable {
    
    typealias DidBeginMultipleSelection = (UISpringLoadedInteractionContext) -> Bool
    
    var shouldSpringLoad: DidBeginMultipleSelection? { get }
    
}

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

@available(iOS 13.0, *)
public protocol StructurableContextualMenuConfigurable {
    
    typealias ContextMenuConfiguration = (CGPoint) -> UIContextMenuConfiguration?
    
    var contextMenuConfiguration: ContextMenuConfiguration? { get }
    
}

// MARK: - StructurableInvalidatable

public protocol StructurableInvalidatable {
    func invalidated()
}
