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
        _ = Dictionary(uniqueKeysWithValues: oldStructure.map { ($0.identifier, $0) })
        _ = Dictionary(uniqueKeysWithValues: oldStructure.enumerated().map { ($1.identifier, $0) }) as [AnyHashable: Int]
        _ = Dictionary(uniqueKeysWithValues: newStructure.enumerated().map { ($1.identifier, $0) }) as [AnyHashable: Int]

        // SECTION DIFF (Paul Heckel)
        let oldSectionIdsArray: [Int] = oldStructure.map { $0.identifier.hashValue }
        let newSectionIdsArray: [Int] = newStructure.map { $0.identifier.hashValue }
        let sectionDiff = Heckel.diff(old: oldSectionIdsArray, new: newSectionIdsArray)

        // Sections to delete/insert
        sectionsToDelete = sectionDiff.deletes
        sectionsToInsert = sectionDiff.inserts

        // Moves for sections
        sectionsToMove = sectionDiff.moves

        // SECTION HEADER/FOOTER RELOADS (compare content hashers for matched sections)
        for (oldIndex, newIndex) in sectionDiff.matches {
            // Headers
            let oldHeader = oldStructure[oldIndex].headerContentHasher?.finalize()
            let newHeader = newStructure[newIndex].headerContentHasher?.finalize()
            if oldHeader != newHeader {
                sectionHeadersToReload.insert(newIndex)
            }
            // Footers
            let oldFooter = oldStructure[oldIndex].footerContentHasher?.finalize()
            let newFooter = newStructure[newIndex].footerContentHasher?.finalize()
            if oldFooter != newFooter {
                sectionFootersToReload.insert(newIndex)
            }
        }

        // ROWS DIFF per matched section (no cross-section moves; represent those as delete+insert)
        for (oldSectionIndex, newSectionIndex) in sectionDiff.matches {
            let oldSection = oldStructure[oldSectionIndex]
            let newSection = newStructure[newSectionIndex]

            // Build identity arrays. Fallback to unique ephemeral ids for non-identifiable rows to force insert/delete.
            let oldRowIds: [Int] = oldSection.rows.enumerated().map { idx, cast in
                if let id = cast.identifyHasher?.finalize() {
                    return id
                } else {
                    // Ephemeral unique id scoped to this section old side
                    return (oldSectionIndex &* 73856093) ^ (idx &* 19349663) ^ 0x0f0f0f
                }
            }
            let newRowIds: [Int] = newSection.rows.enumerated().map { idx, row in
                if let ident = (row as? StructurableIdentifable)?.identifyHasher(for: structureView).finalize() {
                    return ident
                } else {
                    // Ephemeral unique id scoped to this section new side
                    return (newSectionIndex &* 83492791) ^ (idx &* 29765797) ^ 0xf0f0f0
                }
            }

            let rowDiff = Heckel.diff(old: oldRowIds, new: newRowIds)

            // Deletions (old index paths)
            rowDiff.deletes.forEach { deleteRow in
                rowsToDelete.append(IndexPath(item: deleteRow, section: oldSectionIndex))
            }

            // Insertions (new index paths)
            rowDiff.inserts.forEach { insertRow in
                rowsToInsert.append(IndexPath(item: insertRow, section: newSectionIndex))
            }

            // Identify true moves (LIS based). A matched row whose index merely
            // shifted because of surrounding inserts/deletes is NOT a true move
            // and must still be eligible for a content reload.
            let trueMoveOldIndices = Set(rowDiff.moves.map { $0.from })

            // Moves (within the same matched section). When a moved row's content
            // also changed, keep the move and additionally mark its destination
            // for reload; the apply layer reloads moved rows after the move.
            rowDiff.moves.forEach { move in
                let from = IndexPath(item: move.from, section: oldSectionIndex)
                let to = IndexPath(item: move.to, section: newSectionIndex)
                rowsToMove.append((from: from, to: to))

                let oldContent = oldSection.rows[move.from].contentHasher?.finalize()
                let newRow = newSection.rows[move.to]
                let newContent = (newRow as? StructurableContentIdentifable)?.contentHasher().finalize()
                if oldContent != newContent {
                    rowsToReload.append(to)
                }
            }

            // Reloads for matched (and not truly moved) items whose content hash changed
            for (oldRowIndex, newRowIndex) in rowDiff.matches {
                if trueMoveOldIndices.contains(oldRowIndex) { continue } // handled in moves above

                let oldContent = oldSection.rows[oldRowIndex].contentHasher?.finalize()
                let newRow = newSection.rows[newRowIndex]
                let newContent = (newRow as? StructurableContentIdentifable)?.contentHasher().finalize()
                if oldContent != newContent {
                    rowsToReload.append(IndexPath(item: newRowIndex, section: newSectionIndex))
                }
            }
        }

        // Sort operations for stability and UIKit expectations
        rowsToDelete.sort { (lhs, rhs) -> Bool in
            if lhs.section == rhs.section { return lhs.item > rhs.item } // descending within section
            return lhs.section > rhs.section // delete higher sections first
        }
        rowsToInsert.sort { (lhs, rhs) -> Bool in
            if lhs.section == rhs.section { return lhs.item < rhs.item } // ascending within section
            return lhs.section < rhs.section
        }
        rowsToReload.sort { (lhs, rhs) -> Bool in
            if lhs.section == rhs.section { return lhs.item < rhs.item }
            return lhs.section < rhs.section
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

// MARK: - Heckel Diff

fileprivate enum Heckel {
    struct Entry {
        var oldCount: Int = 0
        var newCount: Int = 0
        var oldIndices: [Int] = []
        var newIndices: [Int] = []
    }

    struct Result {
        let deletes: IndexSet
        let inserts: IndexSet
        let matches: [Int: Int] // oldIndex -> newIndex
        let moves: [(from: Int, to: Int)]
    }

    static func diff(old: [Int], new: [Int]) -> Result {
        // Symbol table by value
        var table: [Int: Entry] = [:]

        // Pass 1: scan new
        for (j, value) in new.enumerated() {
            var e = table[value] ?? Entry()
            e.newCount += 1
            e.newIndices.append(j)
            table[value] = e
        }

        // Pass 2: scan old
        for (i, value) in old.enumerated() {
            var e = table[value] ?? Entry()
            e.oldCount += 1
            e.oldIndices.append(i)
            table[value] = e
        }

        // Initialize matches arrays with -1 as unmatched
        var oldToNew = Array(repeating: -1, count: old.count)
        var newToOld = Array(repeating: -1, count: new.count)

        // Pass 3: find all unique elements
        for (_, e) in table where e.oldCount == 1 && e.newCount == 1 {
            if let i = e.oldIndices.first, let j = e.newIndices.first {
                oldToNew[i] = j
                newToOld[j] = i
            }
        }

        // Pass 4: scan forward to extend matches
        var i = 0
        while i < old.count - 1 {
            let j = oldToNew[i]
            if j >= 0 && j + 1 < new.count && oldToNew[i + 1] == -1 && newToOld[j + 1] == -1 {
                if old[i + 1] == new[j + 1] {
                    oldToNew[i + 1] = j + 1
                    newToOld[j + 1] = i + 1
                }
            }
            i += 1
        }

        // Pass 5: scan backward to extend matches
        i = old.count - 1
        while i > 0 {
            let j = oldToNew[i]
            if j >= 0 && j - 1 >= 0 && oldToNew[i - 1] == -1 && newToOld[j - 1] == -1 {
                if old[i - 1] == new[j - 1] {
                    oldToNew[i - 1] = j - 1
                    newToOld[j - 1] = i - 1
                }
            }
            i -= 1
        }

        // Build results
        var deletes = IndexSet()
        for (index, mapped) in oldToNew.enumerated() where mapped == -1 {
            deletes.insert(index)
        }

        var inserts = IndexSet()
        for (index, mapped) in newToOld.enumerated() where mapped == -1 {
            inserts.insert(index)
        }

        var matches: [Int: Int] = [:]
        for (oldIndex, newIndex) in oldToNew.enumerated() where newIndex >= 0 {
            matches[oldIndex] = newIndex
        }

        // Determine true moves via LIS: items whose relative order is preserved are
        // not moves — their index shift is caused by surrounding inserts/deletes.
        let matchedPairs = oldToNew.enumerated()
            .filter { $0.element >= 0 }
            .map { ($0.offset, $0.element) } // (oldIndex, newIndex)
        let stableSet = longestIncreasingSubsequence(matchedPairs.map { $0.1 })
        var moves: [(from: Int, to: Int)] = []
        for (pairIdx, (oldIndex, newIndex)) in matchedPairs.enumerated() {
            if !stableSet.contains(pairIdx) {
                moves.append((from: oldIndex, to: newIndex))
            }
        }

        return Result(deletes: deletes, inserts: inserts, matches: matches, moves: moves)
    }

    // Returns the set of *indices into `values`* that form a longest increasing subsequence.
    // Items outside this set are true moves; items inside just shifted due to inserts/deletes.
    private static func longestIncreasingSubsequence(_ values: [Int]) -> Set<Int> {
        guard !values.isEmpty else { return [] }
        var tails = [Int]()   // tails[i] = index into `values` with smallest tail for IS of length i+1
        var pred = Array(repeating: -1, count: values.count)

        for i in 0..<values.count {
            let v = values[i]
            var lo = 0, hi = tails.count
            while lo < hi {
                let mid = (lo + hi) / 2
                if values[tails[mid]] < v { lo = mid + 1 } else { hi = mid }
            }
            pred[i] = lo > 0 ? tails[lo - 1] : -1
            if lo == tails.count { tails.append(i) } else { tails[lo] = i }
        }

        var result = Set<Int>()
        var idx = tails.last ?? -1
        while idx >= 0 {
            result.insert(idx)
            idx = pred[idx]
        }
        return result
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#endif
