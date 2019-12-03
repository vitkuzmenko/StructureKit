//
//  ViewController.swift
//  StructureKit
//
//  Created by Vitaliy Kuzmenko on 03.12.2019.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var tableView: UITableView!
    
    let tableController = StructureController()
    
    let collectionController = StructureController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()
        makeStructure()
    }
    
    func configureTableView() {
        tableController.register(tableView, cellModelTypes: [
            CityTableViewCellModel.self
        ], headerFooterModelTypes: [
            CountryHeaderViewModel.self
        ])
    }
    
    @IBAction func makeStructure() {
        let structure = CitiesDataSource().countries().map { country -> StructureSection in
            var section = StructureSection(
                identifier: country.title,
                rows: country.cities.map({ CityTableViewCellModel(city: $0) })
            )
            section.header = .view(CountryHeaderViewModel(country: country))
            section.footer = .text("Population: \(country.cities.reduce(0, { $0 + $1.population }))")
            return section
        }
        tableController.set(structure: structure, animation: TableAnimationRule(insert: .left, delete: .right, reload: .fade))
    }
    
}
