//
//  DFUStrategy.swift
//  NewtKit
//
//  Created by Luís Silva on 28/06/2018.
//  Copyright © 2018 Chipp'd. All rights reserved.
//

import Foundation
import os

let NewtKitDFULog = OSLog(subsystem: "NewtKit.DFU", category: "")

public protocol DFUStrategyDelegate: class {
    func dfuStrategy(_ dfuStrategy: DFUStrategy, progress: Double)
    func dfuStrategy(_ dfuStrategy: DFUStrategy, didFinishWithError error: DFUError?)
}

public protocol DFUStrategy {
    var delegate: DFUStrategyDelegate? { get set }
    var newtService: NewtService { get }
    
    func start()
    func cancel()
}

public enum DFUError: Error, CustomStringConvertible {
    case unknown(String)
    case timeout
    
    public var description: String {
        switch self {
        case let .unknown(description):
            return "Unknown - \(description)"
        case .timeout:
            return "Timeout"
        }
    }
}
