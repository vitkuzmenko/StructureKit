//
//  CountryHeaderView.swift
//  StructureKit
//
//  Created by Vitaliy Kuzmenko on 30.11.2019.
//  Copyright © 2019 Vitaliy Kuzmenko. All rights reserved.
//

import UIKit

extension Country: StructureCollectionSectionHeaderFooter {
    
    func configure(collectionViewReusableSupplementaryView view: CountrySectionHeaderCollectionReusableView, isUpdating: Bool) {
        view.imageView.image = UIImage(named: title)
        view.titleLabel.text = title
        view.countLabel.text = String(cities.count)
    }
    
}

extension Country: StructurableSizable {
    
    func size(for parentView: UICollectionView) -> CGSize {
        let layout = parentView.collectionViewLayout as! UICollectionViewFlowLayout
        let width = parentView.bounds.width - layout.sectionInset.left - layout.sectionInset.right - layout.minimumInteritemSpacing
        return CGSize(width: width, height: 42)
    }
    
}
