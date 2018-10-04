//
//  MPStat.swift
//  NewtKit
//
//  Created by Luís Silva on 17/03/2018.
//  Copyright © 2018 Chipp'd. All rights reserved.
//

import Foundation

public struct MPStat: Codable {
    public var name: String
    public var blksz: Int
    public var cnt: Int
    public var free: Int
    public var min: Int
}
