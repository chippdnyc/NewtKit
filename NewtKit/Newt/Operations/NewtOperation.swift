//
//  NewtOperation.swift
//  NewtKit
//
//  Created by Luís Silva on 12/02/2018.
//  Copyright © 2018 Chipp'd. All rights reserved.
//

import Foundation
import os

public class NewtOperation: Operation {
	
	private var _executing = false {
		willSet {
			willChangeValue(forKey: "isExecuting")
		}
		didSet {
			didChangeValue(forKey: "isExecuting")
		}
	}
	
	override public var isExecuting: Bool {
		return _executing
	}
	
	private var _finished = false {
		willSet {
			willChangeValue(forKey: "isFinished")
		}
		
		didSet {
			didChangeValue(forKey: "isFinished")
		}
	}
	
	override public var isFinished: Bool {
		return _finished
	}
	
	func executing(_ executing: Bool) {
		newtService?.willStartOperation(self)
		
		_executing = executing
	}
	
	func finish(_ finished: Bool) {
		_finished = finished
		
		newtService?.didEndOperation(self)
	}
	
	var packet: Packet!
	weak var newtService: NewtService?
    var finishOnDisconnect: Bool { return false }
	
	override init() {
		super.init()
	}
	
	override public func main() {
		guard !isCancelled else {
			finish(true)
			return
		}
		executing(true)
        
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + .seconds(15)) { [weak self] in
            guard let self = self, self.isExecuting && (!self.isFinished && !self.isCancelled) else { return }
            
            self.didTimeout()
        }
	}
	
	func sendPacket() {
		guard packet != nil else {
            os_log("error, no packet to send", log: NewtKitLog.general, type: .debug)
            return
        }
		
		let data = packet.serialized()
        
        guard let transport = newtService?.transport else { fatalError("transport not set") }
		transport.newtService(newtService!, write: data)
	}
	
	func didReceive(packet: Packet) { }
	func didTimeout() {
        os_log("Operation timeout", log: NewtKitLog.general, type: .debug)
        
        cancel()
        finish()
    }
    
    func transportDidConnect() {}
    func transportDidDisconnect() {}
	
	func responseCode(inCBOR: CBOR) -> ResponseCode? {
        if case let CBOR.unsignedInt(rc)? = inCBOR["rc"] {
            return ResponseCode(rawValue: Int(rc))
        }
		return nil
	}
	
	func finish() {
		executing(false)
		finish(true)
	}
}
