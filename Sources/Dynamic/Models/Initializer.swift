//
//  Initializer.swift
//  Dynamic
//
//  Created by Mark Bourke on 05/02/2022.
//

import Foundation

struct Initializer: Hashable, CustomStringConvertible {
    
    let typename: String
    let offset: Int
    let injectableArguments: [FunctionArgument]
    let regularArguments: [FunctionArgument]
    let superSyntaxStructure: SyntaxStructure
    
    var arguments: [FunctionArgument] {
        injectableArguments + regularArguments
    }
    
    var description: String {
        let args = arguments.map { $0.description }.joined(separator: ", ")
        return "\(typename).init(\(args))"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(typename)
        arguments.forEach { hasher.combine($0) }
    }
    
    static func == (lhs: Initializer, rhs: Initializer) -> Bool {
        return lhs.typename == rhs.typename && lhs.arguments.elementsEqual(rhs.arguments)
    }
}
