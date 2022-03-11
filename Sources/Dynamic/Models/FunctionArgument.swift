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
    
    var description: String {
        "\(name): type"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(type)
    }
}
