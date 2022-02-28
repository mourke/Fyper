//
//  Node.swift
//  Dynamic
//
//  Created by Mark Bourke on 28/02/2022.
//

import Foundation

class Node: Hashable, CustomStringConvertible {
    
    let typename: String
    private (set) var children: Set<Node> = []
    weak private(set) var parent: Node?
    
    init(parent: Node?, typename: String) {
        self.parent = parent
        self.typename = typename
    }
    
    @discardableResult
    func addChild(_ child: Node) -> Bool {
        return children.insert(child).inserted
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(typename)
    }
    
    static func == (lhs: Node, rhs: Node) -> Bool {
        return lhs.typename == rhs.typename
    }
    
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
