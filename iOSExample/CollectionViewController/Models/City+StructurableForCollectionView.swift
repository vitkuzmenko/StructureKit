//
//  CityTableViewCell.swift
//  StructureKit
//
//  Created by Vitaliy Kuzmenko on 27.11.2019.
//  Copyright © 2019 Vitaliy Kuzmenko. All rights reserved.
//

import UIKit
import StructureKit

extension City: StructurableForCollectionView {

    func configure(collectionViewCell cell: CityCollectionViewCell) {
        cell.textLabel?.text = name
        cell.detailTextLabel?.text = String(population)
    }

}

extension City: StructurableSizable {
 
    func size(for parentView: UICollectionView) -> CGSize {
        let layout = parentView.collectionViewLayout as! UICollectionViewFlowLayout
        let freeWidth = parentView.bounds.width - layout.sectionInset.left - layout.sectionInset.right - layout.minimumInteritemSpacing
        let cellWidth = freeWidth / 2 // 2: number fo columns
        let cellHeight: CGFloat = 21 + 8 + 21 // 21: label height, 8: space between labels
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
}
