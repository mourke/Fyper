import SwiftSyntaxMacros
import MacrosImplementation
import SwiftSyntaxMacrosTestSupport
import XCTest

let testMacros: [String: Macro.Type] = [
    "Reusable": ComponentMacro.self,
	"Singleton": ComponentMacro.self
]

final class MacrosTests: XCTestCase {

    func testMacro() {
        assertMacroExpansion(
            """
			@Singleton(exposeAs: MyProtocol)
            final class MyGenericClass<S: View> {
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
            }
            """,
            macros: testMacros
        )
    }
}
