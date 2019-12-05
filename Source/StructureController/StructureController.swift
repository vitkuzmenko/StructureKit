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

final class StructureController: NSObject {
    
    internal var structureView: StructureView!
    
    // MARK: - TableView Parameters
    
    internal weak var tableViewDelegate: UITableViewDelegate?
    
    public var tableAnimationRule: TableAnimationRule = .fade
    
    // MARK: - CollectionView Parameters
    
    internal weak var collectionViewDelegate: UICollectionViewDelegate?
    
    public var collectionViewReloadAnimated: Bool = true
    
    // MARK: - Structure
    
    public var structure: [StructureSection] = []
    
    private var previousStructure: [StructureOldSection] = [] {
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
        
    public func cellModel(at indexPath: IndexPath) -> Any? {
        if structure.count - 1 >= indexPath.section {
            let section = structure[indexPath.section]
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
            let nib = UINib(nibName: identifier, bundle: nil)
            tableView.register(nib, forCellReuseIdentifier: identifier)
        }
        
        headerFooterModelTypes.forEach { type in
            let identifier = type.reuseIdentifierForTableViewHeaderFooter()
            let nib = UINib(nibName: identifier, bundle: nil)
            tableView.register(nib, forHeaderFooterViewReuseIdentifier: identifier)
        }
    }
    
    public func register(_ collectionView: UICollectionView, cellModelTypes: [Structurable.Type] = [], reusableSupplementaryViewTypes: [String: [StructureSectionHeaderFooter.Type]] = [:], reloadAnimated: Bool = true, collectionViewDelegate: UICollectionViewDelegate? = nil) {
        
        if self.structureView != nil {
            fatalError("StructureController: Registration may be once per StructureController instance")
        }
        
        self.collectionViewReloadAnimated = reloadAnimated
        self.structureView = .collectionView(collectionView)
        self.collectionViewDelegate = collectionViewDelegate
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        cellModelTypes.forEach { type in
            let identifier = type.reuseIdentifierForCollectionView()
            let nib = UINib(nibName: identifier, bundle: nil)
            collectionView.register(nib, forCellWithReuseIdentifier: identifier)
        }
        
        reusableSupplementaryViewTypes.forEach { kind, types in
            types.forEach { type in
                let identifier = type.reuseIdentifierForCollectionReusableSupplementaryView()
                let nib = UINib(nibName: identifier, bundle: nil)
                collectionView.register(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: identifier)
            }
        }
    }
    
    // MARK: - Sctructure Updating
    
    public func set(structure newStructure: [StructureSection]) {
        guard let StructureView = structureView else { fatalError("StructureView is not configured") }
        previousStructure = structure.old(for: StructureView)
        structure = newStructure
        switch StructureView {
        case .tableView(let tableView):
            set(structure: newStructure, to: tableView)
        case .collectionView(let collectionView):
            set(structure: newStructure, to: collectionView)
        }
    }
    
    internal func set(structure newStructure: [StructureSection], to tableView: UITableView) {
        guard !previousStructure.isEmpty else {
            return tableView.reloadData()
        }
        switch tableAnimationRule {
        case .none:
            tableView.reloadData()
        default:
            do {
                let diff = try StructureDiffer(from: previousStructure, to: structure, StructureView: .tableView(tableView))
                performTableViewReload(tableView, diff: diff, with: tableAnimationRule)
            } catch let error {
                NSLog("StructureController: Can not reload animated. %@", error.localizedDescription)
                tableView.reloadData()
            }
        }
    }
    
    internal func set(structure newStructure: [StructureSection], to collectionView: UICollectionView) {
        guard !previousStructure.isEmpty else {
            return collectionView.reloadData()
        }
        if collectionViewReloadAnimated {
            do {
                let diff = try StructureDiffer(from: previousStructure, to: structure, StructureView: .collectionView(collectionView))
                performCollectionViewReload(collectionView, diff: diff)
            } catch let error {
                NSLog("StructureController: Can not reload animated. %@", error.localizedDescription)
                collectionView.reloadData()
            }
        } else {
            collectionView.reloadData()
        }
    }
        
}

