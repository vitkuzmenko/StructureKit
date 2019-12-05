//
//  StructureSectionHeaderFooter.swift
//  StructureKit
//
//  Created by Vitaliy Kuzmenko on 30.11.2019.
//  Copyright © 2019 Vitaliy Kuzmenko. All rights reserved.
//

import UIKit

// MARK: - StructureSectionHeaderFooter

public protocol StructureSectionHeaderFooter {
    
    static var cellAnyType: UIView.Type { get }
    
    static func reuseIdentifier(for parentView: StructureView) -> String
    
    func configureAny(view: UIView, isUpdating: Bool)
    
}

// MARK: - StructureTableSectionHeaderFooter

public protocol StructureTableSectionHeaderFooter: StructureSectionHeaderFooter {
    
    associatedtype TableViewHeaderFooterType: UITableViewHeaderFooterView
    
    static func reuseIdentifierForTableViewHeaderFooter() -> String
    
    func configure(tableViewHeaderFooterView view: TableViewHeaderFooterType, isUpdating: Bool)
    
}

public extension StructureTableSectionHeaderFooter {
    
    static var cellAnyType: UIView.Type {
        return TableViewHeaderFooterType.self
    }
    
    static func reuseIdentifier(for parentView: StructureView) -> String {
        switch parentView {
        case .tableView:
            return reuseIdentifierForTableViewHeaderFooter()
        default:
            fatalError()
        }
    }
    
    func configureAny(view: UIView, isUpdating: Bool) {
        if let view = view as? TableViewHeaderFooterType {
            configure(tableViewHeaderFooterView: view, isUpdating: isUpdating)
        } else {
            assertionFailure("StructurableForTableView: cell should be subclass of UITableViewCell")
        }
    }
    
    static func reuseIdentifierForTableViewHeaderFooter() -> String {
        return String(describing: cellAnyType)
    }
    
}

// MARK: - StructureTableSectionHeaderFooterContentIdentifable

public protocol StructureTableSectionHeaderFooterContentIdentifable {
    
    func contentHash(into hasher: inout Hasher)
    
}

extension StructureTableSectionHeaderFooterContentIdentifable {
    
    internal func contentHasher() -> Hasher {
        var hasher = Hasher()
        contentHash(into: &hasher)
        return hasher
    }
    
}
