//
//  Dynamic.swift
//  Resolver
//
//  Created by Mark Bourke on 26/01/2022.
//

import Foundation
import ArgumentParser

// encantation: fyper generate [--sourceFiles <source files>]

@main
struct Fyper: ParsableCommand {

    static var configuration = CommandConfiguration(
        abstract: "An compile-time safe automatic dependency injection program",
        version: "1.0.0",
        subcommands: [Generate.self],
        defaultSubcommand: Generate.self)

    struct Generate: ParsableCommand {
        @Option(name: .shortAndLong, parsing: ArrayParsingStrategy.upToNextOption, help: "The Swift source files that are to be used with Fyper.")
        var sourceFiles: [String]

        @Flag(name: .shortAndLong, help: "Show more debugging information.")
        var verbose: Int

        mutating func run() throws {
            let verboseLogging = verbose > 0
            let logger = Logger(verboseLogging: verboseLogging)

            do {
                let files = try Parser(logger: logger, swiftFiles: sourceFiles).parse()
                let graphs = try Analyser(logger: logger, fileStructures: files).analyse()
                try Validator(logger: logger, graphs: graphs).validate()
            } catch let e {
                print(e)
                throw ExitCode.failure
            }
        }
    }
}
