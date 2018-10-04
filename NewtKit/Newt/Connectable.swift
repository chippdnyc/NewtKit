//
//  Connectable.swift
//  NewtKit
//
//  Created by Luís Silva on 26/06/2018.
//  Copyright © 2018 Chipp'd. All rights reserved.
//

import Foundation

public protocol Connectable: AnyObject {
    var isConnected: Bool { get set } 
    var connectionStateChanged: ((_ isConnected: Bool) -> Void)? { get set }
    
    func connect(keepConnection: Bool)
    func disconnect(reconnect: Bool)
}
