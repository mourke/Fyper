//
//  Analysis.swift
//  Fyper
//
//  Created by Mark Bourke on 18/12/2023.
//

import Foundation
import SwiftSyntax

/// The result of the `Analyser` stage.
struct Analysis {

	/// All the data structures participating in dependency injection.
	let components: [Component]

	/// 
	/// The sorted, unique import statements associated with every injectable component.
	///	- Note:	This is not a `Set` because all `Syntax` elements conform to `SyntaxHashable` which compares a UUID for
	///	syntax tree traversal which would break the functionality that `Set` depends upon so we have to implement this ourselves manually.
	let imports: [ImportPathComponentListSyntax]
}
