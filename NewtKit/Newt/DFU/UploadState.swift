//
//  UploadLoaderState.swift
//  NewtKit
//
//  Created by Luís Silva on 27/06/2018.
//  Copyright © 2018 Chipp'd. All rights reserved.
//

import Foundation
import os

class UploadLoaderState: UploadState { }
class UploadAppState: UploadState { }

protocol UploadStateDelegate: class {
    func uploadState(_ uploadState: UploadState, progress: Double)
}

class UploadState: DFUState {
    private var newtService: NewtService
    private var imageData: Data
    private var uploadProgress: Double = 0
    
    weak var delegate: UploadStateDelegate?
    
    init(newtService: NewtService, imageData: Data) {
        self.newtService = newtService
        self.imageData = imageData
        super.init()
    }
    
    override func didEnter() {
        let op = UploadOperation(data: imageData, progress: { [unowned self] (progress) -> Bool in
            os_log("Uploading %.1f", log: NewtKitLog.dfu, type: .debug, progress)
            
            self.delegate?.uploadState(self, progress: progress)
            return true
        }) { (result) in
            switch result {
            case .success(_):
                os_log("Upload success", log: NewtKitLog.dfu, type: .debug)
                self.stateMachine.exitState(self, error: nil)
                
            case .failure(let error):
                os_log("Upload failed %s", log: NewtKitLog.dfu, type: .debug, error.localizedDescription)
                self.stateMachine.exitState(self, error: .unknown(error.localizedDescription))
            }
        }
        newtService.execute(operation: op)
        
    }
    
    override func willExit() {}
    
    override func event(_ event: DFUStateMachineEvent) { }
}

