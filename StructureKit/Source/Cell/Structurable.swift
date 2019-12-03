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
    
    static var cellAnyType: UIView.Type { get }
    
    static func reuseIdentifier(for parentView: StructureView) -> String
    
    func configureAny(cell: UIView)
    
}

// MARK: - StructurableForTableView

public protocol StructurableForTableView: Structurable {
    
    associatedtype TableViewCellType: UITableViewCell
    
    static func reuseIdentifierForTableView() -> String
    
    func configure(tableViewCell cell: TableViewCellType)
    
}

public extension StructurableForTableView {
    
    static var cellAnyType: UIView.Type {
        return TableViewCellType.self
    }
    
    static func reuseIdentifier(for parentView: StructureView) -> String {
        switch parentView {
        case .tableView:
            return reuseIdentifierForTableView()
        default:
            fatalError()
        }
    }
    
    func configureAny(cell: UIView) {
        if let cell = cell as? TableViewCellType {
            configure(tableViewCell: cell)
        } else {
            assertionFailure("StructurableForTableView: cell should be subclass of UITableViewCell")
        }
    }
    
    static func reuseIdentifierForTableView() -> String {
        return String(describing: cellAnyType)
    }
    
}

// MARK: - StructurableForCollectionView

public protocol StructurableForCollectionView: Structurable {
    
    associatedtype CollectionViewCellType: UICollectionViewCell
    
    func reuseIdentifierForCollectionView() -> String
    
    func configure(collectionViewCell cell: CollectionViewCellType)
    
}

public extension StructurableForCollectionView {
    
    static var cellAnyType: UIView.Type {
        return CollectionViewCellType.self
    }
    
    func reuseIdentifier(for parentView: StructureView) -> String {
        switch parentView {
        case .collectionView:
            return reuseIdentifierForCollectionView()
        default:
            fatalError()
        }
    }
    
    func configureAny(cell: UIView) {
        if let cell = cell as? CollectionViewCellType {
            configure(collectionViewCell: cell)
        } else {
            assertionFailure("StructurableForTableView: cell should be subclass of UICollectionViewCell")
        }
    }
    
    static func reuseIdentifierForCollectionView() -> String {
        return String(describing: cellAnyType)
    }
    
}

// MARK: - StructurableIdentifable

public protocol StructurableIdentifable {

    func identifyHash(into hasher: inout Hasher)
    
}

extension StructurableIdentifable {
    
    internal func identifyHasher(for StructureView: StructureView) -> Hasher {
        var hasher = Hasher()
        let cell = self as! Structurable
        hasher.combine(type(of: cell).reuseIdentifier(for: StructureView))
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
    
    var shouldHighlightRow: Bool { get }
    
    typealias DidHighlightRow = () -> Void
    
    var didHighlightRow: DidHighlightRow? { get }
    
    typealias DidUnhighlightRow = () -> Void
    
    var didUnhighlightRow: DidUnhighlightRow? { get }
    
}

// MARK: - StructurableSelectable

public protocol StructurableSelectable {
    
    typealias WillSelect = (UIView?) -> IndexPath?
    
    typealias WillDeselect = (UIView?) -> IndexPath?
    
    /// return nil -> no deselction. return true -> deselect animted. return false -> deselect without animation
    typealias DidSelect = (UIView?) -> Bool?
    
    typealias DidDeselect = (UIView?) -> Void
    
    var willSelect: WillSelect? { get }
    
    var willDeselect: WillDeselect? { get }
    
    var didSelect: DidSelect? { get }
    
    var didDeselect: DidDeselect? { get }
    
}

extension StructurableSelectable {
    
    public var willSelect: WillSelect? {
        return nil
    }
    
    public var willDeselect: WillDeselect? {
        return nil
    }
    
    public var didDeselect: DidSelect? {
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

extension StructurableEditable {
    
    public var shouldIndentWhileEditing: Bool {
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

public protocol StructureViewDisplayable {
    
    typealias WillDisplay = (UIView) -> Void
    
    typealias DidEndDisplay = (UIView) -> Void
    
    var willDisplay: WillDisplay? { get }
    
    var didEndDisplay: DidEndDisplay? { get }
    
}

extension StructureViewDisplayable {
    
    public var didEndDisplay: DidEndDisplay? {
        return nil
    }
    
}


// MARK: - StructurableMovable

public protocol StructurableMovable {
    
    typealias CanMove = () -> Bool
    
    typealias DidMove = (IndexPath, IndexPath) -> Void
    
    var canMove: CanMove? { get }
    
    var didMove: DidMove? { get }
    
}

// MARK: - StructurableFocusable

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
