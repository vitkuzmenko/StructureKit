//
//  ViewController.swift
//  StructureKit
//
//  Created by Vitaliy Kuzmenko on 03.12.2019.
//

import UIKit
import StructureKit

class TableViewController: UIViewController {

    @IBOutlet var tableView: UITableView!
    
    let structureController = StructureController()
    
    let collectionController = StructureController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()
        makeStructure()
    }
    
    func configureTableView() {
        structureController.register(tableView, cellModelTypes: [
            City.self
        ], headerFooterModelTypes: [
            Country.self
        ])
    }
    
    @IBAction func makeStructure() {
        let structure = CitiesStructureBuilder().makeStructure()
        structureController.set(structure: structure)
    }
    
}
