//
//  State.swift
//  NewtKit
//
//  Created by Luís Silva on 25/06/2018.
//  Copyright © 2018 Chipp'd. All rights reserved.
//

import Foundation

class DFUState {
    var stateMachine: DFUStateMachine!
    
    func didEnter() {}
    func willExit() {}
    func event(_ event: DFUStateMachineEvent) {}
}
