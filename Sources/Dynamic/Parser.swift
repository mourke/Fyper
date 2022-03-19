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
    ///  - Throws:   Exception if the file being parsed has encoding errors.
    ///
    /// - Returns:  All the `FileStructure` objects associated with every Swift file in arbitrary order.
    ///
    func parse() throws -> [FileStructure] {
        let swiftFiles = try allSwiftFiles(at: options.sourceDirectory.path)
        let fileNames = swiftFiles.compactMap { $0.split(separator: "/").last }
        
        logger.log("Parsing \(swiftFiles.count) file(s). \(fileNames.joined(separator: ", "))", kind: .debug)
        
        let fileStructures: [FileStructure] = try swiftFiles.map { filePath in
            logger.log("Parsing \(filePath)...", kind: .debug)
            guard let file = File(path: filePath) else {
                let message = Fyper.Error.Message(message: "This file could not be parsed. Is it corrupted or using any non-utf-8 characters?", file: filePath)
                throw Fyper.Error.detail(message)
            }
            
            logger.log("Reading structure of \(filePath)...", kind: .debug)
            let structure = try Structure(file: file)
            
            // print(structure.description)

            guard let jsonData = structure.description.data(using: .utf8) else {
                let message = "Could not parse JSON structure using utf-8 encoding."
                throw Fyper.Error.basic(message)
            }

            logger.log("Mapping JSON to Swift Object...", kind: .debug)
            return (file, try JSONDecoder().decode(SyntaxStructure.self, from: jsonData))
        }
        
        return fileStructures
    }
    
    private func allSwiftFiles(at path: String) throws -> [String] {
        var swiftFiles: [String] = []
        try FileManager.default.contentsOfDirectory(atPath: path).forEach { name in
            let subpath = "\(path)/\(name)"
            if FileManager.default.directoryExists(atPath: subpath) {
                swiftFiles += try allSwiftFiles(at: subpath)
            } else {
                let components = name.components(separatedBy: ".")
                
                if components.last == Constants.FileExtension &&
                    components.first != Constants.GeneratedFileName {
                    swiftFiles.append(subpath)
                }
            }
        }
        
        return swiftFiles
    }
}
