import PackagePlugin
import XcodeProjectPlugin

@main
struct BuildPlugin: XcodeBuildToolPlugin, BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        let generatorTool = try context.tool(named: "Analyser")

        let swiftFiles = target.sourceModule!.sourceFiles.filter({$0.path.extension == "swift"})
		let outputFile = "Public/\(target.name)Container.swift"

        return [ .buildCommand(
            displayName: "Generate dependency container",
            executable: generatorTool.path,
            arguments: [
                "generate",
				"--target-name",
				target.name,
				"-o",
				outputFile,
                "--source-files"
            ] + swiftFiles.map(\.path.string),
            inputFiles: swiftFiles.map(\.path),
			outputFiles: [outputFile].map(Path.init)
        )]
    }
    
    // Entry point for creating build commands for targets in Xcode projects.
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        let generatorTool = try context.tool(named: "Analyser")

        let swiftFiles = target.inputFiles.filter({$0.path.extension == "swift"})
		let outputFile = "Public/\(target.displayName)Container.swift"

        return [ .buildCommand(
            displayName: "Generate dependency container",
            executable: generatorTool.path,
            arguments: [
                "generate",
				"--target-name",
				target.displayName,
				"-o",
				outputFile,
                "--source-files"
            ] + swiftFiles.map(\.path.string),
            inputFiles: swiftFiles.map(\.path),
			outputFiles: [outputFile].map(Path.init)
        )]
    }
}
