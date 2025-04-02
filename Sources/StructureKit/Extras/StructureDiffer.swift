//
//  StructureDiffer.swift
//  StructureKit
//
//  Created by Vitaliy Kuzmenko on 01/11/2019.
//  Copyright © 2019 Vitaliy Kuzmenko. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(macOS)

import Foundation

class StructureDiffer: CustomStringConvertible {
    
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
    
    init(from oldStructure: [StructureCastSection], to newStructure: [StructureSection], structureView: StructureView) throws {
        // Map identifiers for old and new sections
        let oldSectionsById = Dictionary(uniqueKeysWithValues: oldStructure.map { ($0.identifier, $0) })

        // Identify sections to delete
        for (index, oldSection) in oldStructure.enumerated() {
            if !newStructure.contains(where: { $0.identifier == oldSection.identifier }) {
                sectionsToDelete.insert(index)
            }
        }

        // Identify sections to insert or move
        for (newIndex, newSection) in newStructure.enumerated() {
            if let oldIndex = oldStructure.firstIndex(where: { $0.identifier == newSection.identifier }) {
                if oldIndex != newIndex {
                    sectionsToMove.append((from: oldIndex, to: newIndex))
                }

                // Check header/footer changes for reloads
                if let oldSection = oldSectionsById[newSection.identifier] {
                    if oldSection.headerContentHasher?.finalize() != newSection.headerContentHasher?.finalize() {
                        sectionHeadersToReload.insert(newIndex)
                    }
                    if oldSection.footerContentHasher?.finalize() != newSection.footerContentHasher?.finalize() {
                        sectionFootersToReload.insert(newIndex)
                    }
                }
            } else {
                sectionsToInsert.insert(newIndex)
            }
        }

        // Identify rows to delete, insert, move, or reload within sections
        for (oldSectionIndex, oldSection) in oldStructure.enumerated() {
            for (oldRowIndex, oldRow) in oldSection.rows.enumerated() {
                guard let rowIdentifyHasher = oldRow.identifyHasher else { continue }
                if let (newIndexPath, newCell) = newStructure.indexPath(of: rowIdentifyHasher, structureView: structureView) {
                    let newSectionIndex = newIndexPath.section
                    let newRowIndex = newIndexPath.item
                    if oldSectionIndex != newSectionIndex || oldRowIndex != newRowIndex {
                        rowsToMove.append((
                            from: IndexPath(item: oldRowIndex, section: oldSectionIndex),
                            to: IndexPath(item: newRowIndex, section: newSectionIndex)
                        ))
                    }

                    // Check for row reload
                    if let oldContentHasher = oldRow.contentHasher, let newContentHasher = (newCell as? StructurableContentIdentifable)?.contentHasher() {
                        if oldContentHasher.finalize() != newContentHasher.finalize() {
                            rowsToReload.append(newIndexPath)
                        }
                    }
                } else {
                    // Row was deleted
                    rowsToDelete.append(IndexPath(item: oldRowIndex, section: oldSectionIndex))
                }
            }
        }

        // Ensure no conflict between rowsToDelete and rowsToReload
        rowsToReload = rowsToReload.filter { !rowsToDelete.contains($0) }
        
        // Ensure no conflict between rowsToDelete and rowsToMove
        rowsToDelete = rowsToDelete.filter { delete in
            !rowsToMove.contains { $0.from == delete }
        }
        
        // Filter out row-level operations within sections that are being deleted
        rowsToDelete = rowsToDelete.filter { delete in
            !sectionsToDelete.contains(delete.section)
        }

        rowsToMove = rowsToMove.filter { move in
            !sectionsToDelete.contains(move.from.section) && !sectionsToMove.contains { $0.from == move.from.section }
        }

        // Filter out row-level operations within sections that are being moved
        rowsToReload = rowsToReload.filter { reload in
            !sectionsToMove.contains { $0.from == reload.section }
        }

        // Identify rows to insert
        for (newSectionIndex, newSection) in newStructure.enumerated() {
            for (newRowIndex, newRow) in newSection.rows.enumerated() {
                guard let rowIdentifyHasher = (newRow as? StructurableIdentifable)?.identifyHasher(for: structureView) else { continue }
                if !oldStructure.contains(where: { $0.rows.contains { $0.identifyHasher?.finalize() == rowIdentifyHasher.finalize() } }) {
                    rowsToInsert.append(IndexPath(item: newRowIndex, section: newSectionIndex))
                }
            }
        }
    }
    
    var isEmpty: Bool {
        sectionsToMove.isEmpty &&
        sectionsToDelete.isEmpty &&
        sectionsToInsert.isEmpty &&
        sectionHeadersToReload.isEmpty &&
        sectionFootersToReload.isEmpty &&
        rowsToMove.isEmpty &&
        rowsToDelete.isEmpty &&
        rowsToInsert.isEmpty &&
        rowsToReload.isEmpty
    }
    
    var description: String {
        [
            "CYCLE_NOTE - sectionsToMove \(sectionsToMove.description)",
            "CYCLE_NOTE - sectionsToDelete \(sectionsToDelete.description)",
            "CYCLE_NOTE - sectionsToInsert \(sectionsToInsert.description)",
            "CYCLE_NOTE - sectionHeadersToReload \(sectionHeadersToReload.description)",
            "CYCLE_NOTE - sectionFootersToReload \(sectionFootersToReload.description)",
            "CYCLE_NOTE - rowsToMove \(rowsToMove.description)",
            "CYCLE_NOTE - rowsToDelete \(rowsToDelete.description)",
            "CYCLE_NOTE - rowsToInsert \(rowsToInsert.description)",
            "CYCLE_NOTE - rowsToReload \(rowsToReload.description)",
        ].joined(separator: "\n")
    }
    
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#endif
