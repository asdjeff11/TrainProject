//
//  SocketConnector.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/13.
//

import Foundation
import Network
import Dispatch

@available(OSX 10.14, *)
class SocketConnector {
    private static let host = NWEndpoint.Host("127.0.0.1")
//    private static let host = NWEndpoint.Host("192.168.1.86")
//    private static let host = NWEndpoint.Host("192.168.1.3")


    private var dq = DispatchQueue(label: "Server", qos: DispatchQoS.background) // 背景執行
    private var connection: NWConnection! // 連接器
    private var ds:DispatchSemaphore? = DispatchSemaphore(value: 0) // 等待資料回傳 使用
    private var ds_close:DispatchSemaphore = DispatchSemaphore(value: 1) // 專門給 close 使用 , 貌似有case 會有兩人同時close 發生crash 事件
    private var length: Int = 0 // 接收到的資料長度
    private var myPort:NWEndpoint.Port! // 此連接的 port
    private var ID:Int // 此連接的ID ( 用來辨識連線 Debug 使用)
    private var lastUsedTime = Date().timeIntervalSince1970 // 紀錄上次連線的時間  ( 長連接用不到
    private var data: Data? // 接收到的資料
    private var err: NWError? // 是否連線錯誤
    
    private var ctl: DispatchWorkItem? // 好像用不到
    static var onBackGround:Bool = false // 以前的使用 判斷是否在背景執行當中  (( 現在會與系統借用 30 秒 去撈取  如果30秒撈不完 且使用者還未回來app  讓app閃退好像也沒太大問題 ))
    static var alertMsg:Bool = false // 以前的使用  判斷是否已經有錯誤資訊顯示

    private init(_ port: NWEndpoint.Port,ID:Int) {
        myPort = port
        self.ID = ID
        
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.enableKeepalive = true
        tcpOptions.keepaliveIdle = 50
        tcpOptions.keepaliveCount = 5
        tcpOptions.keepaliveInterval = 10
        connection = NWConnection(host: SocketConnector.host, port: port, using: NWParameters(tls: nil,tcp:tcpOptions) )
        
        //connection = NWConnection(host: SocketConnector.host, port: port, using: createTLSParameters(allowInsecure: true, queue: dq))
        connection.stateUpdateHandler = stateDidChanged(to:)
        connection.start(queue: dq)
    }
    
    
    func createTLSParameters(allowInsecure: Bool, queue: DispatchQueue) -> NWParameters {
        let options = NWProtocolTLS.Options()
        sec_protocol_options_set_verify_block(options.securityProtocolOptions, { (sec_protocol_metadata, sec_trust, sec_protocol_verify_complete) in
            let trust = sec_trust_copy_ref(sec_trust).takeRetainedValue()
            if let url = Bundle.main.url(forResource: "localhost", withExtension: "der"),
               let data = try? Data(contentsOf: url),
               let cert = SecCertificateCreateWithData(nil, data as CFData) {
               if SecTrustSetAnchorCertificates(trust, [cert] as CFArray) != errSecSuccess {
                   sec_protocol_verify_complete(false)
                   return
               }
            }
            
            // 设置验证策略
            let policy = SecPolicyCreateSSL(true, "myserver" as CFString)
            SecTrustSetPolicies(trust, policy)
            SecTrustSetAnchorCertificatesOnly(trust, true)
             
            // 验证证书链
            var error: CFError?
            if SecTrustEvaluateWithError(trust, &error) {
                sec_protocol_verify_complete(true)
                 
            } else {
                sec_protocol_verify_complete(false)
                print(error!)
            }
        }, queue)
        
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.enableKeepalive = true
        tcpOptions.keepaliveIdle = 50
        tcpOptions.keepaliveCount = 5
        tcpOptions.keepaliveInterval = 10
        
        return NWParameters(tls: options,tcp:tcpOptions)
    }
    
    public static func Instance(port:UInt16, ID:Int)->SocketConnector {
        let endPort = NWEndpoint.Port(rawValue:port)
        return SocketConnector(endPort!,ID: ID)
    }
  
    private func formatLengthData(_ length: Int) -> Data {
        var buffer = Data(count: 2)
        buffer[0] = UInt8(length & 0xFF)
        buffer[1] = UInt8((length >> 8) & 0xFF)
        return buffer
    }
    
    private func parseLengthData(_ data: Data) -> Int {
        return (Int(data[0]) & 0xFF) | ((Int(data[1]) & 0xFF) << 8)
    }
    
    private func sendCompletion(e: NWError?) { // 傳送完成後 呼叫
        err = e
        if ( err != nil || myPort == 19998 ) { // 19998 為 notification server 已經送完了
            close()
        }
        
        // ds.signal()
        /*if ( err != nil ) {
            print(err!.localizedDescription)
        }*/
    }
  

    public func send(_ command: String? = nil ,_ data:Data? = nil ) {
        if ( connection == nil ) { return }
        if ( command == nil && data == nil ) { return }
        
        let commandData = ( command != nil ? command!.data(using: String.Encoding.utf8) : data )
        //var size = command.utf8.count
        let dataLen = commandData!.count
        let chunkSize = (2048) // 2 KB
        let fullChunks = Int(dataLen / chunkSize)
        let totalChunks = fullChunks + (dataLen % 2048 != 0 ? 1 : 0)

        var chunks:[Data] = [Data]()
        for chunkCounter in 0..<totalChunks {
            var chunk:Data
            let chunkBase = chunkCounter * chunkSize
            var diff = chunkSize
            if(chunkCounter == totalChunks - 1) {
                diff = dataLen - chunkBase
            }
            
            let range:Range<Data.Index> = (chunkBase..<(chunkBase + diff))
            chunk = commandData!.subdata(in: range)
            chunks.append(chunk)
        }
        
        for i in 0..<chunks.count {
            let data = formatLengthData(chunks[i].count) + chunks[i]
            if ( connection == nil ) { break }
            connection.send(content: data, completion: NWConnection.SendCompletion.contentProcessed(sendCompletion))
        }
    }
    
    public func sendComplete() {
        if ( connection == nil ) { return }
        connection.send(content: formatLengthData(-1), completion: NWConnection.SendCompletion.contentProcessed(sendCompletion))
    }
    
    private func readMessageCompletion(d: Data?, context: NWConnection.ContentContext?, b: Bool, e: NWError?) {
        err = e
        data = d
        ds?.signal()
    }
    
    private func readLengthCompletion(d: Data?, context: NWConnection.ContentContext?, b: Bool, e: NWError?) {
        guard let _ = d else {
            close() // 關閉連線   buffer 沒資料read ( 可能是APServer斷線了 or 錯誤被APServer斷線 沒回傳資料
            length = 0xFFFF // -2
            ds?.signal() // timeOut 會進來這邊 d = nil
            return
        }
        err = e
        length = parseLengthData(d!)
        //print("received length: \(length)" )
        
        if length == 0xFFFF || connection == nil {
            data = nil
            ds?.signal()
        }
        else if length > 0 {
            connection.receive(minimumIncompleteLength: length, maximumLength: length, completion: readMessageCompletion)
        }
    }
        
    public func read(_ buffer: inout Data) {
        if ( connection == nil ) { return }
        repeat {
            connection.receive(minimumIncompleteLength: 2, maximumLength: 2, completion: readLengthCompletion )
            if ( self.ds?.wait(timeout: .now() + 10) == .timedOut ) { // 設定time out
                let data = "timeOut".data(using: .utf8)!
                buffer = data
                close()
                return
            }
            
            if ( getIsLive() == false ) {
                let data = "connection refuse".data(using: .utf8)!
                buffer = data
                return
            }
            
            if data != nil {
                buffer.append(data!)
                data = nil
            }
            
        } while length != 0xFFFF
    }
    
    public func close() {
        ds_close.wait()
        defer {
            ds_close.signal()
        }
        if ( connection != nil ) {
            connection.stateUpdateHandler = nil
            if ( connection.state != .cancelled ) { connection.cancel() }
            connection = nil
        }
        
        if let ctl = ctl, ctl.isCancelled == false {
            ctl.cancel()
            self.ctl = nil
        }
        
        ConnectStack.stacks.releaseServerConnect(server: self) // 釋放
    }
}

extension SocketConnector {
    public func removeData() {
        self.data = nil
    }
    
    public func setTime() { // 目前先不用
        self.lastUsedTime = Date().timeIntervalSince1970
    }
}


extension SocketConnector { // 狀態判斷
    private func stateDidChanged(to state: NWConnection.State) {
        switch state {
        case .preparing:
            print("connection is preparing...")
            break
        case .setup:
            print("connection is about to setup")
            break
        case .ready:
            print("connection is ready")
            break
        case .cancelled:
            print("connection is cancelled")
            close()
            break
        case .waiting(let error) :
            print("Waiting for connection error, ", error)
            //alertMsg("連線被拒絕 請回報公司")
            close()
            break
        case .failed(let error): // 心跳包的 timeout 好像會來這邊執行
            print("Connection failed, ", error)
            //alertMsg("連線失敗")
            close()
            break
        default:
            print("Error Occured")
        }
    }
}

extension SocketConnector { // 取得資訊
    public func getID()->Int{ return ID }
    
    public func getPort()->NWEndpoint.Port { return myPort }
    
    public func getIsLive()->Bool {
        return connection != nil && connection.state == .ready
    }
}
