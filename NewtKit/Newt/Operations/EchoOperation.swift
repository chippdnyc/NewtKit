//
//  EchoOperation.swift
//  NewtKit
//
//  Created by Luís Silva on 17/03/2018.
//  Copyright © 2018 Chipp'd. All rights reserved.
//

import Foundation
import Result

public typealias EchoResultClosure = ((Result<String, NewtError>) -> Void)

public class EchoOperation: NewtOperation {
    
    private var resultClosure: EchoResultClosure?
    
    public init(string: String, result: EchoResultClosure?) {
        self.resultClosure = result
        
        super.init()
        
        let cbor = CBOR(dictionaryLiteral: ("d", CBOR(stringLiteral: string)))
        let cborData = Data(cbor.encode())
        
        self.packet = Packet(op: .write, flags: 0, length: cborData.count, group: NMGRGroup.default, seq: 0, id: NMGRCommand.echo.rawValue, data: cborData)
    }
    
    override public func main() {
        super.main()
        
        sendPacket()
    }
    
    override func didReceive(packet: Packet) {
        dump(packet.cborFromData())
        if let cbor = packet.cborFromData(), case let CBOR.map(respDict) = cbor, case let CBOR.utf8String(string)? = respDict["r"] {
            resultClosure?(.success(string))
        } else {
            resultClosure?(.failure(.invalidCbor))
        }
        
        executing(false)
        finish(true)
    }
}
