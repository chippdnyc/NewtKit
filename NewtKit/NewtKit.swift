//
//  NewtKit.swift
//  NewtKit
//
//  Created by Luís Silva on 02/07/2018.
//  Copyright © 2018 Chipp'd. All rights reserved.
//

import Foundation
import os

struct NewtKitLog {
    static let general = OSLog(subsystem: "NewtKit", category: "")
    static let dfu = OSLog(subsystem: "NewtKit.DFU", category: "")
}
