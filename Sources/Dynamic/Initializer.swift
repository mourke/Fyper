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
    let arguments: [String]
    
    var description: String {
        let args = arguments.joined(separator: ", _: ")
        return "\(typename).init(_: \(args))"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(typename)
        arguments.forEach { hasher.combine($0) }
    }
    
    static func == (lhs: Initializer, rhs: Initializer) -> Bool {
        return lhs.typename == rhs.typename && lhs.arguments.elementsEqual(rhs.arguments)
    }
}
