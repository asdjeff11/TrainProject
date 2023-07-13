//
//  BluetoothVIewModel.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/10.
//

import Foundation
import CoreBluetooth
import Combine
import UIKit
class BluetoothViewModel:ViewModelActivity {
    lazy var bluetooth:BlueTooth = {
        let bluetooth = BlueTooth()
        //bluetooth.doneHandler = bluetoothDoneHandler
        //bluetooth.addPeripheral = addPeripheral
        bluetooth.handler = handlerBlueTooth
        return bluetooth
    }() // 藍芽物件
 
    /*private func startScan() {
        bluetooth.startScan()
        DispatchQueue.global(qos:.background).asyncAfter(deadline: .now() + 15) { [weak self] in // 15秒後停止掃描
            self?.bluetooth.centeralManager.stopScan()
        }
    }*/
    
    /*func selectPeripheral(index:Int) {
        if ( index < bluetooth.connectPeripherals.count ) {
            self.bluetooth.selectPeripheral(peripheral: peripherals[index])
        }
    }*/
}


extension BluetoothViewModel {
    func handlerBlueTooth(message:String) {
        print(message)
    }
    
    func bluetoothDoneHandler() {
        showAlert?("提醒","已連接上Bee藍芽")
    }
}
