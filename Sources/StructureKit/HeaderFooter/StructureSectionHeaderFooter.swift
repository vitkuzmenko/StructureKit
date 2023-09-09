//
//  StructureSectionHeaderFooter.swift
//  StructureKit
//
//  Created by Vitaliy Kuzmenko on 30.11.2019.
//  Copyright © 2019 Vitaliy Kuzmenko. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif

#if os(iOS) || os(tvOS)
public typealias NativeTableViewHeaderFooterView = UITableViewHeaderFooterView
public typealias NativeCollectionReusableView = UICollectionReusableView
#elseif os(macOS)
public typealias NativeTableViewHeaderFooterView = NSView
public typealias NativeCollectionReusableView = NSView
#endif

// MARK: - StructureSectionHeaderFooter

public protocol StructureSectionHeaderFooter {
        
    static func reuseIdentifierForTableViewHeaderFooter() -> String
    
    static func reuseIdentifierForCollectionReusableSupplementaryView() -> String
    
    static func bundleForNib() -> Bundle?
    
    func _configure(tableViewHeaderFooterView view: NativeTableViewHeaderFooterView, isUpdating: Bool)
    
    func _configure(collectionViewReusableSupplementaryView view: NativeCollectionReusableView, isUpdating: Bool)
    
}

public extension StructureSectionHeaderFooter {

    static func reuseIdentifierForTableViewHeaderFooter() -> String {
        fatalError("Structurable: You should implement method reuseIdentifierForTableView")
    }
    
    static func reuseIdentifierForCollectionReusableSupplementaryView() -> String {
        fatalError("Structurable: You should implement method reuseIdentifierForCollectionView")
    }
    
    static func bundleForNib() -> Bundle? {
        return nil
    }
    
    func _configure(tableViewHeaderFooterView view: NativeTableViewHeaderFooterView, isUpdating: Bool) {
        fatalError("Structurable: You should implement method _configure(tableViewHeaderFooterView:isUpdating:")
    }
    
    func _configure(collectionViewReusableSupplementaryView view: NativeCollectionReusableView, isUpdating: Bool) {
        fatalError("Structurable: You should implement method _configure(collectionViewHeaderFooterView:isUpdating:)")
    }
    
}

// MARK: - StructureTableSectionHeaderFooter

public protocol StructureTableSectionHeaderFooter: StructureSectionHeaderFooter {
    
    associatedtype TableViewHeaderFooterType: NativeTableViewHeaderFooterView
    
    static func reuseIdentifierForTableViewHeaderFooter() -> String
    
    func configure(tableViewHeaderFooterView view: TableViewHeaderFooterType, isUpdating: Bool)
    
}

public extension StructureTableSectionHeaderFooter {
    
    static var tableViewCellType: NativeTableViewHeaderFooterView.Type {
        return TableViewHeaderFooterType.self
    }
        
    func _configure(tableViewHeaderFooterView view: NativeTableViewHeaderFooterView, isUpdating: Bool) {
        if let view = view as? TableViewHeaderFooterType {
            configure(tableViewHeaderFooterView: view, isUpdating: isUpdating)
        } else {
            assertionFailure("StructurableForTableView: cell should be subclass of UITableViewCell")
        }
    }
    
    static func reuseIdentifierForTableViewHeaderFooter() -> String {
        return String(describing: tableViewCellType)
    }
    
}

// MARK: - StructureCollectionSectionHeaderFooter

public protocol StructureCollectionSectionHeaderFooter: StructureSectionHeaderFooter {
    
    associatedtype CollectionViewHeaderFooterType: NativeCollectionReusableView
    
    static func reuseIdentifierForCollectionReusableSupplementaryView() -> String
    
    func configure(collectionViewReusableSupplementaryView view: CollectionViewHeaderFooterType, isUpdating: Bool)
    
}

public extension StructureCollectionSectionHeaderFooter {
    
    static var collectionViewCellType: NativeCollectionReusableView.Type {
        return CollectionViewHeaderFooterType.self
    }
        
    func _configure(collectionViewReusableSupplementaryView view: NativeCollectionReusableView, isUpdating: Bool) {
        if let view = view as? CollectionViewHeaderFooterType {
            configure(collectionViewReusableSupplementaryView: view, isUpdating: isUpdating)
        } else {
            assertionFailure("StructurableForCollectionView: cell should be subclass of UICollectionViewCell")
        }
    }
    
    static func reuseIdentifierForCollectionReusableSupplementaryView() -> String {
        return String(describing: collectionViewCellType)
    }
    
}

// MARK: - StructureTableSectionHeaderFooterContentIdentifable

public protocol StructureSectionHeaderFooterContentIdentifable {
    
    func contentHash(into hasher: inout Hasher)
    
}

extension StructureSectionHeaderFooterContentIdentifable {
    
    internal func contentHasher() -> Hasher {
        var hasher = Hasher()
        contentHash(into: &hasher)
        return hasher
    }
    
}
