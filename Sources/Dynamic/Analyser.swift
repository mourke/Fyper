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
        let injections = try findInjections(in: fileStructures)
        var roots: [InitialNode] = []
        roots.reserveCapacity(injections.count)
        
        logger.log("Generating call graph for \(injections.count) injection(s)...", kind: .debug)
        for initializer in injections {
            let root = InitialNode(initializer: initializer, syntaxStructure: initializer.superSyntaxStructure)
            try buildCallingGraph(node: root, fileStructures: fileStructures)
            
            roots.append(root)
        }
        
        logger.log("Graphs generated:\n\(roots.map { $0.description }.joined(separator: "\n"))", kind: .debug)
        
        return roots
    }
    
    // MARK: - Searching for Injectable classes
    
    private func findInjections(in fileStructures: [FileStructure]) throws -> Set<Initializer> {
        var injections: Set<Initializer> = []
        
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
                
                var lineContent = commentLine.content.replacingOccurrences(of: " ", with: "")
                
                logger.log("Comment found in file \(filePath) for initializer: \(initializer): \(lineContent).", kind: .debug)
                
                guard lineContent.hasPrefix(Constants.LinePrefix) else {
                    logger.log("Comment \(commentLine.content) found in file \(filePath) for initializer: \(initializer) is not an injectable comment.", kind: .debug)
                    continue
                }
                
                logger.log("Injectable comment found in file \(filePath) for initializer: \(initializer).", kind: .debug)
                
                lineContent.removeFirst(Constants.LinePrefix.count)
                
                guard let injectionKind = Injection.Kind(rawValue: lineContent) else {
                    let message = Fyper.Error.Message(message: "Unrecognised injection kind.", line: commentLine.index, file: filePath)
                    throw Fyper.Error.detail(message)
                }
                
                logger.log("\(initializer) will be \(injectionKind.rawValue).", kind: .debug)
                
                injections.insert(initializer)
            }
        }
        
        logger.log("Found \(injections.count) injection(s). \(injections.map { $0.description }.joined(separator: ", "))", kind: .debug)
        
        return injections
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
                               injectableArguments: arguments,
                               regularArguments: [], // TODO: Implement this
                               superSyntaxStructure: syntaxStructure)
        } ?? []
    }
    
    // MARK: - Building the Calling graph
    
    private func buildCallingGraph(node parent: Node, fileStructures: [FileStructure]) throws {
        for (file, syntaxStructure) in fileStructures {
            logger.log("Searching \(file.path!) for calls to \(parent.typename) initializers...", kind: .debug)
            guard let initializingClass = fileInitializesType(parent.typename, syntaxStructure: syntaxStructure) else {
                continue
            }
            
            logger.log("Found call to \(parent.typename) initializer in \(file.path!) by \(initializingClass).", kind: .debug)
            
            let node = CallingNode(parent: parent, typename: initializingClass, syntaxStructure: syntaxStructure)
            parent.addChild(node)
            
            try buildCallingGraph(node: node, fileStructures: fileStructures)
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
