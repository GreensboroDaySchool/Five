//
//  HexNode.swift
//  Hive Five
//
//  Created by Jiachen Ren on 3/27/18.
//  Copyright © 2018 Greensboro Day School. All rights reserved.
//

import Foundation

/**
 This is the parent of Hive, QueenBee, Beetle, Grasshopper, Spider, and SoldierAnt,
 since all of them are pieces that together consist a hexagonal board, a hexagonal node with
 references to all the neighbors is the ideal structure.
 */
public class HexNode: IdentityProtocol, Hashable {
    public var neighbors = Neighbors()
    public var color: Color = .black
    public var identity: Identity {
        get {return .dummy}
    }
    
    //Node: hashValue may not be the ObjectIdentifier of the node. In multi-player enviorment, its synced to the server's hashValue
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }
    
    /**
     Initializer must specify the color
     */
    public init(color: Color) {
        self.color = color
    }
    
    /**
     For initialization of a dummy node
     */
    public convenience init() {
        self.init(color: .black)
    }

    /**
     The implementation for this method should be different for each class that conforms to the HexNode protocol.
     For example, a beetle's route may cover a piece while a Queen's route may never overlap another piece.
     - Note: Empty implementation for HexNode because it is just a dummy.
     - Returns: All possible positions
     */
    public func _availableMoves() -> [Position] {
        return []
    }
    
    /**
     Sometimes two different positions represents the same physical position. The job of this
     method is to get rid of such duplicate positions.
     - Returns: An array containing physically non-repeating available destinations
     - Todo: Debug & test
     */
    final public func uniqueAvailableMoves() -> [Position] {
        // Check one-hive rule
        if (!canDisconnect()) {
            return []
        }
        let moves = _availableMoves()
        let paths = derivePaths()
        return moves.map {position in
                let route = paths.filter {$0.destination === position.node}[0].route
                return route.append([position.dir])
            }.filterDuplicates(isDuplicate: ==)
            .map {Position.resolve(from: self, following: $0)}
    }
    
    /**
     - Returns: Available moves within one step
     - Warning: This is a helper method for QueenBee::availableMoves, Beetle, and Spider, don't use it!
     */
    public func oneStepMoves() -> [Route] {
        return neighbors.present().filter{$0.dir.rawValue < 6} // only horizontal nodes
            .map{($0.dir, $0.node.neighbors
                .adjacent(of: $0.dir.opposite())
                .filter{$0.node == nil} // ensure that the spot is vacant
                .map{$0.dir})}
            .map{(arg) -> [Route] in let (dir, dirs) = arg; return {
                dirs.map{Route(directions: [dir, $0])} // ensure that the current node can squeeze in
                    .filter{canGetIn(dir: $0.simplified().directions[0])}
            }()}
            .flatMap{$0} // if two different routes lead to the same position, keep only one.
            .filterDuplicates(isDuplicate: ==)
    }
    
    /**
     Derive the Path to every HexNode in the hive
     - Returns: The paths leading to the rest of the pieces in the hive
     */
    public func derivePaths() -> [Path] {
        var paths = [Path(route: Route(directions: []), destination: self)]
        derivePaths(&paths, paths[0].route) // the root path is initially []
        paths.removeFirst()
        return paths
    }
    
    private func blockedDirections() -> [Direction] {
        return Direction.xyDirections.filter{neighbors[$0] != nil || !canGetIn(dir: $0)}
    }

    /**
     - Parameter paths: Derived paths
     - Parameter root: The root path
     - Returns: Paths to the rest of the nodes in the hive from the current node
     */
    private func derivePaths(_ paths: inout [Path], _ root: Route) {
        let available = neighbors.present().filter {
            pair in !paths.contains(where: { pair.node === $0.destination })
        }
        
        if available.count == 0 {return} // base case
        let newPaths = available.map{Path(route: root.append([$0.dir]), $0.node)}
        paths.append(contentsOf: newPaths)
        newPaths.forEach{$0.destination.derivePaths(&paths, $0.route)} // recursive call
    }

    /**
     - Returns: Whether the current node could move
     */
    public func canMove() -> Bool {
        return canDisconnect() && _availableMoves().count > 0
    }
    
    /**
     Checks if a certain movement is legal
     */
    public func canMove(to position: Position) -> Bool {
        if !canDisconnect() {return false}
        let availableMoves = self._availableMoves()
        let preserved = neighbors
        move(to: position)
        var canMove = false
        for move in availableMoves {
            let contains = neighbors.present()
                .map{(node: $0.node, dir: $0.dir.opposite())}
                .contains{Position(node: $0.node, dir: $0.dir) == move}
            if contains {
                canMove = true
                break
            }
        }
        disconnect() //restore the status of the hive
        self.neighbors = preserved
        return canMove
    }

    /**
     Checks if a certain piece could get move in a certain direction.
     For example, if we have a node 'a', and 'a' has 'b' and 'c' at .upperLeft, .upperRight respectively,
     Then the piece cannot move in the direction of .up; except when the piece is Beetle.
     Beetle should override this method to always return true.
     */
    public func canGetIn(dir: Direction) -> Bool {
        var canGetIn = false
        for node in neighbors.adjacent(of: dir).map({$0.node}) {
            canGetIn = canGetIn || node == nil
        }
        return canGetIn
    }

    /**
     Checks whether a piece can initially connect to the hive at the designated position
     */
    public func canPlace(at position: Position) -> Bool {
        if position.dir.rawValue >= 6 {return false}
        let node = position.node
        let dir = position.dir
        if node.neighbors[dir] != nil {return false}
        let dummy = Identity.dummy.new(color: color)
        dummy.move(to: position)
        let opponents = dummy.neighbors.present()
            .map{Hive.traverse(from: $0.node, toward: .top)}
            .filter{$0.color != color}
            .count
        dummy.disconnect()
        return opponents == 0
    }

    /**
     - Attention: This is for initially putting down a piece; does not recommend using like move(to:)
     - Note: Will first check if the placement is allowed/legal
     */
    public func place(at position: Position) {
        if !canPlace(at: position) {fatalError("Cannot place at \(position)")}
        if neighbors.present().count != 0 {fatalError("Still connected to the hive. Please disconnect first")}
        move(to: position)
    }
    
    /**
     The behavior is the same as place(at:), this is for convenient access
     - Parameter node: The destination node
     - Parameter dir: The direction in relation to the destination node in which the current piece is to be placed at
     */
    public func place(at dir: Direction, of node: HexNode) {
        place(at: Position(node: node, dir: dir))
    }

    /**
     Move the piece to the designated position and **properly** connect the piece with the hive,
     i.e., handles multi-directional reference bindings, unlike connect(with:) which only handles bidirectional binding
     - Warning: This method assumes that the position is a valid position and that the route taken is legal.
     Maybe a more intuitive description is that this method snaps a piece off the hive and squeeze it into the position
     - Attention: Use this method to MOVE the piece, not to initially PLACE a piece.
     */
    public func move(to position: Position) {
        self.disconnect() // disconnect from the hive
        let node = position.node
        let dir = position.dir
        connect(with: node, at: dir) // connect with position node
        inferAdditionalConnections(from: node, at: dir) // make additional connections
    }
    
    /**
     The behavior is the same as move(to:), this overloading method is for convenient access.
     - Parameter node: The destination node.
     - Parameter dir: The direction in relation to the destination node in which the current piece is moving to.
     */
    public func move(to dir: Direction, of node: HexNode) {
        move(to: Position(node: node, dir: dir))
    }
    
    private func inferAdditionalConnections(from node: HexNode, at dir: Direction) {
        let pairs = Direction.allDirections.filter{$0 != dir.opposite()}
            .map{(dir: $0, trans: $0.translation())}
        // directions in which additional connections might need to be made
        
        derivePaths().map {path -> Position? in //make additional connections to complete the hive
            let filtered = pairs.filter {path.route.translation == $0.trans}
            return filtered.count == 0 ? nil :
                Position(node: path.destination, dir: filtered[0].dir)
            }.filter{$0 != nil}
            .map{$0!}
            .forEach{$0.node.connect(with: self, at: $0.dir)}
    }

    /**
     Moves the piece by following a certain route
     (just for convenience, because route is eventually resolved to a position)
     */
    public func move(by route: Route) {
        move(to: Position.resolve(from: self, following: route))
    }

    /**
     - Returns: Whe number of nodes that are connected to the current node, including the current node
     */
    public func numConnected() -> Int {
        return connectedNodes().count
    }

    /**
     Connect bidirectionally with another node at a certain neighboring position.
     - Attention: Does not connect properly with the entire hive structure; only a bidirectional reference binding.
     - Parameter node: The node in which a bidirectional connection is to be established
     - Parameter dir: The direction in relation to the node to be connected with
     */
    public func connect(with node: HexNode, at dir: Direction) {
        assert(node.neighbors[dir] == nil)
        node.neighbors[dir] = self
        neighbors[dir.opposite()] = node
    }

    /**
     - Returns: Whether taking this node up will break the structure.
     */
    public func canDisconnect() -> Bool {
        if self.neighbors[.top] != nil {return false} // little fucking beetle...
        let neighbors = self.neighbors // make a copy of the neighbors
        let numConnected = self.numConnected() // the number of pieces that are currently connected.
        self.disconnect() // temporarily disconnect with all neighbors

        let available = neighbors.present() // extract all present neighbors
        let connected = available.map {$0.node.numConnected()}
        var canMove = true
        for i in (0..<connected.count) {
            // if number of connected pieces are not the same for each piece after the current
            // node is removed from the structure, then the structure is broken.
            if connected[i] != numConnected - 1 {
                canMove = false
                break
            }
        }

        available.forEach {connect(with: $0.node, at: $0.dir.opposite())} // reconnect with neighbors
        return canMove
    }

    /**
     When the node disconnects from the structure, all references to it from the neighbors should be removed.
     - Attention: Disconnect with all neighbors, i.e. remove from the hive
     */
    public func disconnect() {
        neighbors.present().map {$0.node}.forEach {$0.disconnect(with: self)}
    }

    /**
     Disconnect with the specified node
     - Attention: Disconnect ONLY with the specified node, does not disconnect with all the surrounding nodes
     - Parameter node: The node with which the bidirectional connection is to be broken
     */
    public func disconnect(with node: HexNode) {
        node.remove(self)
        assert(node.neighbors.contains(self) == nil) // make sure the reference is removed
        remove(node)
        assert(neighbors.contains(node) == nil)
    }

    /**
     - Parameter pool: References to HexNodes that are already accounted for
     - Returns: An integer representing the number of nodesincluding self
     */
    private func deriveConnectedNodes(_ pool: inout [HexNode]) -> Int {
        let pairs = neighbors.present() // neighbors that are present
        if pool.contains(where: { $0 === self }) {return 0}
        pool.append(self) // add self to pool of accounted node such that it won't get counted again
        return pairs.map {$0.node}.filter { node in !pool.contains(where: { $0 === node })}
                .map {$0.deriveConnectedNodes(&pool)}
                .reduce(1) {$0 + $1}
    }

    /**
     - Returns: An array containing all the references to the connected pieces, including self; i.e. the entire hive
     */
    public func connectedNodes() -> [HexNode] {
        var pool = [HexNode]()
        let _ = deriveConnectedNodes(&pool)
        return pool
    }

    /**
     Remove the reference to a specific node from its neighbors
     */
    public func remove(_ node: HexNode) {
        neighbors = neighbors.remove(node)
    }

    /**
     Returns self for convenient chained modification.
     - Parameter nodes: references to the nodes to be removed
     - Returns: self
     */
    public func removeAll(_ nodes: [HexNode]) -> HexNode {
        nodes.forEach(remove)
        return self
    }

    /**
     - Returns: Whether the node has [other] as an immediate neighbor
     */
    public func hasNeighbor(_ other: HexNode) -> Direction? {
        return neighbors.contains(other)
    }
    
    /**
     A newly instantiated HexNode that is identical to the current node.
     - Note: Does not include possibly invalid neighbor references.
     */
    public func clone() -> HexNode{
        return identity.new(color: color)
    }
    
    /**
     Make a copy of all of the nodes that are connected to root, i.e. the entire hive.
     This can be quite tricky...
     */
    public static func clone(root: HexNode) -> HexNode {
        let paths = root.derivePaths()
        let newRoot = root.clone()
        paths.forEach{(route, destination) in
            let newNode = destination.clone()
            newNode.neighbors = newRoot.neighbors // Put the new node at the position of the original node
            let dirs = route.directions
            if dirs.count == 1 { // Immediate neighbors of root are handled with caution
                newNode.move(to: dirs.first!, of: newRoot)
            } else {
                newNode.move(by: route)
            }
        }
        return newRoot
    }
    
    public static func == (lhs: HexNode, rhs: HexNode) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

public extension HexNode {
    func valueEquals(_ node: HexNode) -> Bool {
        return identity == node.identity && color == node.color
    }
}

/**
 Extend from Int for convenience during serialization
 */
public enum Color: Int, CustomStringConvertible, Codable {
    case black = 0, white
    
    public var opposite: Color {
        get {
            return (self == .black ? .white : .black)
        }
    }
    
    public var description: String {
        switch self {
        case .black: return "black"
        case .white: return "white"
        }
    }
}
