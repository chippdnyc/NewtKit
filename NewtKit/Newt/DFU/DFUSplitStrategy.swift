//
//  DFUSplitStrategy.swift
//  NewtKit
//
//  Created by Luís Silva on 25/06/2018.
//  Copyright © 2018 Chipp'd. All rights reserved.
//

import Foundation
import os

public class DFUSplitStrategy: DFUStrategy {
    enum State {
        case getStatus
        case appNotActive
        case appActiveNotConfirmed
        case appActive
        
        case eraseOldApp
        case waitConnectAfterEraseOldApp
        
        case uploadNewLoader
        case activateNewLoader
        case waitConnectAfterActivateNewLoader
        case confirmNewLoader
        case eraseOldLoader
        
        case waitConnectAfterEraseOldLoader
        case uploadNewApp
        case activateNewApp
        case waitConnectAfterActivateNewApp
        case confirmNewApp
    }
    
    public let newtService: NewtService
    var loaderData: Data
    var appData: Data
    
    var stateMachine: DFUStateMachine = DFUStateMachine()
    
    public weak var delegate: DFUStrategyDelegate?
    
    private var loaderImage: Image!
    private var appImage: Image!
    private var splitStatus = 0
    private var overallProgress: Double = 0
    private var timer: Timer?
    private var timerCount: Int = 45
    private var connectionObservation: NSKeyValueObservation?
    
    public init(newtService: NewtService, loader: Data, app: Data) {
        self.newtService = newtService
        self.loaderData = loader
        self.appData = app
        
        stateMachine.delegate = self
        connectionObservation = newtService.observe(\.isTransportConnected) { (newtService, change) in
            os_log("isConnected %@", log: NewtKitLog.dfu, type: .debug, newtService.isTransportConnected)
            newtService.isTransportConnected ? self.deviceDidConnect() : self.deviceDidDisconnect()
        }
    }
    
    public func start() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerStep(_:)), userInfo: nil, repeats: true)

        let op = ImageListOperation { [unowned self] (result) in
            switch result {
            case .success(let (splitStatus,  images)):
                self.splitStatus = Int(splitStatus)
                
                // SplitStatus = 0 -> Only slot 0 is occupied, go directly to loader upload
                if splitStatus == 0 {
                    self.loaderImage = images.filter { $0.isBootable }[0]
                    
                    self.stateMachine.enterState(EraseOldAppImageState(newtService: self.newtService, image: Data())) // clean scratch zone before starting upload
                } else { // Do regular process
                    self.loaderImage = images.filter { $0.isBootable }[0]
                    self.appImage = images.filter { !$0.isBootable }[0]
                    
                    self.stateMachine.enterState(DeactivateAppState(newtService: self.newtService, active: self.loaderImage.hash))
                }
                
                os_log("SplitStatus %d", log: NewtKitLog.dfu, type: OSLogType.debug, splitStatus)
            default: break
            }
        }
        newtService.execute(operation: op)
    }
    
    public func cancel() {
        timer?.invalidate()
        timer = nil
        
        stateMachine.currentState = nil
    }
    
    private func deviceDidConnect() {
        stateMachine.event(.connect)
    }
    
    private func deviceDidDisconnect() {
        stateMachine.event(.disconnect)
    }
    
    @objc private func timerStep(_ timer: Timer) {
        timerCount -= 1
        
        if timerCount <= 0 {
            // timeout
            delegate?.dfuStrategy(self, didFinishWithError: .timeout)
        }
    }
    
    func resetWatchDog() {
        timerCount = 45
    }
}

// MARK: - DFUStateMachineDelegate
extension DFUSplitStrategy: DFUStateMachineDelegate {
    func stateMachine(_ stateMachine: DFUStateMachine, didExit state: DFUState, error: DFUError?) {
        if let error = error {
            stateMachine.currentState = nil
            delegate?.dfuStrategy(self, didFinishWithError: error)
            return
        }
        
        resetWatchDog()
        
        switch state {
        case _ as DeactivateAppState:
            os_log("DeactivateAppState (%@) -> EraseOldAppImageState", log: NewtKitLog.dfu, type: .debug, appImage.hash.hexString)

            stateMachine.enterState(EraseOldAppImageState(newtService: newtService, image: appImage.hash))
            
        case _ as EraseOldAppImageState:
            os_log("EraseOldAppImageState -> UploadLoaderState", log: NewtKitLog.dfu, type: .debug)
            
            let uploadState = UploadLoaderState(newtService: newtService, imageData: loaderData)
            uploadState.delegate = self
            stateMachine.enterState(uploadState)
            
        case _ as UploadLoaderState:
            os_log("UploadLoaderState -> SetNewLoaderActiveState (%@)", log: NewtKitLog.dfu, type: .debug, loaderImage.hash.hexString)
            
            let op = ImageListOperation { [unowned self] (result) in
                switch result {
                case .success(let (_,  images)):
                    let newLoaderImage = images.filter { $0.isBootable }[1]
                    self.stateMachine.enterState(SetNewLoaderActiveState(newtService: self.newtService, active: newLoaderImage.hash))
                default: break
                }
            }
            newtService.execute(operation: op)
            
        case _ as SetNewLoaderActiveState:
            os_log("SetNewLoaderActiveState -> EraseOldLoaderImageState", log: NewtKitLog.dfu, type: .debug)
            stateMachine.enterState(EraseOldLoaderImageState(newtService: newtService, image: loaderImage.hash))
            
        case _ as EraseOldLoaderImageState:
            os_log("EraseOldLoaderImageState -> UploadAppState", log: NewtKitLog.dfu, type: .debug)
            self.overallProgress = 0.5
            let uploadState = UploadAppState(newtService: newtService, imageData: appData)
            uploadState.delegate = self
            stateMachine.enterState(uploadState)
            
        case _ as UploadAppState:
            os_log("UploadAppState -> SetNewAppActiveState", log: NewtKitLog.dfu, type: .debug)
            let op = ImageListOperation { [unowned self] (result) in
                switch result {
                case .success(let (_,  images)):
                    let newAppImage = images.filter { !$0.isBootable }[0]
                    self.stateMachine.enterState(SetNewAppActiveState(newtService: self.newtService, active: newAppImage.hash))
                default: break
                }
            }
            newtService.execute(operation: op)
            
        case _ as SetNewAppActiveState:
            os_log("SetNewAppActiveState -> THE END.", log: NewtKitLog.dfu, type: .debug)
            
            timer?.invalidate()
            stateMachine.currentState = nil
            
            delegate?.dfuStrategy(self, didFinishWithError: nil)

        default:
            break
        }
    }
}

// MARK: - UploadStateDelegate
extension DFUSplitStrategy: UploadStateDelegate {
    func uploadState(_ uploadState: UploadState, progress: Double) {
        resetWatchDog()
        
        delegate?.dfuStrategy(self, progress: self.overallProgress + progress * 0.5)
    }
}
