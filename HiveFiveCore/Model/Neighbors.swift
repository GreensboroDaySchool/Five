/**
 *
 *  This file is part of Hive Five.
 *
 *  Hive Five is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Hive Five is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Hive Five.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import Foundation

public struct Neighbors: Equatable, Hashable {
    var nodes = [HexNode?](repeating: nil, count: Direction.allDirections.count)

    public subscript(dir: Direction) -> HexNode? {
        get {return nodes[dir.rawValue]}
        set {nodes[dir.rawValue] = newValue}
    }

    /**
     - Returns: The direction & node tuples in which there is a neighbor present.
     */
    public func present() -> [(dir: Direction, node: HexNode)] {
        return nodes.enumerated().filter {$0.element != nil}
                .map {Direction(rawValue: $0.offset)!}
                .map {($0, self[$0]!)}
    }
    
    /**
     - Returns: The directions at which there is no neighbors.
     */
    public func empty() -> [Direction] {
        return nodes.enumerated()
            .filter{$0.element == nil}
            .map{Direction(rawValue: $0.offset)!}
    }

    /**
    e.g. adjacent(of: .down) produces [(.lowerRight, node at self[.lowerRight), (.lowerLeft, node at self[.lowerLeft)])]
     - Returns: the adjacent localized node of the specified direction
     */
    public func adjacent(of dir: Direction) -> [(dir: Direction, node: HexNode?)] {
        return dir.adjacent().map {($0, self[$0])}
    }

    /**
     - Parameter node: The node to be removed
     - Returns: A new instance with the specified node removed
     */
    public func remove(_ node: HexNode) -> Neighbors {
        var copied = self
        guard let index = nodes.firstIndex(where: { $0 === node }) else {
            return copied
        }
        copied.nodes[index] = nil
        return copied
    }

    public func removeAll(_ nodes: [HexNode]) -> Neighbors {
        var copied = self
        for node in nodes {
            copied = copied.remove(node) // not very efficient, but suffice for now!
        }
        return copied
    }

    /**
     - Returns: Whether the references to each nodes of [self] is the same as that of [other]
     */
    public func equals(_ other: Neighbors) -> Bool {
        return zip(nodes, other.nodes).reduce(true) {
            $0 && ($1.0 === $1.1)
        }
    }

    /**
     Whether [nodes] contains reference to [node]
     - Returns: Nil if node is not in [nodes]; returns the Direction otherwise.
    */
    public func contains(_ node: HexNode) -> Direction? {
        return nodes.enumerated().reduce(nil) {
            $1.element === node ? Direction(rawValue: $1.offset) : $0
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        //djb2a over all the object identifiers
        hasher.combine(nodes.reduce(5381) {
            var hash = 0
            if let node = $1 { hash = ObjectIdentifier(node).hashValue }
            return (($0 << 5) &+ $0) ^ (hash)
        })
    }
    
    public static func ==(l: Neighbors, r: Neighbors) -> Bool {
        return l.equals(r)
    }
}
