//
//  LogLevel.swift
//  NewtKit
//
//  Created by Luís Silva on 17/03/2018.
//  Copyright © 2018 Chipp'd. All rights reserved.
//

import Foundation

public enum LogLevel: Int, Codable, CustomStringConvertible {
    case debug = 0
    case info = 1
    case warn = 2
    case error = 3
    case critical = 4
    
    public var description: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warn: return "WARN"
        case .error: return "ERROR"
        case .critical: return "CRITICAL"
        }
    }
}
