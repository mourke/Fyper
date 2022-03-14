//
//  FunctionArgument.swift
//  Dynamic
//
//  Created by Mark Bourke on 11/03/2022.
//

import Foundation

struct FunctionArgument: Hashable, CustomStringConvertible {
    
    let name: String
    let type: String
    
    private let isUsingGeneratedName: Bool
    
    init(name: String? = nil, type: String) {
        self.type = type
        if let name = name {
            self.name = name
            self.isUsingGeneratedName = false
        } else {
            self.name = Constants.GeneratedVariablePrefix + type
            self.isUsingGeneratedName = true
        }
    }
    
    var description: String {
        if isUsingGeneratedName {
            return "_ \(name): \(type)"
        }
        return "\(name): \(type)"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(type)
    }
}
