//
//  LogModuleListOperation.swift
//  NewtKit
//
//  Created by Luís Silva on 17/03/2018.
//  Copyright © 2018 Chipp'd. All rights reserved.
//

import Foundation
import Result

public typealias LogModuleListResultClosure = ((Result<[LogModule], NewtError>) -> Void)

public class LogModuleListOperation: NewtOperation {
    private var resultClosure: LogModuleListResultClosure?
    
    init(result: LogModuleListResultClosure?) {
        self.resultClosure = result
        
        super.init()
        
        self.packet = Packet(op: .read, flags: 0, length: 0, group: NMGRGroup.logs, seq: 0, id: NMGRLogsCommand.moduleList.rawValue, data: Data())
    }
    
    override public func main() {
        super.main()
        
        sendPacket()
    }
    
    override func didReceive(packet: Packet) {
//        if let cbor = packet.cborFromData(), let modulesDict = cbor["module_map"]?.dictionaryValue {
//            let modules: [LogModule] = modulesDict.compactMap {
//                guard let id = $0.value.int, let name = $0.key.string else { return nil }
//                return LogModule(id: id, name: name)
//            }
//            resultClosure?(.success(modules))
//        } else {
//            resultClosure?(.failure(.invalidCbor))
//        }
        
        if let cbor = packet.cborFromData(), case let CBOR.map(modulesDict)? = cbor["module_map"] {
            let modules: [LogModule] = modulesDict.compactMap {
                if case let CBOR.unsignedInt(id) = $0.value, case let CBOR.utf8String(name) = $0.key {
                    return LogModule(id: Int(id), name: name)
                }
                return nil
            }
            resultClosure?(.success(modules))
        } else {
            resultClosure?(.failure(.invalidCbor))
        }
        
        executing(false)
        finish(true)
    }
}

