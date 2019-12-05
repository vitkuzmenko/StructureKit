//
//  CitiesStructureBuilder.swift
//  StructureKit
//
//  Created by Vitaliy Kuzmenko on 05.12.2019.
//

import Foundation

class CitiesStructureBuilder {
    
    func makeStructure() -> [StructureSection] {
        return CitiesDataSource().countries().map { country -> StructureSection in
            var section = StructureSection(
                identifier: country.title,
                rows: country.cities
            )
            section.header = .view(country)
            section.footer = .text("Population: \(country.cities.reduce(0, { $0 + $1.population }))")
            return section
        }
    }
    
}
