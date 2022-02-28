//
//  Analyser.swift
//  Dynamic
//
//  Created by Mark Bourke on 02/02/2022.
//

import Foundation
import SourceKittenFramework

struct Analyser {
    
    typealias FileStructure = (File, SyntaxStructure)
    
    let logger: Logger
    let options: Options
    
    func analyse() throws {
        let fileNames = try FileManager.default.contentsOfDirectory(atPath: options.sourceDirectory.path)
        let swiftFileNames = fileNames.filter { $0.components(separatedBy: ".").last == Constants.FileExtension }
        
        logger.log("Analysing \(swiftFileNames.count) file(s). \(swiftFileNames.joined(separator: ", "))", kind: .debug)
        
        let fileStructures: [FileStructure] = try swiftFileNames.map { fileName in
            let filePath = "\(options.sourceDirectory.relativePath)/\(fileName)"
            
            logger.log("Parsing \(filePath)...", kind: .debug)
            guard let file = File(path: filePath) else {
                let message = Fyper.Error.Message(message: "This file could not be parsed. Is it corrupted or using any non-utf-8 characters?", file: filePath)
                throw Fyper.Error.parseError(message)
            }
            
            logger.log("Reading structure of \(filePath)...", kind: .debug)
            let structure = try Structure(file: file)
            
//            print(structure.description)

            guard let jsonData = structure.description.data(using: .utf8) else {
                let message = "Could not parse JSON structure using utf-8 encoding."
                throw Fyper.Error.internalError(message)
            }

            logger.log("Mapping JSON to Swift Object...", kind: .debug)
            return (file, try JSONDecoder().decode(SyntaxStructure.self, from: jsonData))
        }
        
        let injections = try findInjections(in: fileStructures)
        
        for (initializer, _) in injections {
            var root = Node(parent: nil, typename: initializer.typename)
            
            try buildCallingGraph(node: &root, fileStructures: fileStructures)
            
            print(root)
        }
    }
    
    private func findInjections(in fileStructures: [FileStructure]) throws -> [Initializer: Set<Injection>] {
        var injections: [Initializer: Set<Injection>] = [:]
        
        for (file, syntaxStructure) in fileStructures {
            guard let filePath = file.path else {
                throw Fyper.Error.internalError("File was not created properly. No path found.")
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
                    throw Fyper.Error.internalError(message)
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
                    throw Fyper.Error.parseError(message)
                }
                
                logger.log("\(initializer) will be \(injectionKind.rawValue).", kind: .debug)
                
                injections[initializer, default: []].formUnion(initializer.arguments.map {
                    return Injection(typenameToBeInjected: $0,
                                     typenameToBeInjectedInto: initializer.typename,
                                     kind: injectionKind)
                })
            }
        }
        
        logger.log("Found \(injections.count) injection(s). \(injections.values.map { $0.description }.joined(separator: ", "))", kind: .debug)
        
        return injections
    }
    
    private func buildCallingGraph(node parent: inout Node, fileStructures: [FileStructure]) throws {
        for (_, syntaxStructure) in fileStructures {
            guard let initializingClass = fileInitializesType(parent.typename, syntaxStructure: syntaxStructure) else {
                continue
            }
            
            var node = Node(parent: parent, typename: initializingClass)
            parent.addChild(node)
            
            try buildCallingGraph(node: &node, fileStructures: fileStructures)
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
            
            let arguments = structure.substructure?.compactMap { $0.typename } ?? []
            
            logger.log("Found initializer in \(typename) with \(arguments.count) argument(s).", kind: .debug)

            return Initializer(typename: typename, offset: offset, arguments: arguments)
        } ?? []
    }
}
