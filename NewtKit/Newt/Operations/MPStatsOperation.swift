//
//  MPStatsOperation.swift
//  NewtKit
//
//  Created by Luís Silva on 17/03/2018.
//  Copyright © 2018 Chipp'd. All rights reserved.
//

import Foundation
import Result

public typealias MPStatsResultClosure = ((Result<[MPStat], NewtError>) -> Void)

public class MPStatsOperation: NewtOperation {
    
    private var resultClosure: MPStatsResultClosure?
    
    init(result: MPStatsResultClosure?) {
        self.resultClosure = result
        
        super.init()
        
        self.packet = Packet(op: .read, flags: 0, length: 0, group: NMGRGroup.default, seq: 0, id: NMGRCommand.mpStats.rawValue, data: Data())
    }
    
    override public func main() {
        super.main()
        
        sendPacket()
    }
    
    override func didReceive(packet: Packet) {
        if let cbor = packet.cborFromData(), case let CBOR.map(mpStatsDict)? = cbor["mpools"] {
                let mpStats: [MPStat] = mpStatsDict.compactMap {
                    let key = $0.key
                    let value = $0.value
                    
                    if  case let CBOR.utf8String(name) = key,
                        case let CBOR.unsignedInt(blksz)? = value["blksiz"],
                        case let CBOR.unsignedInt(cnt)? = value["nblks"],
                        case let CBOR.unsignedInt(min)? = value["min"],
                        case let CBOR.unsignedInt(free)? = value["nfree"] {
                        
                        return MPStat(name: name, blksz: Int(blksz), cnt: Int(cnt), free: Int(free), min: Int(min))
                    }
                    return nil
                }
            resultClosure?(.success(mpStats))
        } else {
            resultClosure?(.failure(.parseError))
        }
        
        executing(false)
        finish(true)
    }
}
