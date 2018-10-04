//
//  EraseImageState.swift
//  NewtKit
//
//  Created by Luís Silva on 27/06/2018.
//  Copyright © 2018 Chipp'd. All rights reserved.
//

import Foundation
import os

class EraseOldAppImageState: EraseImageState { }
class EraseOldLoaderImageState: EraseImageState { }

class EraseImageState: DFUState {
    private var newtService: NewtService
    private var imageHash: Data
    
    init(newtService: NewtService, image imageHash: Data) {
        self.newtService = newtService
        self.imageHash = imageHash
        super.init()
    }
    
    override func didEnter() {
        let op = EraseOperation { [unowned self]  (result) in
            switch result {
            case .success(_):
                os_log("Erase %@ success", log: NewtKitLog.dfu, type: .debug, self.imageHash.hexString)
                self.stateMachine.exitState(self, error: nil)
            case .failure(let error):
                os_log("Erase %@ failed", log: NewtKitLog.dfu, type: .debug, self.imageHash.hexString)
                self.stateMachine.exitState(self, error: .unknown(error.localizedDescription))
            }
        }
        newtService.execute(operation: op)
    }
    
    override func willExit() {}
    
    override func event(_ event: DFUStateMachineEvent) {
        if event == .connect {
            self.stateMachine.exitState(self, error: nil)
        }
    }
}
