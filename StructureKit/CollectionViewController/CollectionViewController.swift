//
//  ViewController.swift
//  StructureKit
//
//  Created by Vitaliy Kuzmenko on 03.12.2019.
//

import UIKit

class CollectionViewController: UIViewController {

    @IBOutlet var collectionView: UICollectionView!
    
    let structureController = StructureController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureCollectionView()
        makeStructure()
    }
    
    func configureCollectionView() {
        structureController.register(collectionView, cellModelTypes: [
            City.self
        ])
    }
    
    @IBAction func makeStructure() {
        let structure = CitiesStructureBuilder().makeStructure()
        structureController.set(structure: structure)
    }
    
}
