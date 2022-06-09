//
//  CountryHeaderView.swift
//  StructureKit
//
//  Created by Vitaliy Kuzmenko on 30.11.2019.
//  Copyright © 2019 Vitaliy Kuzmenko. All rights reserved.
//

import UIKit
import StructureKit

extension Country: StructureTableSectionHeaderFooter {
    
    func configure(tableViewHeaderFooterView view: CountryTableHeaderView, isUpdating: Bool) {
        view.imageView.image = UIImage(named: title)
        view.titleLabel.text = title
        view.countLabel.text = String(cities.count)
    }
    
}

extension Country: StructurableHeightable {
    
    func height(for tableView: UITableView) -> CGFloat {
        return 42
    }
    
}
