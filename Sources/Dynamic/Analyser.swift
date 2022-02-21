//
//  Analyser.swift
//  Dynamic
//
//  Created by Mark Bourke on 02/02/2022.
//

import Foundation
import SourceKittenFramework

struct Analyser {
    
    let logger: Logger
    let options: Options
    
    func analyse() throws -> Set<Injection> {
        let fileNames = try FileManager.default.contentsOfDirectory(atPath: options.sourceDirectory.path)
        let swiftFileNames = fileNames.filter { $0.components(separatedBy: ".").last == Constants.FileExtension }
        
        logger.log("Analysing \(swiftFileNames.count) file(s). \(swiftFileNames.joined(separator: ", "))", kind: .debug)
        
        var injections: Set<Injection> = []
        
        for fileName in swiftFileNames {
            let filePath = "\(options.sourceDirectory.relativePath)/\(fileName)"
            
            logger.log("Parsing \(filePath)...", kind: .debug)
            guard let file = File(path: filePath) else {
                let message = Fyper.Error.Message(message: "This file could not be parsed. Is it corrupted or using any non-utf-8 characters?", file: filePath)
                throw Fyper.Error.parseError(message)
            }
            
            logger.log("Reading structure of \(filePath)...", kind: .debug)
            let structure = try Structure(file: file)
            
            guard let jsonData = structure.description.data(using: .utf8) else {
                let message = "Could not parse JSON structure using utf-8 encoding."
                throw Fyper.Error.internalError(message)
            }
            
            logger.log("Mapping JSON to Swift Object...", kind: .debug)
            let syntaxStructure = try JSONDecoder().decode(SyntaxStructure.self, from: jsonData)
            
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
                
                injections.formUnion(initializer.arguments.map {
                    return Injection(typenameToBeInjected: $0,
                                     typenameToBeInjectedInto: initializer.typename,
                                     kind: injectionKind)
                })
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
            
            let arguments = structure.substructure?.compactMap { $0.typename } ?? []
            
            logger.log("Found initializer in \(typename) with \(arguments.count) argument(s).", kind: .debug)

            return Initializer(typename: typename, offset: offset, arguments: arguments)
        } ?? []
    }
}
