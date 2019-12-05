//
//  CityTableViewCell.swift
//  StructureKit
//
//  Created by Vitaliy Kuzmenko on 27.11.2019.
//  Copyright © 2019 Vitaliy Kuzmenko. All rights reserved.
//

import UIKit

extension City: StructurableForTableView {
    
    func configure(tableViewCell cell: CityTableViewCell) {
        cell.textLabel?.text = name
        cell.detailTextLabel?.text = String(population)
    }
    
}
