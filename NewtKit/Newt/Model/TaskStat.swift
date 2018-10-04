//
//  TaskStat.swift
//  NewtKit
//
//  Created by Luís Silva on 17/03/2018.
//  Copyright © 2018 Chipp'd. All rights reserved.
//

import Foundation

public struct TaskStat: Codable {
    public var taskId: UInt64
    public var name: String
    public var priority: UInt64
    public var state: UInt64
    public var runTime: UInt64
    public var contextSwichCount: UInt64
    public var stackSize: UInt64
    public var stackUsed: UInt64
    public var lastSanityCheckin: UInt64
    public var nextSanityCheckin: UInt64
}
