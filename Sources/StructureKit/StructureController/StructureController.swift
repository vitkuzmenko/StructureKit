//
//  TableStructureViewController.swift
//  StructureKit
//
//  Created by Vitaliy Kuzmenko on 06/10/16.
//  Copyright © 2016 Vitaliy Kuzmenko. All rights reserved.
//

import UIKit

public enum StructureView {
    case tableView(UITableView)
    case collectionView(UICollectionView)
}

final public class StructureController: NSObject {
    
    internal var structureView: StructureView!
    
    // MARK: - TableView Parameters
    
    internal weak var tableViewDelegate: UITableViewDelegate?
    
    public var tableAnimationRule: TableAnimationRule = .fade
    
    internal var currentTableReloadingHasher: Hasher?
    
    // MARK: - CollectionView Parameters
    
    internal weak var collectionViewDelegate: UICollectionViewDelegate?
    
    public var collectionAnimationRule: CollectionAnimationRule = .animated
    
    internal var currentCollectionReloadingHasher: Hasher?
    
    internal var shouldReload: Bool = false
    
    // MARK: - Structure
    
    public var structure: [StructureSection] = []
    
    internal var structureCast: [StructureCastSection] = []
    
    private var previousStructure: [StructureCastSection] = [] {
        didSet {
            structure.forEach { section in
                section.rows.forEach { object in
                    if let invalidatableCell = object as? StructurableInvalidatable {
                        invalidatableCell.invalidated()
                    }
                }
            }
        }
    }
    
    public func indexPath(for object: StructurableIdentifable) -> IndexPath? {
        let objectIdentifyHasher = object.identifyHasher(for: structureView)
        return structure.indexPath(of: objectIdentifyHasher, StructureView: structureView)?.indexPath
    }
    
    public func header(at section: Int) -> StructureSection.HeaderFooter? {
        if structure.indices.contains(section) {
            return structure[section].header
        }
        return nil
    }
    
    public func footer(at section: Int) -> StructureSection.HeaderFooter? {
        if structure.indices.contains(section) {
            return structure[section].footer
        }
        return nil
    }
    
    public func cellModel(at indexPath: IndexPath) -> Any? {
        if structure.count - 1 >= indexPath.section {
            let section = structure[indexPath.section]
            if section.rows.count - 1 >= indexPath.row {
                return section.rows[indexPath.row]
            }
        }
        return nil
    }
    
    internal func cellCast(at indexPath: IndexPath) -> StructurableCast? {
        if structureCast.count - 1 >= indexPath.section {
            let section = structureCast[indexPath.section]
            if section.rows.count - 1 >= indexPath.row {
                return section.rows[indexPath.row]
            }
        }
        return nil
    }
    
    // MARK: - Registration
    
    public func register(_ tableView: UITableView, cellModelTypes: [Structurable.Type] = [], headerFooterModelTypes: [StructureSectionHeaderFooter.Type] = [], animationRule: TableAnimationRule = .fade, tableViewDelegate: UITableViewDelegate? = nil) {
        
        if self.structureView != nil {
            fatalError("StructureController: Registration may be once per StructureController instance")
        }
    
        self.tableAnimationRule = animationRule
        self.structureView = .tableView(tableView)
        self.tableViewDelegate = tableViewDelegate
        
        tableView.dataSource = self
        tableView.delegate = self
        
        cellModelTypes.forEach { type in
            let identifier = type.reuseIdentifierForTableView()
            let nib = UINib(nibName: identifier, bundle: type.bundleForTableViewCell())
            tableView.register(nib, forCellReuseIdentifier: identifier)
        }
        
        headerFooterModelTypes.forEach { type in
            let identifier = type.reuseIdentifierForTableViewHeaderFooter()
            let nib = UINib(nibName: identifier, bundle: type.bundleForNib())
            tableView.register(nib, forHeaderFooterViewReuseIdentifier: identifier)
        }
    }
    
    public func register(_ collectionView: UICollectionView, cellModelTypes: [Structurable.Type] = [], reusableSupplementaryViewTypes: [String: [StructureSectionHeaderFooter.Type]] = [:], animationRule: CollectionAnimationRule = .animated, collectionViewDelegate: UICollectionViewDelegate? = nil) {
        
        if self.structureView != nil {
            fatalError("StructureController: Registration may be once per StructureController instance")
        }
        
        self.collectionAnimationRule = animationRule
        self.structureView = .collectionView(collectionView)
        self.collectionViewDelegate = collectionViewDelegate
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        cellModelTypes.forEach { type in
            let identifier = type.reuseIdentifierForCollectionView()
            let nib = UINib(nibName: identifier, bundle: type.bundleForCollectionViewCell())
            collectionView.register(nib, forCellWithReuseIdentifier: identifier)
        }
        
        reusableSupplementaryViewTypes.forEach { kind, types in
            types.forEach { type in
                let identifier = type.reuseIdentifierForCollectionReusableSupplementaryView()
                let nib = UINib(nibName: identifier, bundle: type.bundleForNib())
                collectionView.register(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: identifier)
            }
        }
    }
    
    // MARK: - Sctructure Updating
    
    public func set(structure newStructure: [StructureSection]) {
        guard let structureView = structureView else { fatalError("StructureView is not configured") }
        switch structureView {
        case .tableView(let tableView):
            set(structure: newStructure, to: tableView)
        case .collectionView(let collectionView):
            set(structure: newStructure, to: collectionView)
        }
    }
    
    internal func set(structure newStructure: [StructureSection], to tableView: UITableView) {
        switch tableAnimationRule {
        case .none:
            structure = newStructure
            tableView.reloadData()
        default:
            do {
                previousStructure = structureCast
                structureCast = newStructure.cast(for: structureView)
                structure = newStructure
                guard !previousStructure.isEmpty && structure(in: tableView, isEqualTo: previousStructure) else {
                    return tableView.reloadData()
                }
                let diff = try StructureDiffer(from: previousStructure, to: newStructure, StructureView: .tableView(tableView))
                performTableViewReload(tableView, diff: diff, with: tableAnimationRule)
            } catch let error {
                NSLog("StructureController: Can not reload animated. %@", error.localizedDescription)
                tableView.reloadData()
            }
        }
    }
    
    internal func set(structure newStructure: [StructureSection], to collectionView: UICollectionView) {
        if collectionAnimationRule.enabled {
            do {
                previousStructure = structureCast
                structureCast = newStructure.cast(for: structureView)
                structure = newStructure
                guard !previousStructure.isEmpty && structure(in: collectionView, isEqualTo: previousStructure) else {
                    return collectionView.reloadData()
                }
                let diff = try StructureDiffer(from: previousStructure, to: newStructure, StructureView: .collectionView(collectionView))
                performCollectionViewReload(collectionView, diff: diff, animation: collectionAnimationRule)
            } catch let error {
                NSLog("StructureController: Can not reload animated. %@", error.localizedDescription)
                collectionView.reloadData()
            }
        } else {
            structure = newStructure
            collectionView.reloadData()
        }
    }
    
    private func structure(in tableView: UITableView, isEqualTo previousStructure: [StructureCastSection]) -> Bool {
        if tableView.numberOfSections != previousStructure.count {
            return false
        }
        for (index, section) in previousStructure.enumerated() {
            if tableView.numberOfRows(inSection: index) != section.rows.count {
                return false
            }
        }
        return true
    }
    
    private func structure(in collectionView: UICollectionView, isEqualTo previousStructure: [StructureCastSection]) -> Bool {
        if collectionView.numberOfSections != previousStructure.count {
            return false
        }
        for (index, section) in previousStructure.enumerated() {
            if collectionView.numberOfItems(inSection: index) != section.rows.count {
                return false
            }
        }
        return true
    }
        
}

