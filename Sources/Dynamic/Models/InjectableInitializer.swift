//
//  InjectableInitializer.swift
//  Dynamic
//
//  Created by Mark Bourke on 14/03/2022.
//

import Foundation

struct InjectableInitializer: Hashable, CustomStringConvertible {
    
    let typename: String
    let superSyntaxStructure: SyntaxStructure
    let injectionKind: Injection.Kind
    
    let injectableArguments: [FunctionArgument]
    let regularArguments: [FunctionArgument]
    
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
    
    static func == (lhs: InjectableInitializer, rhs: InjectableInitializer) -> Bool {
        return lhs.typename == rhs.typename && lhs.arguments.elementsEqual(rhs.arguments)
    }
}
