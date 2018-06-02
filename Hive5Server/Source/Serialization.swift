//
//  Serialization.swift
//  Hive5Server
//
//  Created by Xule Zhou on 6/2/18.
//

import Foundation
import Hive5Common

extension JSONDecoder: DecodingDecoder { }

fileprivate let sharedDecoder = JSONDecoder()
fileprivate let sharedEncoder = JSONEncoder()

extension HFTransportModel {
    func export() throws -> Data {
        return try sharedEncoder.encode(self)
    }
}

/**
 Construct HFTransportModel from encoded JSON strings.
 */
public func constructHFModel(from jsonString: String) throws -> HFTransportModel {
    guard let binaryMessage = jsonString.data(using: .utf8) else { throw HFCodingError.decodingError("Unable to convert String to Data") }
    let parsedJSONObject = try JSONSerialization.jsonObject(with: binaryMessage, options: .init(rawValue: 0))
    //Get the op code, and then we can use that to reconstruct the HFTransportModel
    guard let operationCode = (parsedJSONObject as? [String:Any])?["op"] as? String else { throw HFCodingError.decodingError("Unable to parse message operation code") }
    return try constructHFModel(binaryMessage, type: operationCode, with: sharedDecoder)
}
