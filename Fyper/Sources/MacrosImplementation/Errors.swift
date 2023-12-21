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
	case mustHaveOneInjectableInit(typeName: String)
	case onlyInitialisers
	case noAsync
	case noThrowing

	var message: String {
		switch self {
		case .onlyInitialisers:
			return "'@\(Constants.Inject)' may only be applied to initialiser declarations."
		case let .onlyDataStructures(macroName):
			return "'@\(macroName)' may only be applied to classes, structs or actors."
		case .onlyOneMacro:
			return "'@\(Constants.Reusable)' and '@\(Constants.Singleton)' cannot both be applied to the same declaration."
		case .valueTypeSingleton:
			return "'@\(Constants.Singleton)' cannot be applied to value types."
		case let .mustHaveOneInjectableInit(typeName):
			return "'\(typeName)' must have at least one initialiser marked as '@\(Constants.Inject)'."
		case .noAsync:
			return "'@\(Constants.Inject)' cannot be applied to async functions yet."
		case .noThrowing:
			return "'@\(Constants.Inject)' cannot be applied to throwing functions yet."
		}
	}

	var diagnosticID: MessageID {
		MessageID(domain: "com.mourke.fyper", id: String(describing: self))
	}

	var severity: DiagnosticSeverity {
		.error
	}
}
