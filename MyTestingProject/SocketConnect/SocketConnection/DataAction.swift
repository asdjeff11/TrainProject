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

    
    private var canSend:Bool = false // 控制是否開啟網路
    init() {
        canSend = true
    }
}

extension DataAction_KeepAlive {
    public func setStatus(_ status:Bool) {
        canSend = status
    }
    
    public func getStatus()->Bool {
        return canSend
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
        
        var data = Data()
        
        let server = ConnectStack.stacks.getServer(port: Port.testPort.rawValue)
        //print("ID:\(server.getID()) , port:\(server.getPort()) , isLive:\(server.getIsLive())" )
        server.send(command)
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
                    print("command :\(command) is Timeout")
                    return "timeOut!"
                }
                else { // wrong type
                    print("command : \(command)")
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
            var result = ""
            // command
            for i in 0..<commands.count { // 送出所有command
                var data = Data()
                server.send(commands[i])
                server.sendComplete()
                server.read(&data)
                result = String(decoding: data as Data, as: UTF8.self)
                if ( !checkCommandIsCorrect(callBackStr:result) ) {
                    throw updateErrorType.command(commands[i])
                }
            }
            return result
        }
        catch updateErrorType.noWifi {
            print("no wifi connection!")
            return "error:no Wifi"
        }
        catch updateErrorType.command(let mes) { // 需要送end 因為 start 已經開始了
            print("command error : \(mes)")
            return "error:連線失敗(command)"
        }
        catch {
            print("someting error at :\(error)")
            server.close() // 安全起見 在未知錯誤發生時 把連線中斷 讓他重新建立比較安全
            return "error:\(error)"
        }
       
    } // 更新多個資料

    private func checkCommandIsCorrect( callBackStr:String)->Bool {
        do {
            let json_dict = try callBackStr.jsonToDictionary()
            // check some reponse data is correct
            // if (json_dict["key"] == ...) ...
            return true
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
