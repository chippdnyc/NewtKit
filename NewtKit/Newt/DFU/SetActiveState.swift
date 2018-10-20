//
//  SetActiveState.swift
//  NewtKit
//
//  Created by Luís Silva on 27/06/2018.
//  Copyright © 2018 Chipp'd. All rights reserved.
//

import Foundation
import os

class DeactivateAppState: SetActiveState { }
class SetNewLoaderActiveState: SetActiveState { }
class SetNewAppActiveState: SetActiveState { }

class SetActiveState: DFUState {
    private var newtService: NewtService
    private var activeImageHash: Data
    
    init(newtService: NewtService, active imageHash: Data) {
        self.newtService = newtService
        self.activeImageHash = imageHash
        super.init()
    }
    
    override func didEnter() {
        let op = TestOperation(hash: activeImageHash, result: { [unowned self] (result) in
            switch result {
            case .success(_):
                os_log("SetActiveState: test %s success", log: NewtKitLog.dfu, type: .debug, self.activeImageHash.hexString)
                
                let op = ResetOperation { [unowned self] (result) in
                    switch result {
                    case .success(_):
                        os_log("SetActiveState: reset success", log: NewtKitLog.dfu, type: .debug)
                        
                    case .failure(let error):
                        os_log("SetActiveState: reset failed", log: NewtKitLog.dfu, type: .debug)
                        
                        self.stateMachine.exitState(self, error: .unknown(error.localizedDescription))
                    }
                }
                self.newtService.execute(operation: op)
                
            case .failure(let error):
                os_log("SetActiveState %s failed: %s", log: NewtKitLog.dfu, type: .debug, self.activeImageHash.hexString, error.localizedDescription)
                
                self.stateMachine.exitState(self, error: .unknown(error.localizedDescription))
            }
        })
        
        self.newtService.execute(operation: op)
    }
    
    override func willExit() {}
    
    override func event(_ event: DFUStateMachineEvent) {
        if event == .connect {
            let op = ConfirmOperation { [unowned self] (result) in
                switch result {
                case .success(_):
                    os_log("SetActiveState: confirm success", log: NewtKitLog.dfu, type: .debug)
                    
                    self.stateMachine.exitState(self, error: nil)
                    
                case .failure(let error):
                    os_log("SetActiveState: confirm failed %s", log: NewtKitLog.dfu, type: .debug, error.localizedDescription)
                    self.stateMachine.exitState(self, error: .unknown(error.localizedDescription))
                }
            }
            
            self.newtService.execute(operation: op)
        }
    }
}

