//
//  NewtPeripheralViewController.swift
//  NewtKitExample
//
//  Created by Luís Silva on 28/09/2018.
//  Copyright © 2018 Chipp'd. All rights reserved.
//

import UIKit
import CoreBluetooth
import NewtKit

let kNewtServiceUUIDString = "8D53DC1D-1DB7-4CD3-868B-8A527460AA84"
let kNewtCharacteristicUUIDString = "DA2E7828-FBCE-4E01-AE9E-261174997C48"

let kCommandsSection = 1
let kCommandEcho = 0
let kCommandImageList = 1

class NewtPeripheralViewController: UITableViewController {
    var newtService: NewtService = NewtService()
    var peripheral: CBPeripheral! { didSet { peripheral.delegate = self } }
    var newtCharacteristic: CBCharacteristic?

    @IBOutlet weak var inTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        newtService.transport = self
        
        inTextView.text = ""
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        explore()
    }
    
    func explore() {
        setConnectionString("Discovery")
        
        peripheral.discoverServices([CBUUID(string: kNewtServiceUUIDString)])
    }
    
    // MARK: -
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case kCommandsSection:
            if indexPath.item == kCommandEcho {
                commandEcho()
            } else if indexPath.item == kCommandImageList {
                commandImageList()
            }
            
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - UI Util
    
    private func setConnectionString(_ connectionString: String) {
        DispatchQueue.main.async {
            let cell = super.tableView(self.tableView, cellForRowAt: IndexPath(item: 0, section: 0))
            cell.textLabel?.text = connectionString
        }
    }
    
    private func addStringToOutput(_ string: String) {
        DispatchQueue.main.async {
            self.inTextView.text = "\(self.inTextView.text ?? "")\n> \(string)"
            
            self.inTextView.scrollRangeToVisible(NSRange(location: self.inTextView.text.count - 1, length: 1))
        }
    }
    
    // MARK: - Commands Util
    
    private func commandEcho() {
        let alertController = UIAlertController(title: "Echo", message: nil, preferredStyle: UIAlertController.Style.alert)
        alertController.addTextField { (textField) in
            
        }
        let sendAction = UIAlertAction(title: "Send", style: .default) { (action) in
            guard let text = alertController.textFields?.first?.text else { return }

            let op = EchoOperation(string: text, result: { (result) in
                switch result {
                case .success(let string):
                    self.addStringToOutput(string)
                    
                case .failure(_): break
                }
            })
            self.newtService.execute(operation: op)
        }
        alertController.addAction(sendAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action) in
            
        }
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    private func commandImageList() {
        let op = ImageListOperation { (result) in
            switch result {
            case .success(let imageList):
                self.addStringToOutput(String(describing: imageList))
            case .failure(_): break
            }
        }
        newtService.execute(operation: op)
    }

}


// MARK: - CBPeripheralDelegate
extension NewtPeripheralViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        peripheral.services?.forEach {
            if $0.uuid.uuidString == kNewtServiceUUIDString {
                peripheral.discoverCharacteristics([CBUUID(string: kNewtCharacteristicUUIDString)], for: $0)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        service.characteristics?.forEach {
            if $0.uuid.uuidString == kNewtCharacteristicUUIDString {
                newtCharacteristic = $0
                peripheral.setNotifyValue(true, for: $0)
                
                setConnectionString("Ready")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value {
            newtService.didReceive(data: data)
        }
    }
}

// MARK: - NewtServiceTransportDelegate
extension NewtPeripheralViewController: NewtServiceTransportProtocol {
    func newtService(_ newtService: NewtService, write data: Data) {
        guard let c = newtCharacteristic else { fatalError() }
        let writeType: CBCharacteristicWriteType = c.properties.contains(.writeWithoutResponse) ? .withoutResponse : .withResponse
        peripheral.writeValue(data, for: c, type: writeType)
    }
}
