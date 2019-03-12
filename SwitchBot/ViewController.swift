//
//  ViewController.swift
//  SwitchBot
//
//  Created by Minhajul Russell on 2019/03/05.
//  Copyright © 2019 Minhajul Russell. All rights reserved.
//

import UIKit
import CoreBluetooth

let switchBotUUID = CBUUID.init(string: "CBA20D00-224D-11E6-9FB8-0002A5D5C51B")
let switchBotArmUUID = CBUUID.init(string: "CBA20002-224D-11E6-9FB8-0002A5D5C51B")

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    @IBOutlet weak var peripherialLabel: UILabel!
    var centralManager: CBCentralManager!
    var myPeripherial: CBPeripheral?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        centralManager = CBCentralManager.init(delegate: self, queue: nil)
    }

    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            central.scanForPeripherals(withServices: nil, options: nil)
            print("scan for peripheral")
        } else if central.state == CBManagerState.poweredOff {
            print("Bluetooth is off")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        guard let peripherialName = peripheral.name else {
            return
        }
        print("Descovered peripheral name: \(peripherialName)")
        
        if peripheral.name?.contains("WoHand") == true {
            print(peripheral.name ?? "no name")
            self.peripherialLabel.text = peripheral.name
            centralManager.stopScan()
            print("Advertising data: \(advertisementData)")
            central.connect(peripheral, options: nil)
            myPeripherial = peripheral
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        central.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected : \(peripheral.name ?? "no name")")
        peripheral.discoverServices(nil)
        peripheral.delegate = self
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == switchBotUUID {
                    print("Service string is: \(service.uuid.uuidString)")
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
        }
    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let chars = service.characteristics {
            for char in chars {
                
                print("char.properties.rawValue is : \(char.properties.rawValue)")
                print("discovered characteristic: \(char.uuid.uuidString) | read=\(char.properties.contains(.read)) | write=\(char.properties.contains(.write))")

                let command:[UInt8] = [0x57, 0x01, 0x00]
                let commandData = NSData(bytes: command, length: command.count)
                if char.uuid == switchBotArmUUID {
                    
                    peripheral.readValue(for: char)
                    
                    if char.properties.contains(CBCharacteristicProperties.writeWithoutResponse) {
                        peripheral.writeValue(commandData as Data, for: char, type: CBCharacteristicWriteType.withoutResponse)
                    } else {
                        peripheral.writeValue(commandData as Data, for: char, type: CBCharacteristicWriteType.withResponse)
                    }
                }
                
            }
            
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("error while writing value to \(characteristic.uuid.uuidString): \(error.debugDescription)")
        } else {
            print("didWriteValueFor \(characteristic.uuid.uuidString)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if characteristic.uuid == switchBotArmUUID {
            print("characteristic.value is: \(characteristic.value!)")
        }
    }
    
    
    @IBAction func moveArm(_ sender: Any) {
        print("Move Arm tapped")
        centralManager = CBCentralManager.init(delegate: self, queue: nil)
    }
    
}

