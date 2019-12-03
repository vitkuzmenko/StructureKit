//
//  StructureDiffer.swift
//  StructureKit
//
//  Created by Vitaliy Kuzmenko on 01/11/2019.
//  Copyright © 2019 Vitaliy Kuzmenko. All rights reserved.
//

import Foundation

class StructureDiffer {
    
    enum DifferenceError: Error, LocalizedError {
        
        case insertion, deletion, similarObjects, similarSections
        
        var errorDescription: String? {
            switch self {
            case .insertion:
                return "Attempts to insert row in movable section."
            case .deletion:
                return "Attempts to delete row in movable section."
            case .similarSections:
                return "Structure contains two or more equal section identifiers."
            case .similarObjects:
                return "Structure contains two or more equal objects."
            }
        }
    }
    
    var sectionsToMove: [(from: Int, to: Int)] = []
    
    var sectionsToDelete = IndexSet()
    
    var sectionsToInsert = IndexSet()
    
    var sectionHeadersToReload = IndexSet()
    
    var sectionFootersToReload = IndexSet()
    
    var rowsToMove: [(from: IndexPath, to: IndexPath)] = []
    
    var rowsToDelete: [IndexPath] = []
    
    var rowsToInsert: [IndexPath] = []
    
    var rowsToReload: [IndexPath] = []
    
    init(from oldStructure: [StructureOldSection], to newStructure: [StructureSection], StructureView: StructureView) throws {
        
        for (oldSectionIndex, oldSection) in oldStructure.enumerated() {
            
            if let newSectionIndex = newStructure.firstIndex(where: { $0.identifier == oldSection.identifier }) {
                if oldSectionIndex != newSectionIndex {
                    sectionsToMove.append((from: oldSectionIndex, to: newSectionIndex))
                }
                
                if let oldHeaderHasher = oldSection.headerContentHasher,
                    let newHeaderHasher = newStructure[newSectionIndex].headerContentHasher,
                    oldHeaderHasher.finalize() != newHeaderHasher.finalize() {
                    sectionHeadersToReload.insert(newSectionIndex)
                }
                
                if let oldFooterHasher = oldSection.footerContentHasher,
                    let newFooterHasher = newStructure[newSectionIndex].footerContentHasher,
                    oldFooterHasher.finalize() != newFooterHasher.finalize() {
                    sectionFootersToReload.insert(newSectionIndex)
                }
                
            } else {
                sectionsToDelete.insert(oldSectionIndex)
            }
            
            for (oldRowIndex, oldRow) in oldSection.rows.enumerated() {
                var skipForContentUpdater = false
                let oldIndexPath = IndexPath(row: oldRowIndex, section: oldSectionIndex)
                if let rowIdentifyHasher = oldRow.identifyHasher, let newRow = newStructure.indexPath(of: rowIdentifyHasher, StructureView: StructureView) {
                    let newRowIndexPath = newRow.indexPath
                    if oldIndexPath != newRowIndexPath {
                        if newStructure.contains(where: { $0.identifier == oldSection.identifier }) {
                            let newSection = newStructure[newRowIndexPath.section]
                            if oldStructure.contains(where: { $0.identifier == newSection.identifier }) {
                                rowsToMove.append((from: oldIndexPath, to: newRowIndexPath))
                            } else {
                                rowsToDelete.append(oldIndexPath)
                                skipForContentUpdater = true
                            }
                        } else {
                            rowsToInsert.append(newRowIndexPath)
                        }
                    }
                    if !skipForContentUpdater {
                        var contentHasher = Hasher()
                        if let oldRowContentHasher = oldRow.contentHasher,
                            let newRowContentIdentifable = newRow.cellModel as? StructurableContentIdentifable {
                            newRowContentIdentifable.contentHash(into: &contentHasher)
                            if contentHasher.finalize() != oldRowContentHasher.finalize() {
                                rowsToReload.append(newRowIndexPath)
                            }
                        }
                    }
                } else {
                    rowsToDelete.append(oldIndexPath)
                }
                
            }
        }
        
        for (newSectionIndex, newSection) in newStructure.enumerated() {
            if !oldStructure.contains(where: { $0.identifier == newSection.identifier }) {
                sectionsToInsert.insert(newSectionIndex)
            }
            
            for (newRowIndex, newRow) in newSection.rows.enumerated() {
                if let newRowIdentifable = newRow as? StructurableIdentifable, oldStructure.contains(Structure: newRowIdentifable.identifyHasher(for: StructureView)) {
                    // nothing
                } else {
                    rowsToInsert.append(IndexPath(row: newRowIndex, section: newSectionIndex))
                }
            }
        }
        
        if rowsToDelete.contains(where: { (deletion) -> Bool in
            return sectionsToMove.contains(where: { (movement) -> Bool in
                return movement.from == deletion.section
            })
        }) {
            throw DifferenceError.deletion
        }

        if rowsToInsert.contains(where: { (insertion) -> Bool in
            return sectionsToMove.contains(where: { (movement) -> Bool in
                return movement.to == insertion.section
            })
        }) {
            throw DifferenceError.insertion
        }
        
        var uniqueSections: [StructureSection] = []
        
        for newSection in newStructure {
            if uniqueSections.contains(where: { $0.identifier == newSection.identifier }) {
                throw DifferenceError.similarSections
            } else {
                uniqueSections.append(newSection)
            }
        }
        
        var unique: [Structurable] = []
        
        for section in newStructure {
            for lhs in section.rows {
                if let lhsIdentifable = lhs as? StructurableIdentifable, unique.contains(where: { rhs -> Bool in
                    guard let rhsIdentifable = rhs as? StructurableIdentifable else { return false }
                    let lhsIdentifyHasher = lhsIdentifable.identifyHasher(for: StructureView)
                    let rhsIdentifyHasher = rhsIdentifable.identifyHasher(for: StructureView)
                    return lhsIdentifyHasher.finalize() == rhsIdentifyHasher.finalize()
                }) {
                    throw DifferenceError.similarObjects
                } else {
                    unique.append(lhs)
                }
            }
        }
    }
    
}
