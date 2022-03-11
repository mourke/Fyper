//
//  Parser.swift
//  Dynamic
//
//  Created by Mark Bourke on 11/03/2022.
//

import Foundation
import SourceKittenFramework

typealias FileStructure = (File, SyntaxStructure)

struct Parser {
    
    let logger: Logger
    let options: Options
    
    ///
    /// Parses all the Swift files in the input directory and returns them in a `FileStructure` object.
    ///
    /// - Returns:  All the `FileStructure` objects associated with every Swift file in arbitrary order.
    ///
    func parse() throws -> [FileStructure] {
        let fileNames = try FileManager.default.contentsOfDirectory(atPath: options.sourceDirectory.path)
        let swiftFileNames = fileNames.filter { $0.components(separatedBy: ".").last == Constants.FileExtension }
        
        logger.log("Parsing \(swiftFileNames.count) file(s). \(swiftFileNames.joined(separator: ", "))", kind: .debug)
        
        let fileStructures: [FileStructure] = try swiftFileNames.map { fileName in
            let filePath = "\(options.sourceDirectory.relativePath)/\(fileName)"
            
            logger.log("Parsing \(filePath)...", kind: .debug)
            guard let file = File(path: filePath) else {
                let message = Fyper.Error.Message(message: "This file could not be parsed. Is it corrupted or using any non-utf-8 characters?", file: filePath)
                throw Fyper.Error.parseError(message)
            }
            
            logger.log("Reading structure of \(filePath)...", kind: .debug)
            let structure = try Structure(file: file)
            
            print(structure.description)

            guard let jsonData = structure.description.data(using: .utf8) else {
                let message = "Could not parse JSON structure using utf-8 encoding."
                throw Fyper.Error.internalError(message)
            }

            logger.log("Mapping JSON to Swift Object...", kind: .debug)
            return (file, try JSONDecoder().decode(SyntaxStructure.self, from: jsonData))
        }
        
        return fileStructures
    }
}
