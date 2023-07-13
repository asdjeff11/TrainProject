//
//  DataAction.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/13.
//

import Foundation
import Network
import UIKit

class DataAction_KeepAlive {
    enum updateErrorType:Error {
        case noWifi
        case notConnect
        case startGroup
        case command(String)
        case successGroup
        case endGroup
    }
    
    enum IDActionType:Int {
        case confirm = 2
        case release = 3
    }
    
    enum ActionType {
        case Update,Add
    }
    
    final private let smallSize:CGSize = CGSize(width: 480, height: 480)
    static private let reSend_times = 3
    
    private var UUID:String = ""
    private var communityID:String = ""

    
    private var canSend:Bool = false // 控制是否開啟網路
    init() {
        /*if let myUserData = myUserData {
            UUID = myUserData.getUUID()
            communityID = myUserData.getCommunityID()
        }
        else {
            UUID = ""
            communityID = ""
        }*/
        canSend = true
    }
}

extension DataAction_KeepAlive {
    public func setUUIDAndCommunity( UUID:String, communityID:String) { // 換社區
        canSend = true
        self.UUID = UUID
        self.communityID = communityID
        ConnectStack.stacks.releaseIDServerConnect() // 釋放 IDServer 要用再自己去建立
        // 設定 ID communityID
    }
    
    
    public func setStatus(_ status:Bool) {
        canSend = status
    }
    
    public func getStatus()->Bool {
        return canSend
    }

}

extension DataAction_KeepAlive { // 圖片處理
    public func setImage(originalImg:UIImage,times:Int = DataAction_KeepAlive.reSend_times) -> (Bool,String) { // 回傳 errorCode , hash碼
        var result = false
        //guard let originalImg = UIImage.convertStringData(from: originalImg_String) else { return (result,"") }
       
        let smallImg = UIImage.resize_no_cut(image: originalImg, newSize: smallSize)
        //guard let smallImg_String = UIImage.convertUIImageData(from: smallImg) else { return (result,"") }
        
        
        let data_original = originalImg.pngData()!
        let data_smaller = smallImg.pngData()!
        
        var totalData:Data = Data()
        // errorCode
        var errorCode = Data(count: 1)
        errorCode[0] = UInt8(0)
        // 圖片類別 (判斷是否要讓Bee 存在本機上)
        var imageType = Data(count:1)
        imageType[0] = UInt8(8)
        
        // originalImageLength
        let originalImageLength = intTo4BytesData(data_original.count)
        // smallImageLength
        let smallImageLength = intTo4BytesData(data_smaller.count)
        
        totalData = errorCode + imageType + originalImageLength  + data_original + smallImageLength + data_smaller
        
        // send
        let server = ConnectStack.stacks.getServer(port: Port.PicPort.rawValue)
        defer {
            ConnectStack.stacks.finishUsedServer(server)
        }
        server.send(nil,totalData)
        server.sendComplete()
        var data = Data()
        server.read(&data)
        if ( server.getIsLive() ) {
            let err = String.init(data[0]) // errorCode
            let subData = data.subdata(in: 1..<data.count) // 圖片資料
            // 回傳為 16bytes 的 base64 data
            // base64 是  原8bits 用6bits 實現   3 個bytes 24bits 用 4個base64字符 ( 4 * 6 = 24) 實現  多餘的位數
            // 尾巴的 "=" 為padding位 移除即可
            let hash = subData.base64EncodedString() // .replacingOccurrences(of: "=", with: "") // 要存入的值
            
            switch ( err ) {
                case "0" :
                    result = true
                    break
                case "2" :
                    result = true
                    print("重複插入")
                    break
                default :
                    print("插入錯誤")
                    break
            }
            
            return (result,hash)
        }
        else { // 連線異常 (被斷線了)
            if ( String(decoding: data as Data, as: UTF8.self).contains("refuse") ) { // 如果是 refuse
                return (false,"connection refuse!") // 連線拒絕 就不重撈了
            }
            else if ( times != 0 ) {
                return setImage(originalImg: originalImg, times:times - 1) // 再呼叫一次
            }
            else {
                return ( false , "connection failed!")
            }
        }
        
    }
    
    public func getImage(hash:String,imageType:Int,times:Int = DataAction_KeepAlive.reSend_times )->UIImage? { // 取得圖片
        // imageType == 0 original , 1 smaller
        var result:UIImage? = nil
        var totalData:Data = Data()
        
        // 錯誤碼
        var errorCode = Data(count: 1)
        errorCode[0] = UInt8(1)
        // 要求要 大圖 or 小圖
        var imageTypeCode = Data(count: 1)
        imageTypeCode[0] = UInt8(imageType)
       
        
        let base64 = hash.HexBase64Hash // Hex -> Base64
        
        guard let hashdata = base64.hexadecimal else { return nil }
        
        
        totalData = errorCode + imageTypeCode + hashdata // hashCode
        // send
        let server = ConnectStack.stacks.getServer(port: Port.PicPort.rawValue)
        defer {
            ConnectStack.stacks.finishUsedServer(server)
        }
        server.send(nil,totalData)
        server.sendComplete()
        var data = Data()
        server.read(&data)
        /*
         ConnectStack.stacks.finishUsedServer(server)
    
        if ( data.count == 7 ) { // 這個判斷是因為 如果資料量很大 轉字串會很費時  故先判斷大小來確定資料是否正常
            if ( String(decoding: data as Data, as: UTF8.self) == "timeOut" ) { // 如果是 timeOut
                resend(commandData:totalData, port:Port.resident.rawValue, data:&data) // 重送 ( 至多三次 )
            }
        }*/
        
        if ( server.getIsLive() ) {
            // Define the length of data to return
            let err = String.init(data[0]) // errorCode
            //let importantType = Int.init(data[1]) // 圖片是否重要 ( 主要是給bee 使用啦 )
            switch ( err ) {
                case "0" : // 正確回傳
                    let subData = data.subdata(in: 2..<data.count) // 圖片資料
                    result = UIImage(data:subData)
                    break
                case "1" :
                    print("找不到圖片")
                    break
                case "2" :
                    print("資料庫錯誤")
                    break
                default :
                    print("讀取錯誤")
                    break
            }
            
            return result
        }
        else {
            if ( String(decoding: data as Data, as: UTF8.self).contains("refuse") ) { // 如果是 refuse
                return nil // 連線拒絕 就不重撈了
            }
            else if ( times != 0 ) {
                return getImage(hash: hash, imageType: imageType,times: times - 1) // 再呼叫一次
            }
            else {
                return nil
            }
        }
    }
    
    private func intTo4BytesData(_ length: Int) -> Data { // image 圖片 檔案大小  4bytes
        var myLength = length
        var buffer = Data(count: 4)
        buffer[0] = UInt8(myLength & 0xFF)
        myLength = myLength >> 8
        buffer[1] = UInt8(myLength & 0xFF)
        myLength = myLength >> 8
        buffer[2] = UInt8(myLength & 0xFF)
        myLength = myLength >> 8
        buffer[3] = UInt8(myLength & 0xFF)
        return buffer
    }
}


extension DataAction_KeepAlive { // 取ID
    func setIDServer(_ server:SocketConnector)throws {
        var totalData:Data = Data()
        // 指令碼
        var commandCode = Data(count: 1)
        commandCode[0] = UInt8(0)
        
        totalData = commandCode + communityID.data(using: .utf8)!
      
        server.send(nil,totalData)
        server.sendComplete()
        var data = Data()
        server.read(&data)
        
        if ( server.getIsLive() ) {
            let err = String.init(data[0]) // errorCode
            if ( err == "1" ) {
//                throw errorType.IDServerError("IDServer community not exist")
                throw ErrorCase.IDServerError("IDServer community not exist")
            }
            else if ( err == "2" ) {
//                throw errorType.IDServerError("IDServer 資料錯誤")
                throw ErrorCase.IDServerError("IDServer 資料錯誤")
            }
        }
        else {
//            throw errorType.IDServerError("連接失敗")
            throw ErrorCase.IDServerError("連接失敗")
        }
    }
    
    func getID(IDType:String,count:Int)throws ->[Any] { // get ID
        enum IDReturnType {
            case 字串
            case 數字
        }
        
        func getReturnType()->IDReturnType {
            if ( IDType == "Payroll" || IDType == "Leave" || IDType == "Matters" || IDType == "OvertimeRecord" || IDType == "Message") {
                return .數字
            }
            else {
                return .字串
            }
        }
        
        var result = [Any]() // 要回傳的ID 列表
        
        var totalData:Data = Data()
        // 指令碼
        var commandCode = Data(count: 1)
        commandCode[0] = UInt8(1)
        
        // count
        var countCode = Data(count: 1)
        countCode[0] = UInt8(count)
        
        // IDType
        let IDType_Data = IDType.data(using: .utf8)!
        
        totalData = commandCode + countCode + IDType_Data
        
        // send
        var data = try sendToIDServer(data: totalData) // 資料
        let type = getReturnType()
        // 解析資料
        while data.isEmpty == false {
            var length = 4 // default  數字是 4 bytes 長度
            switch ( type ) {
            case .字串 :
                length = Int(String.init(data[0]))! // 取得資料長度
                if ( data.count - 1 < length ) { // 資料長度 < 我預計要接到的長度
                    throw ErrorCase.IDServerError("IDServer 回傳資訊異常")
                }
                let ID_Data = data.subdata(in: 1..<(length+1)) // 擷取 資料內容
                let ID = String(decoding: ID_Data, as: UTF8.self) // data -> string
                result.append(ID as Any) // append string
                data = data.subdata(in: (length+1)..<data.count) // data 往下
                break
            case .數字 :
                if ( data.count < 4 ) { throw ErrorCase.IDServerError("ID 回傳異常")}
                let ID_Data = data.subdata(in: 0..<length) // 擷取 資料內容
                let ID = ID_Data.fourBytesToInt() // 4bytes data -> Int  裡面做了一次bytes 反轉 問翔恩 為什麼要這樣放
                result.append(ID as Any) // append Int
                data = data.subdata(in: length..<data.count) // data 往下
                break
            }
        }
        /*
        registerID.store.setID(IDType: IDType, IDs: result)
        
        if ( result.count != count ) {
            registerID.store.releaseID()
//            throw errorType.IDServerError("ID 編號數量異常")
            throw ErrorCase.IDServerError("ID 編號數量異常")
        }*/
        
        return result
    }
    
    func IDAction(IDs:[String],IDType:String = "" , actionType:IDActionType) throws { // release and confirm
//        if ( IDs.isEmpty ) { throw errorType.IDServerError("ID 陣列為空") }
        if ( IDs.isEmpty ) { throw ErrorCase.IDServerError("ID 陣列為空") }

        
        var totalData = Data()
        // 指令碼
        var commandCode = Data(count: 1)
        commandCode[0] = UInt8(actionType.rawValue)
        
        totalData = commandCode
        
        var type_Data = Data()
        var type_length = Data(count: 1)
        
        let type = IDType //(IDType != "") ? IDType : translateID.getType(id: IDs[0])
//        if ( type == "" ) { throw errorType.IDServerError("ID 類別有誤") }
        if ( type == "" ) { throw ErrorCase.IDServerError("ID 類別有誤") }

        type_Data = type.data(using: .utf8)!
        type_length[0] = UInt8( type_Data.count & 0xFF)
        
        totalData += type_length + type_Data
        
        // 放入資料
        for ID in IDs {
            let argument = ID.components(separatedBy: ":")
            if ( argument.count == 1 ) {
                let data = ID.data(using: .utf8)!
                var data_len = Data(count: 1)
                data_len[0] = UInt8( data.count & 0xFF)
                totalData += data_len + data
            }
            else if ( argument.count == 2 ) {
                let myID = Int(argument[1])!
                let data = intTo4BytesData(myID)
                totalData += data
            }
        }
        
        // send
        let data = try sendToIDServer(data: totalData)
        // 解析資料
        for i in 0..<data.count {
            let err = String.init(data[i])
            if ( err == "1" ) {
                throw ErrorCase.IDServerError("ID :\(IDs[i])  本擁有者編號無任何紀錄")
               // print( "ID :\(IDs[i])  本擁有者編號無任何紀錄 " )
            }
            else if ( err == "2" ) {
                throw ErrorCase.IDServerError( "ID :\(IDs[i])  本擁有者並不擁有此ID ")
                //print( "ID :\(IDs[i])  本擁有者並不擁有此ID " )
            }
        }
    }
    
    private func sendToIDServer(data:Data)throws->Data {
        var result = Data()
        let server = ConnectStack.stacks.getServer(port: Port.IDServer.rawValue)
        defer {
            ConnectStack.stacks.finishUsedServer(server)
        }
        server.send(nil,data)
        server.sendComplete()
        var turnBackData = Data()
        server.read(&turnBackData)
        
        if ( server.getIsLive() ) {
            let err = String.init(turnBackData[0]) // errorCode
            if ( err == "1" ) {
//                throw errorType.IDServerError("IDServer 尚未切換社區")
                throw ErrorCase.IDServerError("IDServer 尚未切換社區")
            }
            else if ( err == "2" ) {
//                throw errorType.IDServerError("IDServer ID類別不支援")
                throw ErrorCase.IDServerError("IDServer ID類別不支援")
            }
            
            // 解析資料
            result = turnBackData.subdata(in: 1..<turnBackData.count) // 資料
        }
        else {
//            throw errorType.IDServerError("連接失敗")
            throw ErrorCase.IDServerError("連接失敗")
        }
        
        return result
    }
}


extension DataAction_KeepAlive { // 資料抓取
    public func fetchData<T:Decodable>(_ command:String, _ testStruct:inout T,_ isArray:Bool, _ times:Int = DataAction_KeepAlive.reSend_times ) -> (String)  { // 抓取資料
        // 回傳 為 錯誤訊息 若正確傳接 則 回傳空字串
        if ( canSend == false ) { // 網路問題
            print("no wifi connection !")
            return "no Wifi"
        }
        else if ( command == "error") { // command 問題
            return "command Error"
        }
        
        let mycommand = "\(UUID),\(communityID)," + command
        var data = Data()
        
        let server = ConnectStack.stacks.getServer(port: Port.testPort.rawValue)
        //print("ID:\(server.getID()) , port:\(server.getPort()) , isLive:\(server.getIsLive())" )
        server.send(mycommand)
        server.sendComplete()
        server.read(&data)
        //print("ID:\(server.getID()) , port:\(server.getPort()) , isLive:\(server.getIsLive())" )
        ConnectStack.stacks.finishUsedServer(server)
        
        if ( server.getIsLive() ) { // 傳接資料都正常
            data = ( isArray == true ) ? turnToArray(data) : data
            let decoder = JSONDecoder()
            
            decoder.dateDecodingStrategy = .iso8601
            do {
                testStruct = try decoder.decode(T.self, from: data)
                return "" // 正常
            } catch {
                
                let decodedString = String(decoding: data as Data, as: UTF8.self)
                if ( decodedString == "" || decodedString == "[]" ) { // 沒資料  正常
                    return ""
                }
                else if ( decodedString.contains("error")){ // error code
                    //print(" Error: ",decodedString)
                    let errorMsg = ( decodedString.last == "]" ? String(decodedString.dropLast(3).suffix(5)) : String(decodedString.dropLast(2).suffix(5)) )
                    return errorMsg //
                }
                else if ( decodedString.contains("connection refuse")) {
                    print("connection refuse!")
                    canSend = false
                    return "connection refuse!"
                }
                else if ( decodedString.contains("timeOut")) {
                    print("command :\(mycommand) is Timeout")
                    return "timeOut!"
                }
                else { // wrong type
                    print("command : \(mycommand)")
                    print(" Error: ",decodedString)
                    print(error)
                    return "wrong type to decode !"
                }
            }
        }
        else { // 不正常
            if ( times != 0 && String(decoding: data as Data, as: UTF8.self) == "timeOut") { // 可能拿掉 再試看看會不會有問題
                return fetchData(command, &testStruct, isArray, times - 1) // 回去再撈一次
            }
            else {
                return String(decoding: data as Data, as: UTF8.self)
            }
           /* if ( String(decoding: data as Data, as: UTF8.self) == "connection error" ) { // 如果是 refuse
                return "connection refuse!" // 連線拒絕 就不重撈了
            }
            else if ( times != 0 ){
                return fetchData(command, &testStruct, isArray, times - 1) // 回去再撈一次
            }
            else {
                return "連線中斷"
            }*/
        }
    } // 抓取資料
    
    
    func resend(command:String? = nil,commandData:Data? = nil , port:Int, data:inout Data) { // 重送專用 先不使用  舊版本
        guard command != nil || commandData != nil else { return }
        
        var decodedString = String(decoding: data as Data, as: UTF8.self)
        var times = 2
        while ( decodedString == "timeOut" && times != 0 ) { // 如果是超時 重撈
            data.removeAll()
            times -= 1
            let server = ConnectStack.stacks.getServer(port: port) // 再要一個連線 ( ps: 如果剛剛的連線超時 會被close 掉  取的時候會把它移除
            server.send(command,commandData)
            server.sendComplete()
            server.read(&data)
            ConnectStack.stacks.finishUsedServer(server)
            if ( data.count != 7 ) { break }
            decodedString = String(decoding: data as Data, as: UTF8.self)
        }
    }
}

extension DataAction_KeepAlive { // 資料更新
    public func updateMoreData(_ commands:[String]) ->(String) { // 更新多個資料
        var server:SocketConnector!
        defer {
            if ( server != nil ) { ConnectStack.stacks.finishUsedServer(server) }
        }
        do {
            if ( canSend == false ) { throw updateErrorType.noWifi }
            // 取得連線
            server = ConnectStack.stacks.getServer(port: Port.testPort.rawValue)
         
            
            // 有連線失敗 就直接關閉 避免 start end 出問題
            var result = sendStart(server) // send Start
            if (result.contains("\"accept\"") == false) {
                // result = server.sendEnd(server)  連start 都不接受 故不需要send end
                throw updateErrorType.startGroup
            }
            
            // command
            for i in 0..<commands.count { // 送出所有command
                let mycommand = "\(UUID),\(communityID)," + commands[i]
                var data = Data()
                server.send(mycommand)
                server.sendComplete()
                server.read(&data)
                result = String(decoding: data as Data, as: UTF8.self)
                if ( !checkCommandIsCorrect(callBackStr:result) ) {
                    throw updateErrorType.command(mycommand)
                }
            }
            
            if ( server.getIsLive() == false ) { // 連線已經不存活 代表中間發生了一些問題
                throw updateErrorType.notConnect // 連線失敗
            }
            
            // successful
            result = sendSuccessful(server) // send Start
            if (result.contains("\"accept\"") == false) {
                // result = server.sendEnd(server)  連start 都不接受 故不需要send end
                throw updateErrorType.successGroup
            }
            
            // end
            result = sendEnd(server) // send end
            if ( result.contains("\"accept\"") ) {
                return result
            }
            else {
                throw updateErrorType.endGroup
            }
        }
        catch updateErrorType.noWifi {
            print("no wifi connection!")
            return "error:no Wifi"
        }
        catch updateErrorType.startGroup { // 不需要送end 因為start 就出錯了
            print("start group error")
            return "error:連線失敗(start)"
        }
        catch updateErrorType.command(let mes) { // 需要送end 因為 start 已經開始了
            print("command error : \(mes)")
            let endResult = sendEnd(server)
            if ( !endResult.contains("\"accept\"") ) { server.close() } // 連end都失敗 直接把連線給砍了
            return "error:連線失敗(command)"
        }
        catch updateErrorType.notConnect {
            print("connect failed!")
            return "error:connect failed"
        }
        catch updateErrorType.successGroup { // 需要送end 因為 start 已經開始了
            print("successful group error")
            let endResult = sendEnd(server)
            if ( !endResult.contains("\"accept\"") ) { server.close() } // 連end都失敗 直接把連線給砍了
            return "error:連線失敗(successful)"
        }
        catch updateErrorType.endGroup { // 全部都成功 但 end 失敗 直接把連線砍掉
            print("end group error")
            server.close()
            return "error:連線失敗(end)"
        }
        catch {
            print("someting error at :\(error)")
            server.close() // 安全起見 在未知錯誤發生時 把連線中斷 讓他重新建立比較安全
            return "error:\(error)"
        }
        /*
        if ( canSend == false ) {
            print("no wifi connection !")
            return "no Wifi"
        }
        
        
        let server = ConnectStack.stacks.getServer(port: Port.resident.rawValue)
        defer {
            ConnectStack.stacks.finishUsedServer(server)
        }
        // 有連線失敗 就直接關閉 避免 start end 出問題
        var result = sendStart(server) // send Start
        if (result.contains("\"accept\"") == false) {
            // result = server.sendEnd(server)  連start 都不接受 故不需要send end
            return "error:連線失敗"
        }
        
        for i in 0..<commands.count { // 送出所有command
            let mycommand = "\(UUID),\(communityID)," + commands[i]
            var data = Data()
            server.send(mycommand)
            server.sendComplete()
            server.read(&data)
            result = String(decoding: data as Data, as: UTF8.self)
            if (result.contains("\"accept\"") == false) {
                result = sendEnd() // 若發生錯誤 會被斷線 故給裡面創建新的 去sendEnd 結束掉group
                return "error:連線失敗"
            }
        }
        
        if ( server.getIsLive() == false ) { // 連線已經不存活 代表中間發生了一些問題
            if ( result.contains("refuse") ) { // 如果是 refuse
                return "error:connection refuse!" // 連線拒絕 就不重撈了
            }
            else if ( times != 0 ){
                return updateMoreData(commands,times - 1) // 重新呼叫一次
            }
            else {
                return "error:connection failed!"
            }
        }
        else {
            result = sendEnd(server) // send end
            if ( result.contains("\"accept\"") ) {
                return result
            }
            else {
                return "error:資料錯誤"
            }
            //return // String(result.replacingOccurrences(of: "\"", with: "").dropLast().dropFirst())
        }*/
        //return testStruct
    } // 更新多個資料
    
    public func updateSingleData(_ command:String) -> (String)  { // 更新單筆資料
        var server:SocketConnector!
        defer {
            if ( server != nil ) { ConnectStack.stacks.finishUsedServer(server) }
        }
        do {
            if ( canSend == false ) { throw updateErrorType.noWifi }
            // 取得連線
            server = ConnectStack.stacks.getServer(port: Port.testPort.rawValue)
         
            
            // 有連線失敗 就直接關閉 避免 start end 出問題
            var result = sendStart(server) // send Start
            if (result.contains("\"accept\"") == false) {
                // result = server.sendEnd(server)  連start 都不接受 故不需要send end
                throw updateErrorType.startGroup
            }
            
            // command
            let mycommand = "\(UUID),\(communityID)," + command
            var data = Data()
            
            server.send(mycommand)
            server.sendComplete()
            server.read(&data)
            result = String(decoding: data as Data, as: UTF8.self)
            if ( !checkCommandIsCorrect(callBackStr: result) ) {
                throw updateErrorType.command(mycommand)
            }
            
            if ( server.getIsLive() == false ) { // 連線已經不存活 代表中間發生了一些問題
                throw updateErrorType.notConnect // 連線失敗
            }
            
            // successful
            result = sendSuccessful(server) // send Start
            if (result.contains("\"accept\"") == false) {
                // result = server.sendEnd(server)  連start 都不接受 故不需要send end
                throw updateErrorType.successGroup
            }
            
            // end
            result = sendEnd(server) // send end
            if ( result.contains("\"accept\"") ) {
                return result
            }
            else {
                throw updateErrorType.endGroup
            }
        }
        catch updateErrorType.noWifi {
            print("no wifi connection!")
            return "error:no Wifi"
        }
        catch updateErrorType.startGroup { // 不需要送end 因為start 就出錯了
            print("start group error")
            return "error:連線失敗(start)"
        }
        catch updateErrorType.command(let mes) { // 需要送end 因為 start 已經開始了
            print("command error : \(mes)")
            let endResult = sendEnd(server)
            if ( !endResult.contains("\"accept\"") ) { server.close() } // 連end都失敗 直接把連線給砍了
            return "error:連線失敗(command)"
        }
        catch updateErrorType.notConnect {
            print("connect failed")
            return "error:connect failed"
        }
        catch updateErrorType.successGroup { // 需要送end 因為 start 已經開始了
            print("successful group error")
            let endResult = sendEnd(server)
            if ( !endResult.contains("\"accept\"") ) { server.close() } // 連end都失敗 直接把連線給砍了
            return "error:連線失敗(successful)"
        }
        catch updateErrorType.endGroup { // 全部都成功 但 end 失敗 直接把連線砍掉
            print("end group error")
            server.close()
            return "error:連線失敗(end)"
        }
        catch {
            print("someting error at :\(error)")
            server.close() // 安全起見 在未知錯誤發生時 把連線中斷 讓他重新建立比較安全
            return "error:\(error)"
        }
        
        /*if ( canSend == false  ) {
            print("no wifi connection !")
            return "no Wifi"
        }
        
        let server = ConnectStack.stacks.getServer(port: Port.resident.rawValue)
        defer {
            ConnectStack.stacks.finishUsedServer(server)
        }
        
        var result = sendStart(server)
        if (result.contains("\"accept\"") == false) {
            // start 都沒接受 不送end了
            // result = server.sendEnd(server)
            return "error:連線失敗"
        }
        
        let mycommand = "\(UUID),\(communityID)," + command
        var data = Data()
        
        server.send(mycommand)
        server.sendComplete()
        server.read(&data)
        result = String(decoding: data as Data, as: UTF8.self)
        if (result.contains("\"accept\"") == false) {
            // 中間錯誤  直接送回end
            result = sendEnd(server) // 因為server 已經被斷線了 故 不使用原先的連線 進入後創建一個sendEnd
            return "error:連線失敗"
        }
        
        if ( server.getIsLive() == false ) { // 連線已經不存活 代表中間發生了一些問題
            if ( String(decoding: data as Data, as: UTF8.self).contains("refuse") ) { // 如果是 refuse
                return "error:connection refuse!" // 連線拒絕 就不重撈了
            }
            else if ( times != 0 ){
                return updateSingleData(command,times - 1) // 重新呼叫一次
            }
            else {
                return "error:connection failed!"
            }
        }
        else {
            result = sendSuccessful(server) // success Group
            if (result.contains("\"accept\"") == false) {
                _ = sendEnd(server) // 因為server 已經被斷線了 故 不使用原先的連線 進入後創建一個sendEnd
                return "error:連線失敗"
            }
            
            result = sendEnd(server) // end Group
            if (result.contains("\"accept\"") == false) {
                return "error:連線失敗"
            }
            else {
                return String(result.replacingOccurrences(of: "\"", with: "").dropLast().dropFirst())
            }
        }*/
        //return testStruct
    }  // 更新單筆資料
    
    private func sendStart(_ server:SocketConnector)->String { // start group
        server.send("""
        \(UUID),\(communityID),{"group":"start"}
        """)
        var data = Data()
        server.sendComplete()
        server.read(&data)
        let mes : String = (NSString(data: data, encoding: String.Encoding.utf8.rawValue) ?? "") as String
        return mes
    }
    
    private func sendSuccessful(_ server:SocketConnector)->String {
        if ( !server.getIsLive() ) { return "accept" } // 不明原因已經斷線了 直接返回就好
        
        server.send("""
        \(UUID),\(communityID),{"group":"successful"}
        """)
        var data = Data()
        server.sendComplete()
        server.read(&data)
        let mes : String = (NSString(data: data, encoding: String.Encoding.utf8.rawValue) ?? "") as String
        return mes
    }
    
    private func sendEnd(_ server:SocketConnector)->String { // end 有可能斷線後才進 ( 中間出錯 ) 故有機會被disconnect 要特別判斷
        if ( server.getIsLive() == false ) { return "accept" }  // 如果某些問題導致斷線了 則不需要送end

        server.send("""
        \(UUID),\(communityID),{"group":"end"}
        """)
        var data = Data()
        server.sendComplete()
        server.read(&data)
        
        let mes : String = (NSString(data: data, encoding: String.Encoding.utf8.rawValue) ?? "") as String
        return mes
    }
    
    private func checkCommandIsCorrect( callBackStr:String)->Bool {
        do {
            let json_dict = try callBackStr.jsonToDictionary()
            if ( json_dict["PK"] != nil && json_dict["className"] != nil && json_dict["affectedRows"] != nil ) {
                return true
            }
        }
        catch {
            print(error)
        }
        return false
    }
}

extension DataAction_KeepAlive { // 資料解析
    public func turnToArray(_ data:Data)->Data { // 將資料轉乘陣列
        var mystring : String = (NSString(data: data, encoding: String.Encoding.utf8.rawValue) ?? "") as String
        mystring = mystring.trimmingCharacters(in: .whitespaces )
        if ( !mystring.hasPrefix("[")) {
            mystring = "[" + mystring
        }
        
        if ( !mystring.hasSuffix("]")) {
            mystring += "]"
        }
        
        let data = Data(mystring.utf8)
        return data
    } // 將資料轉乘陣列
    
    public func parsingStruct<T>(SingleStruct:T? = nil , StructArray:[T]? = nil, updateOrAdd:ActionType , typeValue:String = "")->String { // 將物件 寫成 json 字串
        // updateOradd  ->  true update  , false add
        func parsing<T>(SingleStruct:T? = nil , typeValue:String = "")->String {
            var ansStr = ""
            var valueTypeArr = [String]()//紀錄每個變數的type(類型)
            let mirror = Mirror(reflecting: SingleStruct!)
            var counter = 0
            for property in mirror.children { // 取得屬性
                var valueType = "\(type(of: property.value))"
                valueType = valueType.replacingOccurrences(of: "Optional", with: "").replacingOccurrences(of: "Array", with: "").replacingOccurrences(of: "<", with: "").replacingOccurrences(of: ">", with: "")
                // 去除掉optional , array , < , >
                valueTypeArr.append(valueType)
            }//valueTypeArr裝載中
            
            
            for property in mirror.children {
                let proV = property.value // 這個標籤的屬性
                if counter == 0 { ansStr += "{\"className\":\"\(typeValue)\","} // className
                //--------------------------------------------------------
                if proV as? [Any] != nil { // 若是陣列
                    let proVType = "<" + valueTypeArr[counter] + ">"
                    /* var proVType = "\(type(of: proV))"
                     proVType = proVType.replacingOccurrences(of: "Optional", with: "").replacingOccurrences(of: "Array", with: "").replacingOccurrences(of: "<", with: "").replacingOccurrences(of: ">", with: "") // array 拔掉
                     proVType =  "<" + proVType + ">"*/
                    if proVType == "<Int>" || proVType == "<Float>" || proVType == "<String>" || proVType == "<Bool>" || proVType == "<Double>" { // 判斷他的屬性
                        var tmp_result = ""
                        ansStr += "\"\(property.label!)\":["
                        
                        for item in proV as! [Any] {
                            tmp_result += (proVType == "<Int>" || proVType == "<Float>" || proVType == "<Bool>" || proVType == "<Double>") ? "\(item)," : "\"\(item)\","
                        }
                        tmp_result = String(tmp_result.dropLast(1)) // 去掉最後","
                        ansStr += "\(tmp_result)]," // 陣列結束
                        if counter == mirror.children.count - 1 { ansStr = String(ansStr.dropLast(1)) } // 若是最後一個label 就把最後,去除
                        
                    } else { // 自定義屬性
                        let tmp_result = parsingStruct(StructArray:proV as? [Any], updateOrAdd: updateOrAdd,typeValue: valueTypeArr[counter]) // 遞迴呼叫讓他去解析這個字定義型別底下的屬性
                        
                        ansStr += "\"\(property.label!)\":\(tmp_result)," // 遞迴回來會是一個陣列"[自定義屬性,自定義屬性 ....]"  直接放入
                        if counter == mirror.children.count - 1 {  // 若是最後一個label 就把最後,去除
                            ansStr = String(ansStr.dropLast(1))
                        }  // 若是最後一個label 就把最後,去除
                    }
                } else { // 不是陣列 單筆
                    
                    let proVType = valueTypeArr[counter] // 取得 type
                    //print("proVType:\(valueTypeArr[counter])")
                    if updateOrAdd == .Add { // true -> update  false -> add
                        // add
                        if property.label! != "PK" &&  "\(proV)" != "nil"{ // 只要type 不是pk 就加入
                            ansStr += "\"\(property.label!)\":"
                        } // 只要type 不是pk 就加入
                    }
                    else {
                        // update
                        if "\(proV)" != "nil" { // 只要值不是null 就加入
                            ansStr += "\"\(property.label!)\":"
                        } // 只要type 不是pk 就加入
                    }
                    
                    if proVType != "Int" && proVType != "Float" && proVType != "String" && proVType != "Bool" && proVType != "Double" { // 自定義的單筆資訊
                        var tmp_result = parsingStruct(SingleStruct:proV, updateOrAdd: updateOrAdd, typeValue: proVType) // 遞迴回去
                        
                        //啟用畸形補救辦法
                        if tmp_result.contains("some") { // 將some 拔掉
                            let str = "\"className\":\"\(proVType)\",\"some\":{"
                            tmp_result = String(tmp_result.replacingOccurrences(of: str , with: "").dropLast(1))//"}"
                            //                            tmp_result:{"className":"howx","some":{"className":"howx","xx":3}}
                            //                            tmp_result:{"className":"howx","xx":3}
                        } // 將some 拔掉
                        //啟用畸形補救辦法over
                        
                        //print("tmp_result:\(tmp_result)")
                        ansStr += "\(tmp_result),"
                        
                    }
                    else { // 自定義的單筆資訊
                        //rm_optVal : remove optional value
                        let rm_optVal = "\(proV)".replacingOccurrences(of: "Optional(\"", with: "").replacingOccurrences(of: "\")", with: "")
                        
                        if ( updateOrAdd == .Add ) {
                            // add
                            if property.label! != "PK" && "\(proV)" != "nil" {
                                ansStr += (proVType == "Int" || proVType == "Float" || proVType == "Bool" || proVType == "Double") ? "\(rm_optVal)," : "\"\(rm_optVal)\"," // 判斷是否是字串 決定command要不要加 ""
                            }
                        }
                        else {
                            // update
                            if "\(proV)" != "nil" {
                                ansStr += (proVType == "Int" || proVType == "Float" || proVType == "Bool" || proVType == "Double") ? "\(rm_optVal)," : "\"\(rm_optVal)\"," // 判斷是否是字串 決定command要不要加 ""
                            }
                        } // update
                    } // 自定義的單筆資訊
                    
                    if counter == mirror.children.count - 1 { ansStr = String(ansStr.dropLast(1)) } // 若是最後一個。把最後","去掉
                }
                //--------------------------------------------------------
                if counter == mirror.children.count - 1 { ansStr += "}," } // 若是最後一個 加入最後的},
                counter += 1
            }//for property in mirror.children
            return ansStr
        }
        

        var FinAnswer = ""
        var Ttype = ""
        if SingleStruct != nil {  // 是單筆資訊
            Ttype = "\(T.self)"
            if Ttype == "Any" { // 因後續不知道struct 類別 故後續都進入此條件
                FinAnswer = String(parsing(SingleStruct:SingleStruct,typeValue:typeValue).dropLast(1))/* , */
            }else{ // first times
                FinAnswer = String(parsing(SingleStruct:SingleStruct,typeValue: Ttype ).dropLast(1))/* , */
            }
            return FinAnswer // 去掉最後一個","
        } else { // 是陣列
            Ttype = "\(T.self)"
            if Ttype == "Any" { // 因後續不知道struct 類別 故後續都進入此條件
                for ele in StructArray! { FinAnswer += parsing(SingleStruct:ele ,typeValue: typeValue) } // 遍歷總共有多少數量
            }else{ // first times
                for ele in StructArray! { FinAnswer += parsing(SingleStruct:ele, typeValue: Ttype ) } // 遍歷總共有多少數量
            }
            FinAnswer = "[" + String(FinAnswer.dropLast(1))/* , */ + "]" // 將最後的","去除掉
            return FinAnswer
        }
        
    } // 將物件 寫成 json 字串
}
