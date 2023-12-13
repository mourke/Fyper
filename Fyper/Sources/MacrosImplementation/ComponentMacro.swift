import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftParser
import SwiftDiagnostics
import SwiftParserDiagnostics
import Foundation

private struct CustomFixItMessage: FixItMessage {
    let message: String
    private let messageID: String

    init(_ message: String, messageID: String = #function) {
      self.message = message
      self.messageID = messageID
    }

     var fixItID: MessageID {
         MessageID(domain: "SwiftParser", id: "\(type(of: self)).\(messageID)")
    }
}

private enum SyntaxError: DiagnosticMessage {
    case onlyDataStructures

    var message: String {
        switch self {
        case .onlyDataStructures:
            "'@Component' may only be applied to classes, structs or actors."
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "com.mourke.fyper", id: String(describing: self))
    }

    var severity: DiagnosticSeverity {
        .error
    }
}

public struct ComponentMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
		providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
		return []


		// TODO: Add extension macro to make sure the type conforms to exposeAs

		// TODO: Make sure a type cannot be marked with both macros if that's possible maybe it's not

		// TODO:  Make sure singleton is not struct unless it's ~Copyable

		/*
        guard
            let initializer = declaration.as(InitializerDeclSyntax.self),
            let body = initializer.body
        else {
            let diagnostic = Diagnostic(
                node: node._syntaxNode,
                message: SyntaxError.onlyInitializers
            )
            context.diagnose(diagnostic)
            return []
        }

        guard case let .argumentList(arguments) = node.argument,
              arguments.count == 1,
              let argument = arguments.first
        else {
            let diagnostic = Diagnostic(
                node: node._syntaxNode,
                message: SyntaxError.malformedMacro
            )
            context.diagnose(diagnostic)
            return []
        }

        let parameters: [FunctionParameterSyntax] = initializer.signature.input.parameterList.map({$0})
        let maxParameters = parameters.count
        let numberOfInjectableParameters: Int

        switch argument.expression.kind {
        case .identifierExpr: // * = all arguments
            let identifier = argument.expression.cast(IdentifierExprSyntax.self).identifier
            guard identifier.text == "*" else {
                let fixIt = FixIt(
                    message: CustomFixItMessage("Replace '\(identifier.text)' with '*'"),
                    changes: [
                        .replace(
                            oldNode: identifier._syntaxNode,
                            newNode: TokenSyntax(stringLiteral: "*")._syntaxNode
                        )
                    ]
                )
                let diagnostic = Diagnostic(
                    node: node._syntaxNode,
                    message: SyntaxError.unsupportedBinaryOperator,
                    fixIts: [fixIt]
                )
                context.diagnose(diagnostic)
                return []
            }
            numberOfInjectableParameters = maxParameters
        case .integerLiteralExpr: // specific number of arguments
            let digitsString = argument.expression.cast(IntegerLiteralExprSyntax.self).digits
            guard let digits = Int(digitsString.text) else {
                let diagnostic = Diagnostic(
                    node: node._syntaxNode,
                    message: SyntaxError.malformedMacro
                )
                context.diagnose(diagnostic)
                return []
            }
            numberOfInjectableParameters = digits
        default:
            let diagnostic = Diagnostic(
                node: node._syntaxNode,
                message: SyntaxError.malformedMacro
            )
            context.diagnose(diagnostic)
            return []
        }

        guard numberOfInjectableParameters <= maxParameters else {
            let wrongExpression = argument.expression.cast(IntegerLiteralExprSyntax.self)
            let fixIt = FixIt(
                message: CustomFixItMessage("Replace '\(wrongExpression.digits.text)' with '*'"),
                changes: [
                    .replace(
                        oldNode: wrongExpression._syntaxNode,
                        newNode: IdentifierExprSyntax(identifier: TokenSyntax(stringLiteral: "*"))._syntaxNode
                    )
                ]
            )
            let diagnostic = Diagnostic(
                node: node._syntaxNode,
                message: SyntaxError.tooManyParameters(wanted: numberOfInjectableParameters, maximum: maxParameters),
                fixIts: [fixIt]
            )
            context.diagnose(diagnostic)
            return []
        }

        let keptParameters = FunctionParameterListBuilder.buildFinalResult(Array(parameters.dropFirst(numberOfInjectableParameters)))
        let injectedParameters = Array(parameters.dropLast(maxParameters - numberOfInjectableParameters))

        let variables = try injectedParameters.map {
            let name = $0.secondName?.text ?? $0.firstName.text
            guard let type = $0.type.as(SimpleTypeIdentifierSyntax.self) else {
                throw TypeError.injectNonSimpleType
            }
            return "let \(name) = Resolver.resolve(\(type.name.text).self)"
        }

        let generatedInitializer = try InitializerDeclSyntax("init(\(keptParameters))") {
            for variable in variables {
                DeclSyntax(stringLiteral: variable)
            }
            for statement in body.statements {
                statement.trimmed // Remove space that's already there
            }
        }

        return [DeclSyntax(generatedInitializer)]
		 */
    }
}

@main
struct FyperMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ComponentMacro.self,
    ]
}
