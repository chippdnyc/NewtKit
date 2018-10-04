//
//  TaskStatsOperation.swift
//  NewtKit
//
//  Created by Luís Silva on 17/03/2018.
//  Copyright © 2018 Chipp'd. All rights reserved.
//

import Foundation
import Result

public typealias TastStatsResultClosure = ((Result<[TaskStat], NewtError>) -> Void)

class TaskStatsOperation: NewtOperation {
    
    private var resultClosure: TastStatsResultClosure?
    
    init(result: TastStatsResultClosure?) {
        self.resultClosure = result
        
        super.init()
        
        self.packet = Packet(op: .read, flags: 0, length: 0, group: NMGRGroup.default, seq: 0, id: NMGRCommand.taskStats.rawValue, data: Data())
    }
    
    override func main() {
        super.main()
        
        sendPacket()
    }
    
    override func didReceive(packet: Packet) {
//        if let cbor = packet.cborFromData(), let taskStatsDict = cbor["tasks"]?.dictionaryValue {
//            let taskStats: [TaskStat] = taskStatsDict.compactMap {
//                let key = $0.key
//                let value = $0.value
//
//                if  let name = key.string,
//                    let state = value["state"]?.uIntValue,
//                    let runTime = value["runtime"]?.uIntValue,
//                    let priority = value["prio"]?.uIntValue,
//                    let taskId = value["tid"]?.uIntValue,
//                    let contextSwichCount = value["cswcnt"]?.uIntValue,
//                    let stackUsed = value["stkuse"]?.uIntValue,
//                    let stackSize = value["stksiz"]?.uIntValue,
//                    let lastSanityCheckin = value["last_checkin"]?.uIntValue,
//                    let nextSanityCheckin = value["next_checkin"]?.uIntValue {
//
//                    return TaskStat(taskId: taskId, name: name, priority: priority, state: state, runTime: runTime, contextSwichCount: contextSwichCount, stackSize: stackSize, stackUsed: stackUsed, lastSanityCheckin: lastSanityCheckin, nextSanityCheckin: nextSanityCheckin)
//
//                }
//                return nil
//            }
//            resultClosure?(.success(taskStats))
//        } else {
//            resultClosure?(.failure(.parseError))
//        }

        if let cbor = packet.cborFromData(), case let CBOR.map(taskStatsDict)? = cbor["tasks"] {
            let taskStats: [TaskStat] = taskStatsDict.compactMap {
                let key = $0.key
                let value = $0.value
                
                if  case let CBOR.utf8String(name) = key,
                    case let CBOR.unsignedInt(state)? = value["state"],
                    case let CBOR.unsignedInt(runTime)? = value["runtime"],
                    case let CBOR.unsignedInt(priority)? = value["prio"],
                    case let CBOR.unsignedInt(taskId)? = value["tid"],
                    case let CBOR.unsignedInt(contextSwichCount)? = value["cswcnt"],
                    case let CBOR.unsignedInt(stackUsed)? = value["stkuse"],
                    case let CBOR.unsignedInt(stackSize)? = value["stksiz"],
                    case let CBOR.unsignedInt(lastSanityCheckin)? = value["last_checkin"],
                    case let CBOR.unsignedInt(nextSanityCheckin)? = value["next_checkin"] {
                    
                    return TaskStat(taskId: taskId, name: name, priority: priority, state: state, runTime: runTime, contextSwichCount: contextSwichCount, stackSize: stackSize, stackUsed: stackUsed, lastSanityCheckin: lastSanityCheckin, nextSanityCheckin: nextSanityCheckin)
                    
                }
                return nil
            }
            resultClosure?(.success(taskStats))
        } else {
            resultClosure?(.failure(.parseError))
        }
        
        executing(false)
        finish(true)
    }
}

