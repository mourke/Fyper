//
//  Generator.swift
//  Dynamic
//
//  Created by Mark Bourke on 02/02/2022.
//

import Foundation

///
/// Generates the code needed to make the injection happen.
///
/// - Note: While this can be called directly after the *Analyser* stage, doing so is considered dangerous and might lead to code being generated that will cause runtime crashes. This **must** be called after the *Validator* stage.
///
struct Generator {
    
    let logger: Logger
    let options: Options
    
    /// The calling graph starting from the initialiser that specifies the types that need to be injected into that class/struct, obtained from the *Analyser* stage.
    let graphs: [InitialNode]
    
    ///
    /// Generates code to allow the injection to take place behind the scenes.
    ///
    ///   - Throws:   Exception if the generated file cannot be written to disk.
    ///
    func generate() throws {
        var code = options.additionalImports.map { "import \($0)" }.joined(separator: "\n")
        
        for initialNode in graphs {
            logger.log("Generating convenience initialiser for '\(initialNode.typename)'...", kind: .debug)
            
            let initialiser = initialNode.initializer
            
            let convenienceInit: String
            
            switch initialiser.superDataType {
            case .struct:
                convenienceInit = "init"
            case .class:
                convenienceInit = "convenience init"
            }
            
            let convenienceInitArguments = initialiser.regularArguments.map { $0.description }.joined(separator: ", ")
            
            let initArguments = initialiser.arguments.map { "\($0.name): \($0.name)" }.joined(separator: ", ")
            
            let variables = initialiser.injectableArguments.map {
                "let \($0.name) = \(Constants.Resolve)(\($0.type).self)"
            }.joined(separator: "\n\t\t")
            
            let `extension` = """


extension \(initialiser.typename) {
    
    \(convenienceInit)(\(convenienceInitArguments)) {
        \(variables)
        self.init(\(initArguments))
    }
}
"""
            code += `extension`
        }
        
        logger.log("Writing generated code to disk...", kind: .debug)
        
        let filePath = "\(options.outputDirectory.path)/\(Constants.GeneratedFileName).swift"
        try code.write(toFile: filePath, atomically: true, encoding: .ascii)
    }
}
