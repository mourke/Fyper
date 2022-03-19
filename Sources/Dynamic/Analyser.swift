//
//  Analyser.swift
//  Dynamic
//
//  Created by Mark Bourke on 02/02/2022.
//

import Foundation
import SourceKittenFramework

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
            let root = InitialNode(initializer: initializer, syntaxStructure: initializer.superSyntaxStructure)
            try buildCallingGraph(node: root)
            
            roots.append(root)
        }
        
        logger.log("Graphs generated:\n\(roots.map { $0.description }.joined(separator: "\n"))", kind: .debug)
        
        return roots
    }
    
    // MARK: - Searching for Injectable classes
    
    private func findInjectableInitializers() throws -> Set<InjectableInitializer> {
        var injectableInitializers: Set<InjectableInitializer> = []
        
        for (file, syntaxStructure) in fileStructures {
            guard let filePath = file.path else {
                throw Fyper.Error.basic("File was not created properly. No path found.")
            }
            
            logger.log("Looking for initializers in \(filePath)...", kind: .debug)
            let initializers = findInitializers(syntaxStructure: syntaxStructure)
            logger.log("Found \(initializers.count) initializer(s). \(initializers.map { $0.description }.joined(separator: ", "))", kind: .debug)
            
            if !initializers.isEmpty {
                logger.log("Looking for injectable initializers in \(filePath)...", kind: .debug)
            }
            
            for initializer in initializers {
                guard let location = file.stringView.lineAndCharacter(forCharacterOffset: initializer.offset) else {
                    let message = "Initializer offset \(initializer.offset) was not found in file \(filePath)."
                    throw Fyper.Error.basic(message)
                }
                
                let line = location.line - 1 // make line index 0 based
                
                // TODO: When Swift supports attaching attributes to functions, change this from a comment analysis
                guard let commentLine = file.lines[safe: line - 1] else { // comment will always be one line before init statement
                    logger.log("No line before initializer. Must be at the top of the file \(filePath).", kind: .debug)
                    continue
                }
                
                let lineContent = commentLine.content.replacingOccurrences(of: " ", with: "")
                
                logger.log("Comment found in file \(filePath) for initializer: \(initializer): \(lineContent).", kind: .debug)
                
                guard lineContent.hasPrefix(Constants.LinePrefix) else {
                    logger.log("Comment \(commentLine.content) found in file \(filePath) for initializer: \(initializer) is not an injectable comment.", kind: .debug)
                    continue
                }
                
                logger.log("Injectable comment found in file \(filePath) for initializer: \(initializer).", kind: .debug)
                
                let (injectionKind, arguments): (Injection.Kind, [Injection.Argument: String])
                
                do {
                    (injectionKind, arguments) = try sanitise(comment: lineContent)
                } catch Fyper.Error.basic(let message) {
                    let message = Fyper.Error.Message(message: message, line: commentLine.index, file: filePath)
                    throw Fyper.Error.detail(message)
                }
                
                var injectableArguments: [FunctionArgument] = []
                
                guard arguments.keys.contains(Injection.Argument.arguments) else {
                    let message = Fyper.Error.Message(message: "Arguments to injection call must contain the number of arguments in the initializer to be injected.", line: commentLine.index, file: filePath)
                    throw Fyper.Error.detail(message)
                }
                
                for (argument, value) in arguments {
                    switch argument {
                    case .arguments:
                        let numberOfInjectableTypes: Int
                        let maxArguments = initializer.arguments.count
                        
                        if value == "*" {
                            numberOfInjectableTypes = maxArguments
                        } else if let number = Int(value),
                                    number > 0 &&
                                    number <= maxArguments {
                            numberOfInjectableTypes = number
                        } else {
                            let message = Fyper.Error.Message(message: "Unrecognised argument value '\(value)'. Argument values must be either a number (greater than 0 and less than or equal to the total number of arguments in the initializer (\(maxArguments))) or an asterics denoting that all the arguments are to be injected.", line: commentLine.index, file: filePath)
                            throw Fyper.Error.detail(message)
                        }
                        
                        injectableArguments = initializer.arguments.dropLast(maxArguments - numberOfInjectableTypes)
                    }
                }
                
                let regularArguments = [FunctionArgument](initializer.arguments.dropFirst(injectableArguments.count))
                
                let injectableInitializer = InjectableInitializer(
                    typename: initializer.typename,
                    superSyntaxStructure: initializer.superSyntaxStructure,
                    injectionKind: injectionKind,
                    superDataType: initializer.superDataType,
                    injectableArguments: injectableArguments,
                    regularArguments: regularArguments
                )
                
                logger.log("\(injectionKind.rawValue) \(injectableArguments.count) variable(s) into \(initializer.typename).", kind: .debug)
                
                injectableInitializers.insert(injectableInitializer)
            }
        }
        
        logger.log("Found \(injectableInitializers.count) injectable initializer(s). \(injectableInitializers.map { $0.description }.joined(separator: ", "))", kind: .debug)
        
        return injectableInitializers
    }
    
    private func findTypeAliases(for type: String) -> [String] {
        var aliases: [String] = []
        
        for (file, syntaxStructure) in fileStructures {
            
        }
        
        return aliases
    }
    
    private func findInitializers(syntaxStructure: SyntaxStructure) -> [Initializer] {
        guard let rawValue = syntaxStructure.kind,
              let kind = SwiftDeclarationKind(rawValue: rawValue),
              kind == .class || kind == .struct,
              let typename = syntaxStructure.name
        else {
            logger.log("Syntax structure is not a class or struct. Ignoring...", kind: .debug)
            return syntaxStructure.substructure?.flatMap { findInitializers(syntaxStructure: $0) } ?? []
        }
        
        let dataType: DataType = kind == .class ? .class : .struct
        
        logger.log("Looking for initializers in \(typename)...", kind: .debug)
        
        return syntaxStructure.substructure?.compactMap { structure in
            guard let rawValue = structure.kind,
                  let kind = SwiftDeclarationKind(rawValue: rawValue),
                  kind == .functionMethodInstance,
                  let offset = structure.bodyOffset,
                  let isInitializer = structure.name?.hasPrefix("init("),
                  isInitializer
            else {
                logger.log("No explicit initializers found in \(typename).", kind: .debug)
                return nil
            }
            
            let arguments = structure.substructure?.filter {
                $0.typename != nil
            }.map {
                FunctionArgument(name: $0.name, type: $0.typename!)
            } ?? []
            
            logger.log("Found initializer in \(typename) with \(arguments.count) argument(s).", kind: .debug)

            return Initializer(typename: typename,
                               offset: offset,
                               superSyntaxStructure: syntaxStructure,
                               superDataType: dataType,
                               arguments: arguments)
        } ?? []
    }
    
    private func sanitise(comment: String) throws -> (Injection.Kind, [Injection.Argument: String]) {
        var lineContent = comment
        lineContent.removeFirst(Constants.LinePrefix.count)
        
        
        let types = Injection.Kind.allCases.map { $0.rawValue }.joined(separator: "|")
        guard let range = lineContent.range(of: "(\(types))" + #"\(.+?\)"#, options: .regularExpression) else {
            throw Fyper.Error.basic("Unrecognised injection kind '\(lineContent)'.")
        }
        
        let expression = lineContent[range]
        let openingParenthesisIndex = expression.range(of: "(")!.upperBound
        
        var injectionKindString = expression[expression.startIndex..<openingParenthesisIndex]
        var argumentString = expression[openingParenthesisIndex..<expression.endIndex]
        
        // remove last parenthesis
        injectionKindString.removeLast()
        argumentString.removeLast()
        
        let arguments = try argumentString.split(separator: ",").reduce(into: [Injection.Argument: String]()) {
            let parts = $1.split(separator: ":")
            guard parts.count == 2 else {
                throw Fyper.Error.basic("Unrecognised argument '\($1)'. Arguments must be of the form 'label:value'.")
            }
            
            let label = String(parts[0])
            let value = String(parts[1])
            
            guard let argument = Injection.Argument(rawValue: label) else {
                let message = "Unrecognised argument '\(label)'. Arguments must be one of the following:  \(Injection.Argument.allCases.map { "'\($0.rawValue)'" }.joined(separator: ","))."
                throw Fyper.Error.basic(message)
            }
            
            return $0[argument] = value
        }
        
        let injectionKind = Injection.Kind(rawValue: String(injectionKindString))!
        
        return (injectionKind, arguments)
    }
    
    // MARK: - Building the Calling graph
    
    private func buildCallingGraph(node parent: Node) throws {
        for (file, syntaxStructure) in fileStructures {
            logger.log("Searching \(file.path!) for calls to \(parent.typename) initializers...", kind: .debug)
            guard let initializingClass = fileInitializesType(parent.typename, syntaxStructure: syntaxStructure) else {
                continue
            }
            
            logger.log("Found call to \(parent.typename) initializer in \(file.path!) by \(initializingClass).", kind: .debug)
            
            let node = CallingNode(parent: parent, typename: initializingClass, syntaxStructure: syntaxStructure)
            parent.addChild(node)
            
            try buildCallingGraph(node: node)
        }
    }
    
    private func fileInitializesType(_ type: String, syntaxStructure: SyntaxStructure) -> String? {
        guard let rawValue = syntaxStructure.kind,
              let kind = SwiftDeclarationKind(rawValue: rawValue),
              kind == .class || kind == .struct,
              let typename = syntaxStructure.name
        else {
            logger.log("Syntax structure is not a class or struct. Ignoring...", kind: .debug)
            return syntaxStructure.substructure?.compactMap { fileInitializesType(type, syntaxStructure: $0) }.first
        }
        
        return declarationCallsInitializer(type, syntaxStructure: syntaxStructure) ? typename : nil
    }
    
    private func declarationCallsInitializer(_ type: String, syntaxStructure: SyntaxStructure) -> Bool {
        guard let rawValue = syntaxStructure.kind,
              let kind = SwiftExpressionKind(rawValue: rawValue),
              kind == .call,
              let call = syntaxStructure.name,
              call == "\(type).init" || call == type // TODO: search for shortcut initialisers too
        else {
            return syntaxStructure.substructure?.contains { declarationCallsInitializer(type, syntaxStructure: $0) } ?? false
        }
        
        return true
    }
}
