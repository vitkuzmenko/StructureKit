//
//  TableStructureViewController.swift
//  StructureKit
//
//  Created by Vitaliy Kuzmenko on 06/10/16.
//  Copyright © 2016 Vitaliy Kuzmenko. All rights reserved.
//

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif

#if os(iOS) || os(tvOS)
public typealias NativeView = UIView
public typealias NativeTableView = UITableView
public typealias NativeTableViewCell = UITableViewCell
public typealias NativeTableViewDelegate = UITableViewDelegate

public typealias NativeCollectionView = UICollectionView
public typealias NativeCollectionViewCell = UICollectionViewCell
public typealias NativeCollectionViewDelegate = UICollectionViewDelegate
#elseif os(macOS)
public typealias NativeView = NSView
public typealias NativeTableView = NSTableView
public typealias NativeTableViewCell = NSView
public typealias NativeTableViewDelegate = NSTableViewDelegate

public typealias NativeCollectionView = NSCollectionView
public typealias NativeCollectionViewCell = NSCollectionViewItem
public typealias NativeCollectionViewDelegate = NSCollectionViewDelegate
#endif

public enum StructureView {
    case tableView(NativeTableView)
    case collectionView(NativeCollectionView)
}

final public class StructureController: NSObject {
    
    internal var structureView: StructureView!
    
    // MARK: - TableView Parameters
    
    internal weak var tableViewDelegate: NativeTableViewDelegate?
    
    public var tableAnimationRule: TableAnimationRule = .fade
    
    internal var currentTableReloadingHasher: Hasher?
    
    // MARK: - CollectionView Parameters
    
    internal weak var collectionViewDelegate: NativeCollectionViewDelegate?
    
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
            if section.rows.count - 1 >= indexPath.item {
                return section.rows[indexPath.item]
            }
        }
        return nil
    }
    
    internal func cellCast(at indexPath: IndexPath) -> StructurableCast? {
        if structureCast.count - 1 >= indexPath.section {
            let section = structureCast[indexPath.section]
            if section.rows.count - 1 >= indexPath.item {
                return section.rows[indexPath.item]
            }
        }
        return nil
    }
    
    // MARK: - Registration
    
#if os(iOS) || os(tvOS)
    
    public func register(_ tableView: NativeTableView, cellModelTypes: [Structurable.Type] = [], headerFooterModelTypes: [StructureSectionHeaderFooter.Type] = [], animationRule: TableAnimationRule = .fade, tableViewDelegate: NativeTableViewDelegate? = nil) {
        
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
    
#endif
    
    public func register(_ collectionView: NativeCollectionView, cellModelTypes: [Structurable.Type] = [], reusableSupplementaryViewTypes: [String: [StructureSectionHeaderFooter.Type]] = [:], animationRule: CollectionAnimationRule = .animated, collectionViewDelegate: NativeCollectionViewDelegate? = nil) {
        
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
            #if os(iOS) || os(tvOS)
            let nib = UINib(nibName: identifier, bundle: type.bundleForCollectionViewCell())
            collectionView.register(nib, forCellWithReuseIdentifier: identifier)
            #elseif os(macOS)
            let nib = NSNib(nibNamed: NSNib.Name.init(identifier), bundle: type.bundleForCollectionViewCell())
            collectionView.register(nib, forItemWithIdentifier: NSUserInterfaceItemIdentifier(identifier))
            #endif
        }
        
        reusableSupplementaryViewTypes.forEach { kind, types in
            types.forEach { type in
                let identifier = type.reuseIdentifierForCollectionReusableSupplementaryView()
                #if os(iOS) || os(tvOS)
                let nib = UINib(nibName: identifier, bundle: type.bundleForNib())
                collectionView.register(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: identifier)
                #elseif os(macOS)
                let nib = NSNib(nibNamed: NSNib.Name.init(identifier), bundle: type.bundleForNib())
                collectionView.register(nib, forSupplementaryViewOfKind: kind, withIdentifier: NSUserInterfaceItemIdentifier(identifier))
                #endif
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
    
    internal func set(structure newStructure: [StructureSection], to tableView: NativeTableView) {
        switch tableAnimationRule {
        case .none:
            structure = newStructure
            tableView.reloadData()
        default:
            do {
#if os(iOS) || os(tvOS)
                previousStructure = structureCast
                structureCast = newStructure.cast(for: structureView)
                structure = newStructure
                guard !previousStructure.isEmpty && structure(in: tableView, isEqualTo: previousStructure) else {
                    return tableView.reloadData()
                }
                let diff = try StructureDiffer(from: previousStructure, to: newStructure, StructureView: .tableView(tableView))

                performTableViewReload(tableView, diff: diff, with: tableAnimationRule)
#endif
            } catch let error {
                NSLog("StructureController: Can not reload animated. %@", error.localizedDescription)
                tableView.reloadData()
            }
        }
    }
    
    internal func set(structure newStructure: [StructureSection], to collectionView: NativeCollectionView) {
        if collectionAnimationRule.enabled {
            do {
                previousStructure = structureCast
                structureCast = newStructure.cast(for: structureView)
                structure = newStructure
                if previousStructure.isEmpty || !self.structure(in: collectionView, isEqualTo: previousStructure) {
#if os(iOS)
                    return collectionView.layoutIfNeeded()
#elseif os(macOS)
                    return collectionView.reloadData()
#endif
//                    DispatchQueue.main.async {
//                        collectionView.reloadData()
//                    }
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
    
#if os(iOS) || os(tvOS)
    private func structure(in tableView: NativeTableView, isEqualTo previousStructure: [StructureCastSection]) -> Bool {
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
#endif
    
    private func structure(in collectionView: NativeCollectionView, isEqualTo previousStructure: [StructureCastSection]) -> Bool {
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

