//
//  Image.swift
//  NewtKit
//
//  Created by Luís Silva on 13/02/2018.
//  Copyright © 2018 Chipp'd. All rights reserved.
//

import Foundation

public struct Image: Codable, CustomDebugStringConvertible {
	public var slot: Int
	public var version: String
	public var isConfirmed: Bool
	public var isPending: Bool
	public var isActive: Bool
	public var isBootable: Bool
	public var hash: Data
    
    public var debugDescription: String {
        return "Image(slot: \(slot), version: \(version), isConfirmed: \(isConfirmed), isPending: \(isPending), isActive: \(isActive), isBootable: \(isBootable), hash: \(hash.hexString))"
    }
}
