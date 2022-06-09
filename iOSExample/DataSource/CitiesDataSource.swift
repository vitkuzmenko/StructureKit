//
//  CitiesDataSource.swift
//  StructureKit
//
//  Created by Vitaliy Kuzmenko on 27.11.2019.
//  Copyright © 2019 Vitaliy Kuzmenko. All rights reserved.
//

import Foundation

class CitiesDataSource {
    
    func countries() -> [Country] {
        return [
            Country(title: "USA", cities: usa()),
            Country(title: "Russia", cities: russia())
        ]
    }
    
    func usa() -> [City] {
        return [
            City(name: "New York", population: getRandomPopulation()),
            City(name: "Las Vegas", population: getRandomPopulation()),
            City(name: "San Francisco", population: getRandomPopulation()),
            City(name: "Los Angeles", population: getRandomPopulation())
            ].dropLast(Int.random(in: 0...3)).shuffled()
    }
    
    func russia() -> [City] {
        return [
            City(name: "Moscow", population: getRandomPopulation()),
            City(name: "Rostov-on-Don", population: getRandomPopulation()),
            City(name: "st. Pitersberg", population: getRandomPopulation()),
            City(name: "Vladivostok", population: getRandomPopulation())
            ].dropLast(Int.random(in: 0...3)).shuffled()
    }
    
    func getRandomPopulation() -> Int {
        return Int.random(in: 1...2)
    }
    
}
