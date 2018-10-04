//
//  NewtService.swift
//  NewtKit
//
//  Created by Luís Silva on 12/02/2018.
//  Copyright © 2018 Chipp'd. All rights reserved.
//

import Foundation
import os

public protocol NewtServiceTransportDelegate: class {
	func newtService(_ newtService: NewtService, write data: Data)
}

public class NewtService: NSObject {
	public let operationQueue: OperationQueue
	public var timer: Timer?
	public var receivedData: Data!
    public var operationTimeout: TimeInterval = 15
    @objc public dynamic var isTransportConnected: Bool = false
	
	public weak var transport: NewtServiceTransportDelegate?
	
	public override init() {
		operationQueue = OperationQueue()
		operationQueue.maxConcurrentOperationCount = 1
		operationQueue.name = "NewtKit.NewtService"
        
        super.init()
	}
	
	public func clearQueue() {
        os_log("Queue cleared", log: NewtKitLog.general, type: .debug)
		(operationQueue.operations.first as? NewtOperation)?.finish()
		operationQueue.cancelAllOperations()
	}
	
	public func didReceive(data: Data) {
		guard let newtOperation = operationQueue.operations.first as? NewtOperation else {
            os_log("Warning, no operation in queue for didReceive(_)", log: NewtKitLog.general, type: .debug)
			return
		}
		
		if receivedData == nil {
			receivedData = Data()
		}
		receivedData.append(data)
		
		guard let packet = Packet(data: receivedData) else {
            os_log("Error parsing packet", log: NewtKitLog.general, type: .debug)
			return
		}
		
		if receivedData.count == packet.length + Packet.kHeaderSize {
			newtOperation.didReceive(packet: packet)
			receivedData = nil
		}
	}
    
    public func transportDidConnect() {
        self.isTransportConnected = true
        
        if let op = self.operationQueue.operations.first as? NewtOperation {
            op.transportDidConnect()
        }
    }
    
    public func transportDidDisconnect() {
        if let op = operationQueue.operations.first as? NewtOperation {
            op.transportDidDisconnect()
        }
        
        isTransportConnected = false
    }
	
	func willStartOperation(_ operation: NewtOperation) {
		
	}
	
	func didEndOperation(_ operation: NewtOperation) {
		
	}
    
    public func execute(operation: NewtOperation) {
        operation.newtService = self
        operationQueue.addOperation(operation)
    }
}
