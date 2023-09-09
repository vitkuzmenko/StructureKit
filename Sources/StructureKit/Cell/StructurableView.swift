//
//  File.swift
//  
//
//  Created by Vitaliy Kuzmenko on 02.08.2022.
//

#if os(iOS) || os(tvOS) || os(macOS)

import Foundation

protocol StructurableView {
    
    associatedtype ViewModel: Structurable
    
    func reuse(for viewModel: ViewModel)
    
}

#endif
