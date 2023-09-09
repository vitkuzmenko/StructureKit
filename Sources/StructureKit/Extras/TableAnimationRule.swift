//
//  TableAnimationRule.swift
//  StructureKit
//
//  Created by Vitaliy Kuzmenko on 30.11.2019.
//  Copyright © 2019 Vitaliy Kuzmenko. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif

#if os(iOS) || os(tvOS)
public typealias NativeAnimation = UITableView.RowAnimation
#elseif os(macOS)
public typealias NativeAnimation = NSTableView.AnimationOptions
#endif

public struct TableAnimationRule: Equatable {
    
    public let insert, delete, reload: NativeAnimation
    
    public init(insert: NativeAnimation, delete: NativeAnimation, reload: NativeAnimation) {
        self.insert = insert
        self.delete = delete
        self.reload = reload
    }
}

extension TableAnimationRule {

#if os(iOS) || os(tvOS)
    
    public static let fade = TableAnimationRule(insert: .fade, delete: .fade, reload: .fade)

    public static let right = TableAnimationRule(insert: .right, delete: .right, reload: .right)

    public static let left = TableAnimationRule(insert: .left, delete: .left, reload: .left)

    public static let top = TableAnimationRule(insert: .top, delete: .top, reload: .top)

    public static let bottom = TableAnimationRule(insert: .bottom, delete: .bottom, reload: .bottom)

    public static let none = TableAnimationRule(insert: .none, delete: .none, reload: .none)

    public static let middle = TableAnimationRule(insert: .middle, delete: .middle, reload: .middle)

    public static let automatic = TableAnimationRule(insert: .automatic, delete: .automatic, reload: .automatic)
    
#elseif os(macOS)

    public static let fade = TableAnimationRule(insert: .effectFade, delete: .effectFade, reload: .effectFade)
    
    public static let right = TableAnimationRule(insert: .slideRight, delete: .slideRight, reload: .slideRight)
    
    public static let left = TableAnimationRule(insert: .slideLeft, delete: .slideLeft, reload: .slideLeft)
    
    public static let top = TableAnimationRule(insert: .slideUp, delete: .slideUp, reload: .slideUp)
    
    public static let bottom = TableAnimationRule(insert: .slideDown, delete: .slideDown, reload: .slideDown)
    
    public static let none = TableAnimationRule(insert: .effectFade, delete: .effectFade, reload: .effectFade)
    
#endif
    
}
