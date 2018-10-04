//
//  ImageListOperation.swift
//  NewtKit
//
//  Created by Luís Silva on 12/02/2018.
//  Copyright © 2018 Chipp'd. All rights reserved.
//

import Foundation
import Result

public typealias ImageResultClosure = ((Result<(splitStatus: UInt64, images: [Image]), NewtError>) -> Void)

public class ImageListOperation: NewtOperation {
	
	private var resultClosure: ImageResultClosure?
	
	public init(result: ImageResultClosure?) {
		self.resultClosure = result

		super.init()
		
		self.packet = Packet(op: .read, flags: 0, length: 0, group: NMGRGroup.image, seq: 0, id: NMGRImagesCommand.state.rawValue, data: Data())
	}
	
	override public func main() {
		super.main()
        
        sendPacket()
	}
	
	override func didReceive(packet: Packet) {
		defer {
			executing(false)
			finish(true)
		}
		
		if let cbor = packet.cborFromData() {
			var images: [Image] = []
            
            if case let .unsignedInt(splitStatus)? = cbor["splitStatus"], case let CBOR.array(imagesCbor)? = cbor["images"] {
                for imageCbor in imagesCbor {
                    if  case let CBOR.unsignedInt(slot)? = imageCbor["slot"],
                        case let CBOR.utf8String(version)? = imageCbor["version"],
                        case let CBOR.boolean(confirmed)? = imageCbor["confirmed"],
                        case let CBOR.boolean(pending)? = imageCbor["pending"],
                        case let CBOR.boolean(active)? = imageCbor["active"],
                        case let CBOR.boolean(bootable)? = imageCbor["bootable"],
                        case let CBOR.byteString(hash)? = imageCbor["hash"] {
                        
                        let image = Image(slot: Int(slot), version: version, isConfirmed: confirmed, isPending: pending, isActive: active, isBootable: bootable, hash: Data(hash))
                        images.append(image)
                    }
                }
                resultClosure?(.success((splitStatus: splitStatus, images: images)))
            } else {
                resultClosure?(.failure(.parseError))
            }
		} else {
			resultClosure?(.failure(.invalidCbor))
		}
	}
}
