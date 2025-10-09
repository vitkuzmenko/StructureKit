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

        case insertion, deletion, similarObjects, similarSections, moveIntoInsertedSection, moveIntoDeletedSection

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
            case .moveIntoInsertedSection:
                return "Attempts to move row into inserted section."
            case .moveIntoDeletedSection:
                return "Attempts to move row into deleted section."
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

    init(
        from oldStructure: [StructureCastSection],
        to newStructure: [StructureSection],
        structureView: StructureView
    ) throws {

        // Validate new structure for duplicate section identifiers
        let newSectionIds = newStructure.map { $0.identifier }
        if Set(newSectionIds).count != newSectionIds.count {
            throw DifferenceError.similarSections
        }

        // Validate new structure for duplicate row identifiers
        let newRowIds = newStructure.flatMap { section in
            section.rows.compactMap { row in
                (row as? StructurableIdentifable)?.identifyHasher(for: structureView).finalize()
            }
        }
        if Set(newRowIds).count != newRowIds.count {
            throw DifferenceError.similarObjects
        }

        // Map identifiers for old and new sections
        let oldSectionsById = Dictionary(uniqueKeysWithValues: oldStructure.map { ($0.identifier, $0) })
        let oldIndexById: [AnyHashable: Int] = Dictionary(uniqueKeysWithValues: oldStructure.enumerated().map { ($1.identifier, $0) })

        // Identify sections to delete
        for (index, oldSection) in oldStructure.enumerated() {
            if !newStructure.contains(where: { $0.identifier == oldSection.identifier }) {
                sectionsToDelete.insert(index)
            }
        }

        // First pass: identify sections to insert
        for (newIndex, newSection) in newStructure.enumerated() {
            if oldIndexById[newSection.identifier] == nil {
                sectionsToInsert.insert(newIndex)
            }
        }

        // Second pass: identify sections to move (excluding shifts only due to insertions) and header/footer reloads
        // Also collect potential section moves (naïve oldIndex != newIndex) for row-level filtering
        var potentialSectionsToMove = IndexSet()
        for (newIndex, newSection) in newStructure.enumerated() {
            if let oldIndex = oldIndexById[newSection.identifier] {
                // Record potential move when indices differ (regardless of insertion shifts)
                if oldIndex != newIndex {
                    potentialSectionsToMove.insert(oldIndex)
                }
                // Count inserted sections that appear before (or at) this new index
                let insertedBeforeCount = sectionsToInsert.filter { $0 <= newIndex }.count
                let expectedNewIndex = oldIndex + insertedBeforeCount
                if expectedNewIndex != newIndex {
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
            }
        }

        // Identify rows to delete, insert, move, or reload within sections
        for (oldSectionIndex, oldSection) in oldStructure.enumerated() {
            for (oldRowIndex, oldRow) in oldSection.rows.enumerated() {
                guard let rowIdentifyHasher = oldRow.identifyHasher else { continue }
                if let (newIndexPath, newCell) = newStructure.indexPath(
                    of: rowIdentifyHasher,
                    structureView: structureView
                ) {
                    let newSectionIndex = newIndexPath.section
                    let newRowIndex = newIndexPath.item
                    if oldSectionIndex != newSectionIndex || oldRowIndex != newRowIndex {
                        rowsToMove.append(
                            (
                                from: IndexPath(item: oldRowIndex, section: oldSectionIndex),
                                to: IndexPath(item: newRowIndex, section: newSectionIndex)
                            )
                        )
                    }

                    // Check for row reload
                    if let oldContentHasher = oldRow.contentHasher,
                        let newContentHasher = (newCell as? StructurableContentIdentifable)?.contentHasher()
                    {
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

        // Disallow moving existing rows into newly inserted sections
        if !sectionsToInsert.isEmpty {
            if rowsToMove.contains(where: { move in
                sectionsToInsert.contains(move.from.section)
            }) {
                throw DifferenceError.moveIntoInsertedSection
            }
        }

        // Disallow moving existing rows into newly inserted sections
        if !sectionsToDelete.isEmpty {
            if rowsToMove.contains(where: { move in
                sectionsToDelete.contains(move.to.section)
            }) {
                throw DifferenceError.moveIntoDeletedSection
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
            !sectionsToDelete.contains(move.from.section) && !potentialSectionsToMove.contains(move.from.section)
        }

        // Filter out row-level operations within sections that are being moved
        rowsToReload = rowsToReload.filter { reload in
            !sectionsToMove.contains { $0.from == reload.section }
        }

        rowsToReload = rowsToReload.filter { reload in
            !rowsToMove.contains(where: { move in move.from == reload })
        }

        // Identify rows to insert
        for (newSectionIndex, newSection) in newStructure.enumerated() {
            for (newRowIndex, newRow) in newSection.rows.enumerated() {
                guard let rowIdentifyHasher = (newRow as? StructurableIdentifable)?.identifyHasher(for: structureView)
                else { continue }
                if !oldStructure.contains(where: {
                    $0.rows.contains { $0.identifyHasher?.finalize() == rowIdentifyHasher.finalize() }
                }) && !sectionsToInsert.contains(newSectionIndex) {
                    rowsToInsert.append(IndexPath(item: newRowIndex, section: newSectionIndex))
                }
            }
        }

        // Disallow moving existing rows into newly inserted sections
        if !sectionsToInsert.isEmpty {
            let hasMoveIntoInsertedSection = rowsToMove.contains { move in
                sectionsToInsert.contains(move.to.section)
            }
            if hasMoveIntoInsertedSection {
                throw DifferenceError.moveIntoInsertedSection
            }
        }

    }

    var isEmpty: Bool {
        sectionsToMove.isEmpty && sectionsToDelete.isEmpty && sectionsToInsert.isEmpty && sectionHeadersToReload.isEmpty
            && sectionFootersToReload.isEmpty && rowsToMove.isEmpty && rowsToDelete.isEmpty && rowsToInsert.isEmpty
            && rowsToReload.isEmpty
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
