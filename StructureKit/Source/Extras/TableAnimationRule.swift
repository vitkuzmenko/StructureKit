//
//  TableAnimationRule.swift
//  StructureKit
//
//  Created by Vitaliy Kuzmenko on 30.11.2019.
//  Copyright © 2019 Vitaliy Kuzmenko. All rights reserved.
//

import UIKit

public struct TableAnimationRule: Equatable {
    let insert, delete, reload: UITableView.RowAnimation
}

extension TableAnimationRule {
    
    public static let fade = TableAnimationRule(insert: .fade, delete: .fade, reload: .fade)

    public static let right = TableAnimationRule(insert: .right, delete: .right, reload: .right)

    public static let left = TableAnimationRule(insert: .left, delete: .left, reload: .left)

    public static let top = TableAnimationRule(insert: .top, delete: .top, reload: .top)

    public static let bottom = TableAnimationRule(insert: .bottom, delete: .bottom, reload: .bottom)

    public static let none = TableAnimationRule(insert: .none, delete: .none, reload: .none)

    public static let middle = TableAnimationRule(insert: .middle, delete: .middle, reload: .middle)

    public static let automatic = TableAnimationRule(insert: .automatic, delete: .automatic, reload: .automatic)
    
}
