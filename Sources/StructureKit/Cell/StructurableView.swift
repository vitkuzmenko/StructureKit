//
//  File.swift
//  
//
//  Created by Vitaliy Kuzmenko on 02.08.2022.
//

import Foundation

protocol StructurableView {
    
    associatedtype ViewModel: Structurable
    
    func reuse(for viewModel: ViewModel)
    
}
