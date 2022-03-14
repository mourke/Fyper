//
//  InitialNode.swift
//  Dynamic
//
//  Created by Mark Bourke on 01/03/2022.
//

import Foundation

class InitialNode: Node {
    var typename: String {
        initializer.typename
    }
    let initializer: InjectableInitializer
    
    var children: AnyCollection<Node> {
        AnyCollection(_children.map { $0 as! Node })
    }
    
    private var _children: Set<AnyHashable> = []
    weak private(set) var parent: Node? = nil
    
    let syntaxStructure: SyntaxStructure
    
    @discardableResult
    func addChild<C: Node & Hashable>(_ child: C) -> Bool {
        return _children.insert(child).inserted
    }
    
    init(initializer: InjectableInitializer, syntaxStructure: SyntaxStructure) {
        self.initializer = initializer
        self.syntaxStructure = syntaxStructure
    }
    
}

extension InitialNode: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(typename)
    }

    static func == (lhs: InitialNode, rhs: InitialNode) -> Bool {
        return lhs.typename == rhs.typename
    }
}
