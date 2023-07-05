//
//  InjectableInitializer.swift
//  Dynamic
//
//  Created by Mark Bourke on 14/03/2022.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

struct InjectableInitializer: Hashable, CustomStringConvertible {

    let rootDataStructureSyntax: DataStructureDeclSyntaxProtocol
    let initializerSyntax: InitializerDeclSyntax
    let numberOfInjectableParameters: Int


    var typename: String {
        rootDataStructureSyntax.identifier.text
    }
    var parameters: FunctionParameterListSyntax {
        initializerSyntax.signature.input.parameterList
    }
    var injectableParameters: FunctionParameterListSyntax {
        var injectableParameters: [FunctionParameterSyntax] = []
        for (index, parameter) in parameters.enumerated() where index < numberOfInjectableParameters {
            injectableParameters.append(parameter)
        }

        return FunctionParameterListBuilder.buildFinalResult(injectableParameters)
    }

    var description: String {
        initializerSyntax.description
    }

    static func == (lhs: InjectableInitializer, rhs: InjectableInitializer) -> Bool {
        lhs.typename == rhs.typename
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(typename)
    }
}
