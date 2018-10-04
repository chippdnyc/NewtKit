//
//  LogShowOperation.swift
//  NewtKit
//
//  Created by Luís Silva on 17/03/2018.
//  Copyright © 2018 Chipp'd. All rights reserved.
//

import Foundation
import Result

public typealias LogShowResultClosure = ((Result<[LogEntry], NewtError>) -> Void)

class LogShowOperation: NewtOperation {
    private var resultClosure: LogShowResultClosure?
    
    init(logName: String = "", min: Int = 0, timestamp: Int = 0, result: LogShowResultClosure?) {
        self.resultClosure = result
        
        super.init()
        
        let cbor = CBOR(dictionaryLiteral: ("log_name", CBOR(stringLiteral: logName)), ("index", CBOR(integerLiteral: min)), ("ts", CBOR(integerLiteral: timestamp)))
        let cborData = Data(cbor.encode())
        
        self.packet = Packet(op: .read, flags: 0, length: cborData.count, group: NMGRGroup.logs, seq: 0, id: NMGRLogsCommand.read.rawValue, data: cborData)
    }
    
    override func main() {
        super.main()
        
        sendPacket()
    }
    
    override func didReceive(packet: Packet) {
        if let cbor = packet.cborFromData(), case let .array(logs)? = cbor["logs"] {
            var logEntries: [LogEntry] = []
            for log in logs {
                if case let .array(entries)? = log["entries"] {
                    for entry in entries {
                        if  case let .unsignedInt(index)? = entry["index"],
                            case let .unsignedInt(timestamp)? = entry["ts"],
                            case let .unsignedInt(module)? = entry["module"],
                            case let .unsignedInt(level)? = entry["level"],
                            case let .utf8String(msg)? = entry["msg"] {
                            
                            let logEntry = LogEntry(index: index, timestamp: timestamp, module: module, level: LogLevel(rawValue: Int(level)) ?? .info, message: msg)
                            logEntries.append(logEntry)
                        }
                    }
                }
            }
            resultClosure?(.success(logEntries))
        } else {
            resultClosure?(.failure(.invalidCbor))
        }
        
        executing(false)
        finish(true)
    }
}

