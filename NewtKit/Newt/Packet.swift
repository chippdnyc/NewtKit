//
//  Packet.swift
//  NewtKit
//
//  Created by Luís Silva on 11/02/2018.
//  Copyright © 2018 Chipp'd. All rights reserved.
//

import Foundation
import os

struct Packet {
	static let kHeaderSize = 8
	
	let op: NMGROperation
	let flags: UInt8
	let length: Int
	let group: NMGRGroup
	let seq: UInt8
	let id: UInt8
	
	var data: Data?
	
	init(op: NMGROperation, flags: UInt8, length: Int, group: NMGRGroup, seq: UInt8, id: UInt8, data: Data) {
		self.op = op
		self.flags = flags
		self.length = length
		self.group = group
		self.seq = seq
		self.id = id
		
		self.data = data
	}

	init?(data: Data) {
		guard 8 <= data.count else { return nil }
		
		let bytes: [UInt8] = Array<UInt8>(data)
		
		guard let op = NMGROperation(rawValue: bytes[0]) else { return nil }
		guard let group = NMGRGroup(rawValue: (UInt16(bytes[4]) << 8) | UInt16(bytes[5])) else { return nil }
		
		self.op 	= op
		self.flags 	= bytes[1]
		self.length = Int((UInt16(bytes[2]) << 8) | UInt16(bytes[3]))
		self.group 	= group
		self.seq 	= bytes[6]
		self.id 	= bytes[7]
		
		let size = min(Packet.kHeaderSize + self.length, data.count)
		if Packet.kHeaderSize < size {
			self.data = data.subdata(in: Packet.kHeaderSize..<size)
		}
	}
	
	func serialized() -> Data {
		
		var buffer: [UInt8] = []
		
		buffer.append(op.rawValue)
		buffer.append(flags)
		buffer.append(UInt8(UInt16(length) >> 8))
		buffer.append(UInt8(UInt16(length) & 0xFF))
		buffer.append(UInt8(group.rawValue >> 8))
		buffer.append(UInt8(group.rawValue & 0xFF))
		buffer.append(seq)
		buffer.append(id)
		
		var mutableData = Data(bytes: buffer)
		if let data = self.data {
			mutableData.append(data)
		}
		
        os_log("Packet serialization: %@", log: NewtKitLog.general, type: .debug, mutableData.fullHexString)
		
		return mutableData
	}
	
	func cborFromData() -> CBOR? {
		if let data = data, let cbor_ = try? CBOR.decode(Array<UInt8>(data)), let cbor = cbor_ {
			return cbor
		}
		return nil
	}
}
