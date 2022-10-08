//
//  StructureOldSection.swift
//  StructureKit
//
//  Created by Vitaliy Kuzmenko on 29.11.2019.
//  Copyright © 2019 Vitaliy Kuzmenko. All rights reserved.
//

import Foundation

struct StructureCastSection {
    
    let identifier: AnyHashable
    
    var rows: [StructurableCast]
    
    let headerContentHasher: Hasher?
    
    let footerContentHasher: Hasher?
    
}

extension StructureCastSection: Equatable {
    static func == (lhs: StructureCastSection, rhs: StructureCastSection) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

extension Sequence where Iterator.Element == StructureCastSection {
    
    func indexPath(of identifyHasher: Hasher) -> IndexPath? {
        for (index, section) in enumerated() {
                        
            let firstIndex = section.rows.firstIndex { rhs -> Bool in
                guard let rhsIdentifyHasher = rhs.identifyHasher else { return false }
                return identifyHasher.finalize() == rhsIdentifyHasher.finalize()
            }
            
            if let row = firstIndex {
                return IndexPath(item: row, section: index)
            }
        }
        return nil
    }
    
    func contains(Structure identifyHasher: Hasher) -> Bool {
        return indexPath(of: identifyHasher) != nil
    }
    
}
