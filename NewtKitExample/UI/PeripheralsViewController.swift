//
//  PeripheralsViewController.swift
//  NewtKitExample
//
//  Created by Luís Silva on 28/09/2018.
//  Copyright © 2018 Chipp'd. All rights reserved.
//

import UIKit
import CoreBluetooth

class PeripheralsViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    private var workQueue: DispatchQueue = DispatchQueue(label: "NewtKitExample.workQueue")
    private lazy var centralManager: CBCentralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global(qos: .background), options: [:])
    private var peripherals: [CBPeripheral] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "NewtKit"
        _ = centralManager
    }
}

// MARK: - UITableViewDataSource
extension PeripheralsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let p = peripherals[indexPath.item]
        
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self))
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: String(describing: UITableViewCell.self))
        }
        
        cell.textLabel?.text = "\(p.name ?? "***Unnamed***")"
        cell.detailTextLabel?.text = p.identifier.uuidString
        return cell
    }
}

// MARK: - UITableViewDelegate
extension PeripheralsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        centralManager.connect(peripherals[indexPath.item], options: nil)
    }
}

// MARK: - CBCentralManagerDelegate
extension PeripheralsViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        default:
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard !peripherals.contains(peripheral) else { return }
        
        workQueue.sync {
            let indexPath = IndexPath(item: self.peripherals.count, section: 0)
            self.peripherals.append(peripheral)
            
            DispatchQueue.main.sync { [unowned self] in
                self.tableView.beginUpdates()
                self.tableView.insertRows(at: [indexPath], with: .automatic)
                self.tableView.endUpdates()
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async { [unowned self] in
            let storyboard = UIStoryboard(name: "NewtPeripheral", bundle: Bundle.main)
            let newtPeripheralViewController = storyboard.instantiateInitialViewController() as! NewtPeripheralViewController
            newtPeripheralViewController.peripheral = peripheral
            self.navigationController?.pushViewController(newtPeripheralViewController, animated: true)
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
    }
}
