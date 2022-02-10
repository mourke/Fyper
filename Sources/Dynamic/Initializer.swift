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
    let arguments: [String]
    
    var description: String {
        let args = arguments.joined(separator: ", _: ")
        return "\(typename).init(_: \(args))"
    }
}
