//
//  Node.swift
//  Dynamic
//
//  Created by Mark Bourke on 28/02/2022.
//

import Foundation

protocol Node: AnyObject, CustomStringConvertible {
    
    var typename: String { get }
    var children: AnyCollection<Node> { get }
    var parent: Node? { get }
    var syntaxStructure: SyntaxStructure { get }
    
    @discardableResult
    func addChild<C: Node & Hashable>(_ child: C) -> Bool
}

extension Node {
    private func treeLines(_ nodeIndent: String = "", _ childIndent: String = "") -> [String] {
          return ["\(nodeIndent)\(typename)"] +
                        children.enumerated()
                            .map { ($0 < children.count - 1, $1) }
                            .flatMap { $0 ? $1.treeLines("┣╸","┃ ") : $1.treeLines("┗╸","  ") }
                            .map { childIndent + $0 }
       }

    var description: String {
        return treeLines().joined(separator: "\n")
    }
}
