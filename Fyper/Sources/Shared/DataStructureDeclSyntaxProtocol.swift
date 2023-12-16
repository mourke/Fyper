//
//  DataStructureDeclSyntaxProtocol.swift
//  Fyper
//
//  Created by Mark Bourke on 28/06/2023.
//

import Foundation
import SwiftSyntax

public protocol DataStructureDeclSyntaxProtocol: SyntaxProtocol {
    var identifier: TokenSyntax { get }
    var id: SyntaxIdentifier { get }
    var memberBlock: MemberBlockSyntax { get }
	var attributes: AttributeListSyntax { get }
    var inheritanceClause: InheritanceClauseSyntax? { get }
}

extension ClassDeclSyntax: DataStructureDeclSyntaxProtocol { }
extension StructDeclSyntax: DataStructureDeclSyntaxProtocol { }
extension ActorDeclSyntax: DataStructureDeclSyntaxProtocol { }
