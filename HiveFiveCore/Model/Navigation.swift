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

/**
       _____(up)_____
      /              \
  (upperLeft)         (upperRight)
    /     Oh Yeah!     \
    \      Hive        /
 (lowerLeft)       (lowerRight)
      \____(down)____/
 */
public enum Direction: Int {
    
    public static let allDirections: [Direction] = (0..<8).map {
        Direction(rawValue: $0)!
    }
    public static let xyDirections: [Direction] = Direction.allDirections.filter{$0.rawValue < 6}
    
    public var is2D: Bool {return rawValue < 6}
    
    //Horizontal locations
    case up = 0, upperRight, lowerRight, down, lowerLeft, upperLeft

    //Vertical locations, the top node is always connected to the others (with a below pointed to the node below)
    //The node being suppressed should have all horizontal references set to nil
    case bottom, top

    /**
     I know there's a better way, but that would simply take too much time!
     - Returns: The opposite direction.
     */
    public func opposite() -> Direction {
        switch self {
        case .bottom: return .top
        case .top: return .bottom
        default: return Direction(rawValue: (self.rawValue + 3) % 6)!
        }
    }

    public func horizontalFlip() -> Direction {
        switch self {
        case .upperRight: return .upperLeft
        case .upperLeft: return .upperRight
        case .lowerLeft: return .lowerRight
        case .lowerRight: return .lowerLeft
        default: fatalError("horizontalFlip() only applies to slanted directions")
        }
    }

    /**
     e.g. Direction.up.adjacent() returns [.upperLeft, .upperRight]
     - Attention: This method is not intended for down/bottom.
     - Return: The adjacent directions of a certain direction
     use adjacent()[0] to get the next element counter-clockwise,
     use adjacent()[1] to get the next element clockwise
     */
    public func adjacent() -> [Direction] {
        assert(self.rawValue < 6) // this method is only intended for horizontal directions
        var adjacent = [Direction]()
        let count = 6 // there are 6 horizontal directions in total
        let value = rawValue + count
        adjacent.append(Direction(rawValue: (value - 1) % count)!)
        adjacent.append(Direction(rawValue: (value + 1) % count)!)
        return adjacent
    }
    
    /**
     - Returns: 3D translation that results when the direction is applied
     */
    public func translation() -> Translation {
        switch self {
        case .up: return Translation(x: 0, y: 2, z: 0)
        case .upperRight: return Translation(x: 1, y: 1, z: 0)
        case .lowerRight: return Translation(x: 1, y: -1, z: 0)
        case .down: return Translation(x: 0, y: -2, z: 0)
        case .lowerLeft: return Translation(x: -1, y: -1, z: 0)
        case .upperLeft: return Translation(x: -1, y: 1, z: 0)
        case .bottom: return Translation(x: 0, y: 0, z: -1)
        case .top: return Translation(x: 0, y: 0, z: 1)
        }
    }
}

/**
 Since everything is relative, there is no absolute location like in a x,y coordinate, only relative positions defined by Route;
 Route defines where the location is by providing step-wise directions. If Direction is a vector, then Route is an array
 of vectors that "directs" to the relative location.
 */
public struct Route: Equatable {
    public var directions: [Direction]
    public var translation: Translation {
        get {return directions.map{$0.translation()}
            .reduce(Translation(x: 0, y: 0, z: 0)){$0+$1}
        }
    }
    
    public init(directions: [Direction]){
        self.directions = directions
    }
    
    /**
     Convert quantitative translation to physical relative location based on the given node radius
     - Parameter radius: The radius of each node
     - Returns: Position relative to root
     */
    public func relativeCoordinate(radius: Float) -> Vec2D {
        let translation = self.translation
        let x = Float(translation.x) * radius * 1.5
        let y = Float(translation.y) * radius * sin(.pi / 3)
        return Vec2D(x: x, y: y)
    }

    public func append(_ directions: [Direction]) -> Route {
        var newDirs = self.directions
        newDirs.append(contentsOf: directions)
        return Route(directions: newDirs)
    }
    
    /**
     For core data serialization
     Encodes the current instance into an array of ints that represent the raw values of the directions.
     */
    public func encode() -> [Int] {
        return directions.map{$0.rawValue}
    }
    
    /**
     For core data serialization
     Decodes an int array and constructs a route
     */
    public static func decode(_ arr: [Int]) -> Route {
        return Route(directions: arr.map{Direction(rawValue: $0)!})
    }

    /**
     - Attention: The simplified route might no longer be valid! The purpose is to compare
     if two relative positions are the same.
     - Returns: The simplified route that leads to the exact same spot in less steps
     */
    public func simplified() -> Route {
        // 0 = up, 1 = upperRight, 2 = lowerRight, 3 = down, 4 = lowerLeft, 5 = upperLeft, bottom, top
        var dirs = [Int](repeating: 0, count: 8)
        directions.forEach{dirs[$0.rawValue] += 1}
        
        for i in (0..<3) { // cancel vertically and diagonally
            while (dirs[i] > 0 && dirs[i+3] > 0) {
                dirs[i] -= 1
                dirs[i+3] -= 1
            }
        }

        //upperLeft + upperRight = up, lowerLeft + lowerRight = down, etc
        while (dirs[1] > 0 && dirs[5] > 0) {
            dirs[1] -= 1 // - upperRight
            dirs[5] -= 1 // - upperLeft
            dirs[0] += 1 // + up
        }

        while (dirs[2] > 0 && dirs[4] > 0) {
            dirs[2] -= 1 // - lowerRight
            dirs[4] -= 1 // - lowerLeft
            dirs[3] += 1 // + down
        }

        while (dirs[0] > 0 && dirs[2] > 0) {
            dirs[0] -= 1 // - up
            dirs[2] -= 1 // - lowerRight
            dirs[1] += 1 // + upperRight
        }

        while (dirs[0] > 0 && dirs[4] > 0) {
            dirs[0] -= 1 // - up
            dirs[4] -= 1 // - lowerLeft
            dirs[5] += 1 // + upperLeft
        }

        while (dirs[1] > 0 && dirs[3] > 0) {
            dirs[1] -= 1 // - upperRight
            dirs[3] -= 1 // - down
            dirs[2] += 1 // + lowerRight
        }

        while (dirs[5] > 0 && dirs[3] > 0) {
            dirs[5] -= 1 // - upperLeft
            dirs[3] -= 1 // - down
            dirs[4] += 1 // + lowerLeft
        }

        //reconstruct directions
        let newDirs = dirs.enumerated().map{(index, element) -> [Direction] in
            return element == 0 ? [Direction]() : (0..<element)
                    .map{_ in Direction(rawValue: index)!
            }}.flatMap{$0}

        return Route(directions: newDirs)
    }

    /**
     - Returns: Whether the relative position represented by the two routes are equal
     - Warning: Don't use this to compare if the two routes are comprised of the same directions
     */
    public static func ==(lhs: Route, rhs: Route) -> Bool {
        return lhs.translation == rhs.translation
    }
}

/**
 Position defines the position that a piece would eventually arrive by following a given route.
 */
public struct Position: Equatable {
    public var node: HexNode // b/c the "one hive policy", the position has to be the vacant locations around a node
    public var dir: Direction // the direction of the vacant location

    /**
     Resolve the position by following a given Route.
     - Parameter start: The starting node of the route
     - Parameter route: The route to be followed to get to the position
     - Returns: The resolved position
     */
    public static func resolve(from start: HexNode, following route: Route) -> Position {
        //        let nodes = start.connectedNodes() // this can be optimized -- only resolve the hive structure when pieces are moved/added
        var current = start;
        for q in 0..<(route.directions.count - 1) {
            let direction = route.directions[q]
            current = current.neighbors[direction]!
        }
        return Position(node: current, dir: route.directions.last!)
    }
    
    public static func ==(lhs: Position, rhs: Position) -> Bool {
        return lhs.node === rhs.node && lhs.dir == rhs.dir
    }
}



/**
 The difference between Path and Route is:
 1) Route needs to be resolved to get to a certain destination/location
 2) The destination of Path is known beforehand
 */
public typealias Path = (route: Route, destination: HexNode)

/**
 z: vertical displacement
 Arbitrary Cartesian coordinate that is converted from a given Direction
 */
public typealias Translation = (x: Int, y: Int, z: Int)

public func +(lhs: Translation, rhs: Translation) -> Translation {
    return Translation(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
}

public func &=(lhs: Translation, rhs: Translation) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y
}
