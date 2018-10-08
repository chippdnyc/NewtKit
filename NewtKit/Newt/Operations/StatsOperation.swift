//
//  StatsOperation.swift
//  NewtKit
//
//  Created by Luís Silva on 17/03/2018.
//  Copyright © 2018 Chipp'd. All rights reserved.
//

import Foundation
import Result

public typealias StatsResultClosure = ((Result<[Stat], NewtError>) -> Void)

public class StatsOperation: NewtOperation {
    
    private var resultClosure: StatsResultClosure?
    
    init(name: String, result: StatsResultClosure?) {
        self.resultClosure = result
        
        super.init()
        
        let cbor = CBOR(dictionaryLiteral: ("name", CBOR(stringLiteral: name)))
        let cborData = Data(cbor.encode())
        
        self.packet = Packet(op: .read, flags: 0, length: cborData.count, group: NMGRGroup.stats, seq: 0, id: NMGRStatsCommand.read.rawValue, data: cborData)
    }
    
    override public func main() {
        super.main()
        
        sendPacket()
    }
    
    override func didReceive(packet: Packet) {
        if let cbor = packet.cborFromData(), case let CBOR.map(statsDict)? = cbor["fields"] {
            let stats: [Stat] = statsDict.compactMap {
                if case let CBOR.utf8String(name) = $0.key, case let CBOR.unsignedInt(value) = $0.value {
                    return Stat(name: name, value: Int(value))
                }
                return nil
            }
            resultClosure?(.success(stats))
        } else {
            resultClosure?(.failure(.invalidCbor))
        }
        
        executing(false)
        finish(true)
    }
}
