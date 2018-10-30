//
//  Spider.swift
//  Hive Five
//
//  Created by Jiachen Ren on 3/28/18.
//  Copyright © 2018 Greensboro Day School. All rights reserved.
//

import Foundation

public class Spider: HexNode {
    override public var identity: Identity {
        return .spider
    }
    
    private let allowedMoves = 3
    
    override public func availableMoves() -> [Position] {
        if (!canDisconnect()) {
            // if disconnecting the piece breaks the structure, then there are no available moves.
            return [Position]()
        }
        
        // can't go back to previous location
        var traversed = [Position]()
        let destinations = resolvePositions(&traversed, allowedMoves)
        
        return destinations
    }
    
    private func resolvePositions(_ traversed: inout [Position], _ remaining: Int) -> [Position] {
        registerTraversed(&traversed, self)
        let firstRoutes = oneStepMoves()
        let firstPositions = firstRoutes.map{Position.resolve(from: self, following: $0)}
        if remaining == 0 { // base case
            let location = neighbors.available()[0]
            return [Position(node: location.node, dir: location.dir.opposite())]
        }
        return firstPositions.filter{!traversed.contains($0)} // cannot go back to previous location
            .map{position -> [Position] in
                let neighbor = neighbors.available()[0]
                let anchor = Position(node: neighbor.node, dir: neighbor.dir.opposite())
                self.move(to: position) // move to next destination
                let positions = resolvePositions(&traversed, remaining - 1) // derive next step
                self.move(to: anchor) // move back to previous location
                return positions
            }.flatMap{$0}
    }
    
    private func registerTraversed(_ traversed: inout [Position], _ node: HexNode) {
        traversed.append(contentsOf: node.neighbors.available()
            .map{Position(node: $0.node, dir: $0.dir.opposite())})
    }
}
