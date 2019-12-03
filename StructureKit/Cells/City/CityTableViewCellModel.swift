//
//  CityTableViewCell.swift
//  StructureKit
//
//  Created by Vitaliy Kuzmenko on 27.11.2019.
//  Copyright © 2019 Vitaliy Kuzmenko. All rights reserved.
//

import UIKit

struct CityTableViewCellModel {
            
    let title: String
    
    let population: String
    
    init(city: City) {
        title = city.name
        population = String(city.population)
    }
    
}

extension CityTableViewCellModel: StructurableForTableView {
    
    func configure(tableViewCell cell: CityTableViewCell) {
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = population
    }
    
}

extension CityTableViewCellModel: StructurableIdentifable {
    
    func identifyHash(into hasher: inout Hasher) {
        hasher.combine(title)
    }
    
}

extension CityTableViewCellModel: StructurableContentIdentifable {

    func contentHash(into hasher: inout Hasher) {
        hasher.combine(population)
    }

}
