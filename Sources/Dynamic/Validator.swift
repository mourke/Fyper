//
//  Validator.swift
//  Dynamic
//
//  Created by Mark Bourke on 02/03/2022.
//

import Foundation
import SourceKittenFramework

/// Validates calling graphs. This should be called after Analyser.
struct Validator {
    
    let logger: Logger
    
    /// The calling graph starting from the initialiser that specifies the types that need to be injected into that class/struct, obtained from the *Analyser* stage.
    let graphs: [InitialNode]
    
    ///
    /// Assures that for each calling graph, the types to be injected are actually injected.
    ///
    /// - Throws:   Exception if any of the types are not found in the calling graph.
    ///
    func validate() throws {
        logger.log("Searching call graphs for injections...", kind: .debug)
        for root in graphs {
            try root.initializer.injectableArguments.forEach { argument in
                logger.log("Searching '\(root.typename)' initialiser graph for '\(argument.type)'...", kind: .debug)
                
                let found = searchNodesFor(typeToBeInjected: argument.type, node: root)
                
                if !found {
                    let message = "'\(argument.type)' is not injected in the calling hierarchy."
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
              syntaxStructure.name == "\(Constants.Inject)"
        else {
            logger.log("Expression is not a call. Ignoring...", kind: .debug)
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
            logger.log("Call expression does not match the regex. Ignoring...", kind: .debug)
            return false
        }
        
        logger.log("Found '\(type)' in calling graph!", kind: .debug)
        
        return true
    }
}
