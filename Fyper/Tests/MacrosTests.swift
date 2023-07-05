import SwiftSyntaxMacros
import MacrosImplementation
import SwiftSyntaxMacrosTestSupport
import XCTest

let testMacros: [String: Macro.Type] = [
    "Inject": InjectMacro.self,
]

final class MacrosTests: XCTestCase {

    func testMacro() {
        assertMacroExpansion(
            """
            final class MyClass {
                @Inject(args: 2)
                init(logger: Logger, tracker: Tracker, id: String) {
                    self.logger = logger
                    self.tracker = tracker
                    self.id = id
                }
            }
            """,
            expandedSource: """
            final class MyClass {
                init(logger: Logger, tracker: Tracker, id: String) {
                    self.logger = logger
                    self.tracker = tracker
                    self.id = id
                }
                init(id: String) {
                    let logger = Resolver.resolve(Logger.self)
                    let tracker = Resolver.resolve(Tracker.self)
                    self.logger = logger
                    self.tracker = tracker
                    self.id = id
                }
            }
            """,
            macros: testMacros
        )
    }
}
