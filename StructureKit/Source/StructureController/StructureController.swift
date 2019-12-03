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
    
    private var StructureView: StructureView!
    
    public weak var scrollViewDelegate: UIScrollViewDelegate?
    
    // MARK: - TableViewParameters
    
    internal weak var tableViewDelegate: UITableViewDelegate?
    
    internal weak var tableViewDataSourcePrefetching: UITableViewDataSourcePrefetching?
        
    // MARK: - CollectionView
    
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
        let objectIdentifyHasher = object.identifyHasher(for: StructureView)
        return structure.indexPath(of: objectIdentifyHasher, StructureView: StructureView)?.indexPath
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
    
    public func register(_ tableView: UITableView, cellModelTypes: [Structurable.Type] = [], headerFooterModelTypes: [StructureSectionHeaderFooter.Type] = [], tableViewDelegate: UITableViewDelegate? = nil, tableViewDataSourcePrefetching: UITableViewDataSourcePrefetching? = nil) {
        
        if self.StructureView != nil {
            fatalError("StructureController: Registration may be once")
        }
        
        self.StructureView = .tableView(tableView)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        cellModelTypes.forEach { type in
            let identifier = type.reuseIdentifier(for: StructureView)
            let nib = UINib(nibName: identifier, bundle: nil)
            tableView.register(nib, forCellReuseIdentifier: identifier)
        }
        
        headerFooterModelTypes.forEach { type in
            let identifier = type.reuseIdentifier(for: StructureView)
            let nib = UINib(nibName: identifier, bundle: nil)
            tableView.register(nib, forHeaderFooterViewReuseIdentifier: identifier)
        }
    }
    
    // MARK: - Sctructure Updating
    
    public func set(structure newStructure: [StructureSection], animation: TableAnimationRule = .fade) {
        guard let StructureView = StructureView else { fatalError("StructureView is not configured") }
        previousStructure = structure.old(for: StructureView)
        structure = newStructure
        switch StructureView {
        case .tableView(let tableView):
            guard !previousStructure.isEmpty else {
                return tableView.reloadData()
            }
            switch animation {
            case .none:
                tableView.reloadData()
            default:
                do {
                    let diff = try StructureDiffer(from: previousStructure, to: structure, StructureView: .tableView(tableView))
                    performTableViewReload(tableView, diff: diff, with: animation)
                } catch let error {
                    NSLog("StructureController: Can not reload animated. %@", error.localizedDescription)
                    tableView.reloadData()
                }
            }
        case .collectionView:
            break
        }
    }
        
}

