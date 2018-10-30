//
//  Beetle.swift
//  Hive Five
//
//  Created by Jiachen Ren on 3/28/18.
//  Copyright © 2018 Greensboro Day School. All rights reserved.
//


import Foundation

public class Beetle: HexNode {
    
    override public var identity: Identity {
        return .beetle
    }
    
    
    
    override public func availableMoves() -> [Position] {
        var moves = [Position]()
        if (!canDisconnect()) {
            // if disconnecting the piece breaks the structure, then there are no available moves.
            return moves
        }
        
        let base = Hive.traverse(from: self, toward: .below)
        moves.append(contentsOf: base.neighbors.available()
            .filter{$0.dir.rawValue < 6}
            .map{getTopNode(of: $0.node)}
            .map{Position(node: $0, dir: .above)})
        let moreMoves = base === self ? oneStepMoves().map{Position.resolve(from: base, following: $0)} :
            Direction.xyDirections.map{(dir: $0, node: base.neighbors[$0])}
            .filter{$0.node == nil}
            .map{Position(node: base, dir: $0.dir)}
        moves.append(contentsOf: moreMoves)
        
        return moves
    }
    
    /**
     Beetle can get in anywhere! Yay beetle!
     */
    override public func canGetIn(dir: Direction) -> Bool {
        return true
    }
    
    /**
     - Returns: The node at the top of the stack
     */
    private func getTopNode(of base: HexNode) -> HexNode {
        return Hive.traverse(from: base, toward: .above)
    }
}