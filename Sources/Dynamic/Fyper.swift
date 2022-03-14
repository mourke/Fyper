//
//  Dynamic.swift
//  Resolver
//
//  Created by Mark Bourke on 26/01/2022.
//

import Foundation
import ArgumentParser

// encantation: fyper generate [--source <source directory>] [--output <output directory>]

@main
struct Fyper: ParsableCommand {
    
    static var configuration = CommandConfiguration(
        abstract: "An compile-time safe automatic dependency injection program",
        version: "1.0.0",
        subcommands: [Generate.self],
        defaultSubcommand: Generate.self)
    
    struct Generate: ParsableCommand {
        @Option(name: .shortAndLong, help: "The directory of the source code that is to be used with Fyper. All subdirectories will be included too.")
        var sourceDirectory: String
        
        @Option(name: .shortAndLong, help: "The output directory of the generated files. Fyper will create the directory if it does not exist already provided that the root directory exists already.")
        var outputDirectory: String
        
        @Flag(name: .shortAndLong, help: "Show more debugging information.")
        var verbose: Int

        mutating func run() throws {
            let options = Options(sourceDirectory: URL(fileURLWithPath: sourceDirectory),
                                  outputDirectory: URL(fileURLWithPath: outputDirectory),
                                  verboseLogging: verbose > 0)
            let logger = Logger(verboseLogging: options.verboseLogging)
            
            guard options.sourceDirectory.hasDirectoryPath && options.outputDirectory.hasDirectoryPath else {
                throw ValidationError("Input and output directories must be such.")
            }
            
            
            if !FileManager.default.directoryExists(atPath: outputDirectory) {
                try FileManager.default.createDirectory(atPath: outputDirectory, withIntermediateDirectories: false)
            }
            
            do {
                let files = try Parser(logger: logger, options: options).parse()
                let graphs = try Analyser(logger: logger, fileStructures: files).analyse()
                try Validator(logger: logger, graphs: graphs).validate()
                try Generator(logger: logger, options: options, graphs: graphs).generate()
            } catch let e {
                print(e)
                throw ExitCode.failure
            }
        }
    }
}
