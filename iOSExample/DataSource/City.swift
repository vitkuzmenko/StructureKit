//
//  City.swift
//  StructureKit
//
//  Created by Vitaliy Kuzmenko on 27.11.2019.
//  Copyright © 2019 Vitaliy Kuzmenko. All rights reserved.
//

import Foundation
import StructureKit

struct City: Hashable {
    
    let name: String
    
    let population: Int
    
}

extension City: StructurableIdentifable {
    
    func identifyHash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
}

extension City: StructurableContentIdentifable {

    func contentHash(into hasher: inout Hasher) {
        hasher.combine(self)
    }

}
