//
//  Constants.swift
//  NewtKit
//
//  Created by Luís Silva on 11/02/2018.
//  Copyright © 2018 Chipp'd. All rights reserved.
//

import Foundation

enum NMGROperation: UInt8 {
	case read = 0 
	case readRsp = 1
	case write = 2
	case writeRsp = 3
}

enum NMGRGroup: UInt16 {
	case `default` = 0
	case image = 1
	case stats = 2
	case config = 3
	case logs = 4
	case crash = 5
	case split = 6
	case run = 7
	case fs = 8
	case perUser = 64
}

enum NMGRCommand: UInt8 {
	case echo = 0
	case consEchoCtrl = 1
	case taskStats = 2
	case mpStats = 3
	case datetimeStr = 4
	case reset = 5
}

enum NMGRLogsCommand: UInt8 {
	case read = 0
	case clear = 1
	case append = 2
	case moduleList = 3
	case levelList = 4
	case logsList = 5
}

enum NMGRStatsCommand: UInt8 {
	case read = 0
	case list = 1
}

enum NMGRImagesCommand: UInt8 {
	case state = 0
	case upload = 1
	case coreList = 3
	case coreLoad = 4
	case erase = 5
}

public enum ResponseCode: Int, Error {
	case ok = 0
	case unknown = 1
	case noMemory = 2
	case invalid = 3
	case timeout = 4
	case noEnt = 5
	case badState = 6
	case perUser = 256
	
    // From app
	case invalidCbor = 1000
	case parseError = 1001
}

public typealias NewtError = ResponseCode




