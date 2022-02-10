//
//  Analyser.swift
//  Dynamic
//
//  Created by Mark Bourke on 02/02/2022.
//

import Foundation
import SourceKittenFramework

struct Analyser {
    
    enum Error: Swift.Error {
        case unableToReadFile
        case parseError
        case unknownInjectionType
    }
    
    static let shared = Analyser()
    
    private init() {}
    
    func analyse(_ path: String) throws -> Set<Injection> {
        let fileNames = try FileManager.default.contentsOfDirectory(atPath: path)
        let swiftFileNames = fileNames.filter { $0.components(separatedBy: ".").last == Constants.FileExtension }
        
        var injections: Set<Injection> = []
        
        for fileName in swiftFileNames {
            let filePath = "\(path)/\(fileName)"
            guard let file = File(path: filePath) else {
                throw Error.unableToReadFile
            }
            let structure = try Structure(file: file)
            guard let jsonData = structure.description.data(using: .utf8) else {
                throw Error.unableToReadFile
            }
            
            let syntaxStructure = try JSONDecoder().decode(SyntaxStructure.self, from: jsonData)
            let initializers = findInitializers(syntaxStructure: syntaxStructure)
            
            for initializer in initializers {
                guard let location = file.stringView.lineAndCharacter(forCharacterOffset: initializer.offset) else {
                    throw Error.parseError
                }
                
                let line = location.line - 1 // make line index 0 based
                
                guard let commentLine = file.lines[safe: line - 1] else {
                    continue
                }
                
                var lineContent = commentLine.content.replacingOccurrences(of: " ", with: "")
                
                guard lineContent.hasPrefix(Constants.LinePrefix) else {
                    continue
                }
                
                lineContent.removeFirst(Constants.LinePrefix.count)
                
                guard let injectionKind = Injection.Kind(rawValue: lineContent) else {
                    throw Error.unknownInjectionType
                }
                
                injections.formUnion(initializer.arguments.map {
                    return Injection(typenameToBeInjected: $0,
                                     typenameToBeInjectedInto: initializer.typename,
                                     kind: injectionKind)
                })
            }
        }
        
        return injections
    }
    
    private func findInitializers(syntaxStructure: SyntaxStructure) -> [Initializer] {
        guard let rawValue = syntaxStructure.kind,
              let kind = SwiftDeclarationKind(rawValue: rawValue),
              kind == .class
        else {
            return syntaxStructure.substructure?.flatMap { findInitializers(syntaxStructure: $0) } ?? []
        }
        
        return syntaxStructure.substructure?.compactMap { structure in
            guard let rawValue = structure.kind,
                  let kind = SwiftDeclarationKind(rawValue: rawValue),
                  kind == .functionMethodInstance,
                  let isInitializer = structure.name?.hasPrefix("init("),
                  isInitializer
            else {
                return nil
            }
            
            let arguments = structure.substructure?.compactMap { $0.typename } ?? []
            
            guard let typename = syntaxStructure.name,
                  let offset = structure.bodyOffset
            else {
                return nil
            }

            return Initializer(typename: typename, offset: offset, arguments: arguments)
        } ?? []
    }
}
