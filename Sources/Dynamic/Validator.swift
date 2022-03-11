//
//  Validator.swift
//  Dynamic
//
//  Created by Mark Bourke on 02/03/2022.
//

import Foundation
import SourceKittenFramework

struct Validator {
    
    let logger: Logger
    let graph: [InitialNode]
    
    func validate() throws {
        for root in graph {
            let injections = root.initializer.arguments
            
            try injections.forEach { type in
                let found = searchNodesFor(typeToBeInjected: type, node: root)
                
                if !found {
                    let message = "\(type) is not injected in the calling hierarchy."
                    throw Fyper.Error.basic(message)
                }
            }
        }
    }
    
    private func searchNodesFor(typeToBeInjected type: String, node: Node) -> Bool {
        if searchFor(typeToBeInjected: type, syntaxStructure: node.syntaxStructure) {
            return true
        } else {
            return node.children.contains { searchFor(typeToBeInjected: type, syntaxStructure: $0.syntaxStructure) }
        }
    }
    
    private func searchFor(typeToBeInjected type: String, syntaxStructure: SyntaxStructure) -> Bool {
        guard let rawValue = syntaxStructure.kind,
              let kind = SwiftExpressionKind(rawValue: rawValue),
              kind == .call,
              syntaxStructure.name == "Resolver.register"
        else {
            logger.log("Syntax structure is not a class or struct. Ignoring...", kind: .debug)
            return syntaxStructure.substructure?.contains { searchFor(typeToBeInjected: type, syntaxStructure: $0) } ?? false
        }
        
        guard let substructure = syntaxStructure.substructure?.first,
              let rawValue = substructure.kind,
              let kind = SwiftExpressionKind(rawValue: rawValue),
              kind == .closure,
              let substructure = substructure.substructure?.first,
              let rawValue = substructure.kind,
              let kind = SwiftStatementKind(rawValue: rawValue),
              kind == .brace,
              let substructure = substructure.substructure?.first,
              let rawValue = substructure.kind,
              let kind = SwiftExpressionKind(rawValue: rawValue),
              kind == .call,
              let call = substructure.name,
              call == "\(type).init" || call == type
        else {
            return false
        }
        
        return true
    }
}
