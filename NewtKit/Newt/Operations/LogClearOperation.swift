//
//  LogClearOperation.swift
//  NewtKit
//
//  Created by Luís Silva on 17/03/2018.
//  Copyright © 2018 Chipp'd. All rights reserved.
//

import Foundation
import Result

public typealias LogClearResultClosure = ((Result<Void, NewtError>) -> Void)

public class LogClearOperation: NewtOperation {
    private var resultClosure: LogClearResultClosure?
    
    init(result: LogClearResultClosure?) {
        self.resultClosure = result
        
        super.init()
        
        self.packet = Packet(op: .write, flags: 0, length: 0, group: NMGRGroup.logs, seq: 0, id: NMGRLogsCommand.clear.rawValue, data: Data())
    }
    
    override public func main() {
        super.main()
        
        sendPacket()
    }
    
    override func didReceive(packet: Packet) {
        if let cbor = packet.cborFromData() {
            if let responseCode = responseCode(inCBOR: cbor) {
                if responseCode == .ok {
                    resultClosure?(.success(()))
                } else {
                    resultClosure?(.failure(responseCode))
                }
            }
        } else {
            resultClosure?(.failure(.invalidCbor))
        }
        
        executing(false)
        finish(true)
    }
}
