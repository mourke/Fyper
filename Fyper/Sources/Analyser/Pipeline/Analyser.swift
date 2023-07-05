//
//  Analyser.swift
//  Dynamic
//
//  Created by Mark Bourke on 02/02/2022.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

enum AnalyserError: Error {
    case unsupportedInitializer(_ syntax: FunctionCallExprSyntax)
}

/// Analyses the code and returns a calling graph of all classes that need to be injected.
struct Analyser {

    let logger: Logger

    /// Parsed file structures obtained from the *Parser* stage.
    let fileStructures: [FileStructure]

    ///
    /// Begins the analysis of the source code specified in the Options.
    /// At a high level, this algorithm searches the entire code base for initializer methods marked with the `@SafeInject` keyword.
    /// Once found, the code base is then searched for every place that these classes are initialized.
    /// This repeats, building a calling graph until the first place where the classes are initialised is found.
    ///
    /// - Throws:   Exception if the user has incorrectly declared an injection.
    ///
    /// - Returns:  A calling graph for every class that needs to be injected, along with what needs to be injected.
    ///
    func analyse() throws -> [InitialNode] {
        let injectableInitializers = try findInjectableInitializers()
        var roots: [InitialNode] = []
        roots.reserveCapacity(injectableInitializers.count)

        logger.log("Generating call graph for \(injectableInitializers.count) injection(s)...", kind: .debug)
        for initializer in injectableInitializers {
            let root = InitialNode(initializer: initializer)
            try buildCallingGraph(node: root)

            roots.append(root)
        }

        logger.log("Graphs generated:\n\(roots.map { $0.description }.joined(separator: "\n"))", kind: .debug)

        return roots
    }

    // MARK: - Searching for Injectable classes

    private func findInjectableInitializers() throws -> Set<InjectableInitializer> {
        var injectableInitializers: Set<InjectableInitializer> = []

        for (filePath, syntaxStructure) in fileStructures {
            logger.log("Looking for initializers in \(filePath)...", kind: .debug)
            let initializers = findInitializers(syntax: syntaxStructure)
            logger.log("Found \(initializers.flatMap({$0.1.count}).reduce(0, +)) initializer(s).", kind: .debug)

            if !initializers.isEmpty {
                logger.log("Filtering by injectable initializers...", kind: .debug)
            }

            for (dataStructure, initializers) in initializers {
                for initializer in initializers {
                    // All of the type/syntax checking for this will be handled in the macro, we are just
                    // extracting pre-validated values
                    guard
                        let attributes = initializer.attributes, // '@' modifiers to initialiser
                        let argument = attributes.compactMap({ extractInjectMacroArguments(from: $0) }).first // there should only be one inject macro per initialiser statement
                    else { continue }

                    let numberOfInjectableArguments: Int

                    switch argument.expression.kind {
                    case .identifierExpr: // * = all arguments
                        numberOfInjectableArguments = initializer.signature.input.parameterList.count
                    case .integerLiteralExpr: // specific number of arguments
                        numberOfInjectableArguments = Int(argument.expression.cast(IntegerLiteralExprSyntax.self).digits.text)!
                    default:
                        continue
                    }

                    let injectableInitializer = InjectableInitializer(
                        rootDataStructureSyntax: dataStructure,
                        initializerSyntax: initializer,
                        numberOfInjectableParameters: numberOfInjectableArguments
                    )

                    logger.log("Found injectable initializer: \(injectableInitializer.description).", kind: .debug)

                    injectableInitializers.insert(injectableInitializer)
                }
            }
        }

        return injectableInitializers
    }

    private func extractInjectMacroArguments(from initialiserAttribute: AttributeListSyntax.Element) -> TupleExprElementSyntax? {
        guard
            case let .attribute(syntax) = initialiserAttribute,
            case let .argumentList(list) = syntax.argument
        else { return nil }

        let attributeName = syntax.attributeName.cast(SimpleTypeIdentifierSyntax.self).name.text
        let isInjectMacro = attributeName == Constants.Inject

        return isInjectMacro ? list.first : nil
    }

    private func findInitializers(syntax: SyntaxProtocol) -> [(DataStructureDeclSyntaxProtocol, [InitializerDeclSyntax])] {
        let children = syntax.children(viewMode: .fixedUp)

        guard
            syntax.kind == .classDecl ||
            syntax.kind == .structDecl ||
            syntax.kind == .actorDecl
        else {
            return children.flatMap { findInitializers(syntax: $0) }
        }
        let dataStructure: DataStructureDeclSyntaxProtocol = (syntax.as(ClassDeclSyntax.self) ?? syntax.as(StructDeclSyntax.self)) ?? syntax.cast(ActorDeclSyntax.self)

        let typename = dataStructure.identifier.text
        logger.log("Looking for initializers in \(typename)...", kind: .debug)

        let initializers: [InitializerDeclSyntax] = dataStructure.memberBlock.members.compactMap { child in
            let declaration = child.decl
            guard declaration.kind == .initializerDecl else {
                return nil
            }

            let initialiser = declaration.cast(InitializerDeclSyntax.self)
            logger.log("Found initializer in \(typename): \(initialiser.description)", kind: .debug)

            return initialiser.detach() // save memory by detaching
        }

        return [(dataStructure, initializers)]
    }

    // MARK: - Building the Calling graph

    private func buildCallingGraph(node parent: Node) throws {
        for (file, structure) in fileStructures {
            logger.log("Searching \(file) for calls to \(parent.typename) initializers...", kind: .debug)
            do {
                guard let dataStructure = try searchForInitializationInFile(of: parent.typename, syntax: structure) else {
                    continue
                }

                logger.log("Found call to \(parent.typename) initializer in \(file).", kind: .debug)

                let node = CallingNode(parent: parent, enclosingDataStructure: dataStructure)
                parent.addChild(node)

                try buildCallingGraph(node: node)
            } catch AnalyserError.unsupportedInitializer(let syntax) {
                let location = SourceLocationConverter(file: file, tree: structure).location(for: syntax.position)
                let message = Fyper.Error.Message(
                    message: "Unsupported initializer. Static type information not available for shortcut initializer in this context.",
                    line: location.line,
                    column: location.column,
                    file: file
                )
                throw Fyper.Error.detail(message)
            }
        }
    }

    private func searchForInitializationInFile(of typename: String, syntax: SyntaxProtocol) throws -> DataStructureDeclSyntaxProtocol? {
        guard
            syntax.kind == .classDecl ||
            syntax.kind == .structDecl ||
            syntax.kind == .actorDecl
        else {
            return try syntax.children(viewMode: .fixedUp).compactMap { try searchForInitializationInFile(of: typename, syntax: $0) }.first
        }
        let dataStructure: DataStructureDeclSyntaxProtocol = (syntax.as(ClassDeclSyntax.self) ?? syntax.as(StructDeclSyntax.self)) ?? syntax.cast(ActorDeclSyntax.self)

        return try dataStructureInitializes(typename: typename, syntax: dataStructure) ? dataStructure : nil
    }

    private func dataStructureInitializes(typename: String, syntax: SyntaxProtocol) throws -> Bool {
        guard let call = syntax.as(FunctionCallExprSyntax.self),
              try functionCall(call, isInitialisingType: typename)
        else {
            for child in syntax.children(viewMode: .fixedUp) {
                // Stop at the first one
                if try dataStructureInitializes(typename: typename, syntax: child) {
                    return true
                }
            }
            return false
        }

        return true
    }

    private func functionCall(_ call: FunctionCallExprSyntax, isInitialisingType typename: String) throws -> Bool {
        /*
         There are many ways to initialise a swift object. E.g.

         // Explicit

         MyObject()
         MyObject.init()

         // Inferred from type information

         let variable: MyObject = .init()
         myFunction(.init())
         */

        if let calledExpression = call.calledExpression.as(IdentifierExprSyntax.self) { // Explicit
            let isInitializer = calledExpression.identifier.text == typename
            if isInitializer {
                logger.log("Explicit initializer found.", kind: .debug)
            }
            return isInitializer
        } else if let calledExpression = call.calledExpression.as(MemberAccessExprSyntax.self),
                  calledExpression.name.text == Constants.Init {
            if let _ = calledExpression.base?.as(SuperRefExprSyntax.self) {
                logger.log("Found super init call, ignoring...", kind: .debug)
            } else if let identifier = calledExpression.base?.as(IdentifierExprSyntax.self) { // Explicit
                let isInitializer = identifier.identifier.text == typename
                if isInitializer {
                    logger.log("Explicit initializer found.", kind: .debug)
                }
                return isInitializer
            } else if let parent = call.parent,
                      let foundType = findTypeOfInitializer(from: parent) { // Inferred. We have to statically look up the type.
                return foundType.name.text == typename
            } else { // Unable to statically look up type. Throw error otherwise our dependency graph could be wrong
                throw AnalyserError.unsupportedInitializer(call)
            }
        } else {
            logger.log("Function call is not a recognised initializer.", kind: .debug)
        }

        return false
    }

    private func findTypeOfInitializer(from syntax: SyntaxProtocol) -> SimpleTypeIdentifierSyntax? {
        if let binding = syntax.as(PatternBindingSyntax.self) { // let variable: MyObject = .init()
            logger.log("Shortcut Pattern Binding Initializer found.", kind: .debug)
            return binding.typeAnnotation?.type.as(SimpleTypeIdentifierSyntax.self)
        } else if let functionCall = syntax.as(FunctionCallExprSyntax.self) { // myFunction(.init())
            // TODO: figure out a way to determine this
            return nil
        } else if let parent = syntax.parent { // walk up the tree until we find type information
            return findTypeOfInitializer(from: parent)
        } else {
            return nil
        }
    }
}
