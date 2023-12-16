//
//  Errors.swift
//  Fyper
//
//  Created by Mark Bourke on 15/12/2023.
//

import Foundation
import SwiftDiagnostics
import SwiftParserDiagnostics
import Shared

struct CustomFixItMessage: FixItMessage {
	let message: String
	private let messageID: String

	init(_ message: String, messageID: String = #function) {
		self.message = message
		self.messageID = messageID
	}

	var fixItID: MessageID {
		MessageID(domain: "SwiftParser", id: "\(type(of: self)).\(messageID)")
	}
}

enum SyntaxError: DiagnosticMessage {
	case onlyDataStructures(macroName: String)
	case onlyOneMacro
	case valueTypeSingleton
	case mustConformToExposedAs(typeName: String, protocolName: String)

	var message: String {
		switch self {
		case let .onlyDataStructures(macroName):
			return "'@\(macroName)' may only be applied to classes, structs or actors."
		case .onlyOneMacro:
			return "'@\(Constants.Reusable)' and '@\(Constants.Singleton)' cannot both be applied to the same declaration."
		case .valueTypeSingleton:
			return "'@\(Constants.Singleton)' cannot be applied to value types."
		case let .mustConformToExposedAs(typeName, protocolName):
			return "'\(typeName)' does not conform to protocol '\(protocolName)' at declaration site."
		}
	}

	var diagnosticID: MessageID {
		MessageID(domain: "com.mourke.fyper", id: String(describing: self))
	}

	var severity: DiagnosticSeverity {
		.error
	}
}
