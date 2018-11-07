//
//  btle.swift
//  kart
//
//  Created by Adekunle on 10/29/18.
//  Copyright © 2018 ade. All rights reserved.
//

import UIKit
import Foundation
import CoreBluetooth
import Foundation


var uuid: CBUUID!
class btle_view_controller: NSObject{
    var central_manager: CBCentralManager!
    var module: CBPeripheral!
    var ch: CBCharacteristic!
    var data_rec: UInt8 = 0x0
    
    var angle = "0"
    var ready_to_write = true
    
    override init() {
        super.init()
        print("To start bt service")
        central_manager = CBCentralManager(delegate:self, queue: nil);
    }
}

extension btle_view_controller: CBCentralManagerDelegate, CBPeripheralDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state{
        case .unknown:
            print("State unkown")
        case .resetting:
            print("State resetting")
        case .unsupported:
            print("State unsupported")
        case .unauthorized:
            print("State unauth")
        case .poweredOff:
            print("State powered off")
        case .poweredOn:
            print("State powered on")
            central_manager.scanForPeripherals(withServices: nil)
        }
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if (peripheral.name != "SH-HC-08"){
            return
        }
        uuid = CBUUID(nsuuid: peripheral.identifier)
        module = peripheral
        central_manager.stopScan()
        central_manager.connect(module)
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("\(peripheral) is now connected ")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {        
        if (peripheral.services != nil){
            peripheral.discoverCharacteristics(nil, for: peripheral.services![0])
            peripheral.discoverCharacteristics(nil, for: peripheral.services![1])
        }
        
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for c in service.characteristics!{
            peripheral.readValue(for: c)
        }

        print(service.characteristics)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if ( characteristic.uuid == CBUUID(string: "FFE1")){
            peripheral.setNotifyValue(true, for: characteristic)
            ch = characteristic
            print([UInt8](ch.value!))
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if !characteristic.isNotifying {
            return
        }
        let v = [UInt8](characteristic.value!)
        var s = String(v[0])
        angle = s
        s.append("°")
    }
    
    func get_angle() -> Float{
        return Float(angle)!
    }
    func write_to_bt (data: UInt8)->Bool{
        var d: Data = Data(bytes: [data, 0xFF])
        if (ch == nil){
            return false
        }
        self.module.writeValue(d, for: self.ch, type: .withoutResponse)
        ready_to_write = false
        return true
    }
    
}
