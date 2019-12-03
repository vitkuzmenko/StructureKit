//
//  TableStructureSection.swift
//  StructureKit
//
//  Created by Vitaliy Kuzmenko on 30/03/2019.
//  Copyright © 2019 Vitaliy Kuzmenko. All rights reserved.
//

import Foundation

public struct StructureSection {
    
    public enum HeaderFooter {
        case text(String), view(StructureSectionHeaderFooter)
    }
    
    public let identifier: AnyHashable
    
    public var header: HeaderFooter?
    
    public var footer: HeaderFooter?
    
    public var rows: [Structurable] = []
    
    public init(identifier: AnyHashable, rows: [Structurable] = []) {
        self.identifier = identifier
        self.rows = rows
    }
    
    public mutating func append(_ object: Structurable) {
        rows.append(object)
    }
    
    public mutating func append(contentsOf objects: [Structurable]) {
        rows.append(contentsOf: objects)
    }
        
}

extension StructureSection: Equatable {
    
    public static func == (lhs: StructureSection, rhs: StructureSection) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
}

extension StructureSection: Hashable {
        
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
}

extension StructureSection {
    
    var headerContentHasher: Hasher? {
        return hasher(for: header)
    }
    
    var footerContentHasher: Hasher? {
        return hasher(for: footer)
    }
    
    fileprivate func hasher(for headerFooter: HeaderFooter?) -> Hasher? {
        if let headerFooter = headerFooter {
            switch headerFooter {
            case .text(let text):
                var hasher = Hasher()
                hasher.combine(text)
                return hasher
            case .view(let viewModel):
                return (viewModel as? StructureTableSectionHeaderFooterContentIdentifable)?.contentHasher()
            }
        } else {
            return nil
        }
    }
    
}

extension Sequence where Iterator.Element == StructureSection {
    
    func indexPath(of identifyHasher: Hasher, StructureView: StructureView) -> (indexPath: IndexPath, cellModel: StructurableIdentifable)? {
        for (index, section) in enumerated() {
                        
            let firstIndex = section.rows.firstIndex { rhs -> Bool in
                guard let rhsIdentifable = rhs as? StructurableIdentifable else {
                    return false
                }
                
                let rhsIdentifyHasher = rhsIdentifable.identifyHasher(for: StructureView)
                return identifyHasher.finalize() == rhsIdentifyHasher.finalize()
            }
            
            if let row = firstIndex, let cellModel = section.rows[row] as? StructurableIdentifable {
                return (IndexPath(row: row, section: index), cellModel)
            }
        }
        return nil
    }
    
    func contains(Structure identifyHasher: Hasher, StructureView: StructureView) -> Bool {
        return indexPath(of: identifyHasher, StructureView: StructureView) != nil
    }
    
    // MARK: - Converting to old strcuture
    
    func old(for StructureView: StructureView) -> [StructureOldSection] {
        return map { oldSection in
            return .init(
                identifier: oldSection.identifier,
                rows: oldSection.rows.map { cellOld in
                    return StructureOldItem(
                        identifyHasher: (cellOld as? StructurableIdentifable)?.identifyHasher(for: StructureView),
                        contentHasher: (cellOld as? StructurableContentIdentifable)?.contentHasher()
                    )
                },
                headerContentHasher: oldSection.headerContentHasher,
                footerContentHasher: oldSection.footerContentHasher
            )
        }
    }
    
}
