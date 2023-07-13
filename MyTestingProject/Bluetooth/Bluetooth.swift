//
//  Bluetooth.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/10.
//

import Foundation
import CoreBluetooth

class BlueTooth:NSObject,CBCentralManagerDelegate,CBPeripheralDelegate {
    // 透過 deviceName 找到對應裝置 設定 peripheral ,  用自己的 central 連接 該裝置
    // 透過 該裝置 找到 對應的 Service
    // 尋訪該 Service 提供哪些 Characteristic 服務
    
    // setNotifyValue 為開啟接收廣播(被動) 對方丟資料之後 就會呼叫 didUpdateValueFor
    // readValue 主動向對方要回傳資訊 ( 主要用在 傳送資訊給device 後 , 要求device回傳資訊給我 )
    
    private let DeviceServiceUUID = CBUUID.init(string: "a7cfd1bc-f1c0-11e6-bc64-92361f002671")
    private let DeviceCharacteristic_UUID = CBUUID.init(string: "b7cfd1bc-f1c0-11e6-bc64-92361f002671") // 測試 Characteristic
    private var selectCharacteristic_UUID = CBUUID.init()
    private let DeviceName = "ice"
    private let PairNameInUserDegault = "DeviceBluetooth"
    
    enum CharacteristicType {
        case 找不到服務
        case 此服務不提供傳接資訊
        case 可以使用
    }
    
    enum SendDataError:Error {
        case CharacteristicNotFound
    }
    
    lazy var centeralManager:CBCentralManager = CBCentralManager.init(delegate: self, queue: nil)
    
    @Published var peripherals = [CBPeripheral]() // 搜尋到的
    
    var addPeripherals:CBPeripheral? // 欲加入的
    @Published var connectPeripherals = [CBPeripheral]() // 已經連接上的
    
    var charDictionary = [String:CBCharacteristic]() // 每個 Service 資訊 有哪些 Characteristic 訊息
    /*
    var addPeripheral:((CBPeripheral)->Void)? // 增加Device
    var getServiceHandler:(([CBService])->())? // 連接後 取得 Services
    var doneHandler:(()->())? // 點選 Services 後 取得到的所有 Characteristics
     */
    var handler:((_:String)->())? // 取得device傳遞過來的資料
    var connectErrorHandler:(()->())? // 發生某些原因 導致斷線 連接失敗
    
    func startScan() {
        centeralManager.scanForPeripherals(withServices: nil,options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
    }
    
    func stopScan() {
        centeralManager.stopScan()
    }
    
    private func isPaired()->Bool { // 檢查是否已經配對過
        let user = UserDefaults.standard
        if let uuidString = user.string(forKey: PairNameInUserDegault) {
            let uuid = UUID(uuidString: uuidString)
            let list = centeralManager.retrievePeripherals(withIdentifiers: [uuid!])
            if list.count > 0 {
                for peripheral in list {
                    connectPeripherals.append(peripheral)
                    peripheral.delegate = self
                }
                return true
            }
        }
        return false
    }
    
    private func cancel() {
        for peripheral in connectPeripherals {
            centeralManager.cancelPeripheralConnection(peripheral)
        }
        connectPeripherals.removeAll()
        peripherals.removeAll()
        print("連線中斷")
    }
    
    func closeBlueTooth() { 
        centeralManager.stopScan() // 停止掃描
        cancel() // 取消連線
        //centeralManager = nil
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if isPaired() { // 已經配對過 直接連線
            for peripheral in peripherals {
                centeralManager.connect(peripheral,options: nil)
            }
        }
        else {
            centeralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
        }
    }
    
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) { // 判斷搜尋到的裝置
        guard peripheral.name != nil /* && peripheral.name?.contains(DeviceName) == true */ else { return }
        guard peripherals.first(where: { $0.name == peripheral.name} ) == nil else { return } // 已經搜過的不用搜
        guard connectPeripherals.first(where: { $0.name == peripheral.name} ) == nil else { return } // 已經連接的不用搜
        peripherals.append(peripheral)
        //addPeripheral?(peripheral)
        //centeralManager.stopScan()
        /*
        connectPeripheral = peripheral
        connectPeripheral.delegate = self
        centeralManager.connect(connectPeripheral, options: nil)*/
    }
    
    func selectPeripheral(index:Int) {
        let peripheral = peripherals[index]
        addPeripherals = peripheral
        addPeripherals!.delegate = self
        centeralManager.connect(addPeripherals!,options:nil)
        connectPeripherals.append(addPeripherals!)
        peripherals.remove(at: index)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) { // 連接到 重制 dicitonary
        charDictionary = [:]
        peripheral.discoverServices(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) { // 該裝置有哪些service
        guard error == nil else {
            print("error : \(String(describing: error))")
            return
        }
        
        for service in peripheral.services! {
            peripheral.discoverCharacteristics(nil, for: service)
        }
        /*
        for service in peripheral.services! {
            if ( service.uuid == DeviceServiceUUID ) {
                connectPeripheral.discoverCharacteristics(nil, for: service)
                break
            }
        }*/
    }
    
    func selectChar(charID:CBUUID)->CharacteristicType {
        guard let characteristic = charDictionary[charID.uuidString]
        else { return .找不到服務 }
        
        if ( !characteristic.properties.contains([.notify]) ) {
            return .此服務不提供傳接資訊
        }
        
        selectCharacteristic_UUID = charID
        return .可以使用
        /*
        if ( characteristic.properties.contains([.notify,.notifyEncryptionRequired])) {
            connectPeripherals[per_index].setNotifyValue(true, for: characteristic)
        }*/
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) { // service 內有哪些 Characteristics
        guard error == nil else {
            print("error : \(String(describing: error))")
            return
        }
        
        for characteristic in service.characteristics! {
            let uuidString = characteristic.uuid.uuidString
            charDictionary[uuidString] = characteristic
            print("找到:\(uuidString)")
            if characteristic.properties.contains([.notify]) { // 找到我要的 Characteristic_UUID 服務
                // 這裡可以根據每個 UUID 做對應事情
                // if ( uuidString == "XXX" ) .....
                addPeripherals?.setNotifyValue(true, for: characteristic) // 監聽 這個服務 characteristic  , 只要對方一丟訊息  呼叫 didUpdateValueFor 接收訊息
            }
        }
        
        //doneHandler?() // 告知外面服務設定完成
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) { // 取得資料
        guard error == nil else {
            print("error : \(String(describing: error))")
            return
        }
        
        let data = characteristic.value! as NSData
        let string = String(data: data as Data, encoding: .utf8) ?? ""
        
        print( "getData From \(peripheral.name ?? "裝置") :\(string)")
        
       
        if let handler = handler , characteristic.uuid == selectCharacteristic_UUID {
            handler(string)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) { // 檢測是否 "監聽資訊變化" 有狀況
        if ( error != nil ) {
            print(error!)
        }
    }
    
    func sendData(_ data:Data , writeType: CBCharacteristicWriteType) throws { // 送出資料 到 對應 characteristic
        guard let characteristic = charDictionary[selectCharacteristic_UUID.uuidString] else {
            throw SendDataError.CharacteristicNotFound
        }
        addPeripherals?.writeValue(data, for: characteristic,type: writeType)
        
    }
    
    func readData() {
        addPeripherals?.setNotifyValue(true, for: charDictionary[selectCharacteristic_UUID.uuidString]!) // 數值一更動 回調 didUpdateValueFor (被動 監聽直是否發生變化)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) { // 寫入之後調用
        print("Write Characteristic :", characteristic) // 要寫入的對象
        if ( error != nil ) { // 有error 就不讀取
            print(error!)
        }
        else { // 要資料(QRCode)
            peripheral.readValue(for: characteristic) // 此執行完後 會呼叫 didUpdateValueFor 直接向Bee 要資料 (主動 發起訊息後 立刻要求回傳資料)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) { // 連接失敗 調用
        if ( error != nil ) {
            print(error!)
        }
        centeralManager.cancelPeripheralConnection(peripheral)
        // 判斷是否連接錯誤的是我現在使用的
        // 是的話要回傳錯誤出去 讓view pop回上一頁
        for service in peripheral.services ?? [] {
            for char in service.characteristics ?? [] {
                if ( char.uuid == selectCharacteristic_UUID ) {
                    connectErrorHandler?()
                    break
                }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) { // 要重新連接時 調用
        centeralManager.cancelPeripheralConnection(peripheral)
        if ( isPaired() ) { // 如果已經配對過 直接連接
            centeralManager.connect(peripheral, options: nil)
        }
    }
    
    func unPair() { // 小心調用  Mark: 如果要調用此去解配對  必需還要在裝置上 告知使用者手動取消藍芽配對, 不然會解了跟沒解一樣
        let user = UserDefaults.standard
        user.removeObject(forKey: PairNameInUserDegault)
        user.synchronize()
        
        for peripheral in connectPeripherals {
            centeralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
}
