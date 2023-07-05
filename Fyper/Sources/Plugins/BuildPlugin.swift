import PackagePlugin
import XcodeProjectPlugin

@main
struct BuildPlugin: XcodeBuildToolPlugin, BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        let generatorTool = try context.tool(named: "Analyser")

        let swiftFiles = target.sourceModule!.sourceFiles.filter({$0.path.extension == "swift"})

        return [ .buildCommand(
            displayName: "Validate dependency injection graph",
            executable: generatorTool.path,
            arguments: [
                "generate",
                "--source-files"
            ] + swiftFiles.map(\.path.string),
            inputFiles: swiftFiles.map(\.path)
        )]
    }
    
    // Entry point for creating build commands for targets in Xcode projects.
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        let generatorTool = try context.tool(named: "Analyser")

        let swiftFiles = target.inputFiles.filter({$0.path.extension == "swift"})

        return [ .buildCommand(
            displayName: "Validate dependency injection graph",
            executable: generatorTool.path,
            arguments: [
                "generate",
                "--source-files"
            ] + swiftFiles.map(\.path.string),
            inputFiles: swiftFiles.map(\.path)
        )]
    }
}
