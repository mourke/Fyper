//
//  Initializer.swift
//  Dynamic
//
//  Created by Mark Bourke on 05/02/2022.
//

import Foundation

struct Initializer: CustomStringConvertible {
    
    let typename: String
    let offset: Int
    let superSyntaxStructure: SyntaxStructure
    let arguments: [FunctionArgument]
    
    var description: String {
        let args = arguments.map { $0.description }.joined(separator: ", ")
        return "\(typename).init(\(args))"
    }
}
