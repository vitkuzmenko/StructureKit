//
//  CollectionAnimationRule.swift
//  StructureKit
//
//  Created by Vitaliy Kuzmenko on 21.07.2020.
//

import Foundation

public struct CollectionAnimationRule {
    public let enabled: Bool
    
    // Has no effect is enabled == false
    public let update: Bool
}

extension CollectionAnimationRule {
    
    /// No animations
    public static let none = CollectionAnimationRule(enabled: false, update: false)
    
    /// No animations
    public static let animated = CollectionAnimationRule(enabled: true, update: true)
    
    // Disable update animations
    public static let disableUpdateAnimation = CollectionAnimationRule(enabled: true, update: false)
}
