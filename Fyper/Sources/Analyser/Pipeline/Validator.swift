//
//  Validator.swift
//  Dynamic
//
//  Created by Mark Bourke on 02/03/2022.
//

import Foundation
import SwiftSyntax

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
            try root.initializer.injectableParameters.forEach { argument in
                guard let argumentType = argument.type.as(SimpleTypeIdentifierSyntax.self) else { return }
                logger.log("Searching '\(root.typename)' initialiser graph for '\(argumentType)'...", kind: .debug)

                let found = searchNodesFor(typeToBeInjected: argumentType, node: root)

                if !found {
                    let message = "'\(argumentType)' is not injected in the calling hierarchy."
                    throw Fyper.Error.basic(message)
                }

                logger.log("Found!", kind: .debug)
            }
        }
        logger.log("All dependencies validated correctly", kind: .debug)
    }

    private func searchNodesFor(typeToBeInjected type: SimpleTypeIdentifierSyntax, node: Node) -> Bool {
        if searchFor(typeToBeInjected: type, in: node.enclosingDataStructure) {
            return true
        } else {
            return node.children.contains { searchNodesFor(typeToBeInjected: type, node: $0) }
        }
    }

    private func searchFor(typeToBeInjected type: SimpleTypeIdentifierSyntax, in dataStructure: DataStructureDeclSyntaxProtocol) -> Bool {
        for member in dataStructure.memberBlock.members where member.decl.is(VariableDeclSyntax.self) {
            let variable = member.decl.cast(VariableDeclSyntax.self)
            guard let attributes = variable.attributes,
                  attributesContainRegisterPropertyWrapper(attributes)
            else { continue }

            for patternBinding in variable.bindings {
                guard
                    let variableType = patternBinding.typeAnnotation?.type.as(SimpleTypeIdentifierSyntax.self),
                    variableType.name.text == type.name.text
                else { continue }

                return true
            }
        }
        return false
    }

    private func attributesContainRegisterPropertyWrapper(_ attributes: AttributeListSyntax) -> Bool {
        attributes.contains(where: { attribute in
            guard case let .attribute(attr) = attribute,
                let simpleIdentifier = attr.attributeName.as(SimpleTypeIdentifierSyntax.self) else { return false }
            return simpleIdentifier.name.text == Constants.Register
        })
    }
}
