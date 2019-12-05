//
//  Country.swift
//  StructureKit
//
//  Created by Vitaliy Kuzmenko on 28.11.2019.
//  Copyright © 2019 Vitaliy Kuzmenko. All rights reserved.
//

import Foundation

struct Country: Hashable {
    
    let title: String
    
    let cities: [City]
    
}

extension Country: StructureSectionHeaderFooterContentIdentifable {
    
    func contentHash(into hasher: inout Hasher) {
        hasher.combine(self)
    }
    
}
