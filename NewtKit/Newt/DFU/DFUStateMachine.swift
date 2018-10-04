//
//  DFUStateMachine.swift
//  NewtKit
//
//  Created by Luís Silva on 25/06/2018.
//  Copyright © 2018 Chipp'd. All rights reserved.
//

import Foundation

protocol DFUStateMachineDelegate: class {
    func stateMachine(_ stateMachine: DFUStateMachine, didExit state: DFUState, error: DFUError?)
}

class DFUStateMachine {
    weak var delegate: DFUStateMachineDelegate?
    var currentState: DFUState?
    
    func enterState(_ state: DFUState) {
        state.stateMachine = self
        currentState = state
        
        state.didEnter()
    }
    
    func exitState(_ state: DFUState, error: DFUError?) {
        state.willExit()
        currentState = nil
        
        delegate?.stateMachine(self, didExit: state, error: error)
    }
    
    func event(_ event: DFUStateMachineEvent) {
        currentState?.event(event)
    }
}

enum DFUStateMachineEvent {
    case connect
    case disconnect
}
