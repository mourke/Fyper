//
//  Parser.swift
//  Fyper
//
//  Created by Mark Bourke on 11/03/2022.
//

import Foundation
import SwiftSyntax
import SwiftParser

typealias FileStructure = (String, SourceFileSyntax)

struct Parser {

    let logger: Logger
    let swiftFiles: [String]

    ///
    /// Parses all the Swift files in the input directory and returns them in a `FileStructure` object.
    ///
    ///  - Throws:   Exception if the file being parsed has encoding errors.
    ///
    /// - Returns:  All the `SourceFileSyntax` objects associated with every Swift file in arbitrary order.
    ///
    func parse() throws -> [FileStructure] {
        let fileNames = swiftFiles.compactMap { $0.split(separator: "/").last }
        
        logger.log("Parsing \(swiftFiles.count) file(s). \(fileNames.joined(separator: ", "))", kind: .debug)
        
        let fileStructures: [FileStructure] = try swiftFiles.map { filePath in
            logger.log("Parsing \(filePath)...", kind: .debug)

            let expandedPathString = NSString(string: filePath).expandingTildeInPath

            guard let data = FileManager.default.contents(atPath: expandedPathString),
                  let file = String(data: data, encoding: .utf8) else {
                let message = Fyper.Error.Message(message: "The file could not be parsed. Is it corrupted or using any non-utf-8 characters?", file: filePath)
                throw Fyper.Error.detail(message)
            }
            
            logger.log("Reading structure of \(filePath)...", kind: .debug)
            let structure = SwiftParser.Parser.parse(source: file)

            return (filePath, structure)
        }
        
        return fileStructures
    }
}
