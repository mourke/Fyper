//
//  Injection.swift
//  Dynamic
//
//  Created by Mark Bourke on 07/02/2022.
//

import Foundation



struct Injection: Hashable, CustomStringConvertible {
    
    enum Kind: String {
        case safe = "@SafeInject"
    }
    
    let typenameToBeInjected: String
    let typenameToBeInjectedInto: String
    let kind: Kind
    
    var description: String {
        "\(kind.rawValue) \(typenameToBeInjected) into \(typenameToBeInjectedInto)"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(typenameToBeInjected)
        hasher.combine(typenameToBeInjectedInto)
        hasher.combine(kind.rawValue)
    }
    
    static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.typenameToBeInjectedInto == rhs.typenameToBeInjectedInto &&
        lhs.typenameToBeInjected == rhs.typenameToBeInjected &&
        lhs.kind == rhs.kind
    }
}
