//
//  Fyper.swift
//  Fyper
//
//  Created by Mark Bourke on 26/01/2022.
//

import Foundation
import ArgumentParser

// encantation: fyper generate [--target-name <target name> -o <output> --source-files <source files>]

@main
struct Fyper: ParsableCommand {

    static var configuration = CommandConfiguration(
        abstract: "An compile-time safe automatic dependency injection program",
        version: "1.0.0",
        subcommands: [Generate.self],
        defaultSubcommand: Generate.self)

    struct Generate: ParsableCommand {
		@Option(name: .long, help: "The name of the target whose dependencies are being generated.")
		var targetName: String

		@Option(name: .shortAndLong, help: "The path of the file that the generated code will be written to.")
		var output: String

        @Option(name: .shortAndLong, parsing: ArrayParsingStrategy.upToNextOption, help: "The Swift source files that are to be used with Fyper.")
        var sourceFiles: [String]

        @Flag(name: .shortAndLong, help: "Show more debugging information.")
        var verbose: Int

        mutating func run() throws {
            let verboseLogging = verbose > 0
            let logger = Logger(verboseLogging: verboseLogging)

            do {
                let files = try Parser(logger: logger, swiftFiles: sourceFiles).parse()
                let analysis = Analyser(logger: logger, fileStructures: files).analyse()
				let container = try Generator(logger: logger, targetName: targetName, analysis: analysis).generate()

				let containerURL = URL(filePath: output)

				try FileManager.default.createDirectory(
					at: containerURL.deletingLastPathComponent(),
					withIntermediateDirectories: true
				)
				try container.write(to: containerURL, atomically: true, encoding: .utf8)
            } catch let e {
                print(e)
                throw ExitCode.failure
            }
        }
    }
}
