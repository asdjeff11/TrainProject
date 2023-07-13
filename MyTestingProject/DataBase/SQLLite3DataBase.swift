//
//  SQLLite3DataBase.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/7.
//

import Foundation
import SQLite3

let db = MyDataBase()

class MyDataBase {
    private var db : OpaquePointer? // database
    private var path:String = "myDataBase.sqlite" // 檔案名稱
    private let userDefault = UserDefaults() // 儲存 vacuum的日期 & database 版本 ( 儲存在此地方的資料容易被外界竊取 故這裡只能使用沒那麼重要性的資訊)
    private var semphore = DispatchSemaphore(value: 1) // 同步鎖 防止競爭搶奪資源
    
    init()  { //
        self.db = self.createDB() // 建立資料庫
        // 建立 table
        _ = executeQuery(query: UserData.createTable())
        _ = executeQuery(query: FavoritePlace.createTable())
        _ = executeQuery(query: ImageStore.createTable())
        
        // 移除掉過舊的資訊
        deleteTooOldData()
        // 檢查版本更新
        self.upgradeTable()
        
        // 每日 資料重組 清除資料空間
        let now = Theme.onlyDateDashFormatter.string(from: Date())
        if let recordDate = userDefault.value(forKey: "VacuumDate") as? String {
            if ( recordDate != now ) {
                vacuum()
                userDefault.setValue(now, forKey: "VacuumDate")
            }
        }
        else {
            vacuum()
            userDefault.setValue(now, forKey: "VacuumDate")
        }
    }
    
    func vacuum() { // 清除 所有被刪掉的空白空間  降低app空間
        // 執行此需要2倍的空間數量 , 且使用會耗能
        // 故在使用此為 1天1次 清除不必要空間 ( 因為清除資料通常依日期為單位 )
        if sqlite3_exec(db, "VACUUM;", nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("VACUUM error:\(errmsg)")
        }
    }
    
    func upgradeTable() {
        var version = ""
        // 檢查是否版本不同
        if let currentUserInstallVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String { // 取得 app 版本
            version = currentUserInstallVersion
            if let recordVersion = userDefault.value(forKey: "DatabaseVersion") as? String {
                let recordV = recordVersion.prefix(recordVersion.positionOf(sub: ".",backwards: true))
                let currentV = currentUserInstallVersion.prefix(currentUserInstallVersion.positionOf(sub:".",backwards: true) )
                
                if ( recordV == currentV ) { return } // 版本相同 直接返回
                
            }
            else {  // 還沒有任何database版本
                userDefault.set( version, forKey: "DatabaseVersion")
                return
            }
        }
      
        // 更新版本
        func updateData<T:MyDataBaseStructer>( object:T.Type ) {
            var lists:[T] = read2Object(query: "SELECT * FROM \(object.tableName) limit 1;") // 先抓一筆 只是先拿來判斷是否結構更動 , 真的有更動資訊在全撈 , 為了面對大數量資訊 ex一大堆圖片
            // read2Object 只會依照現在結構 取得資訊 , db有該屬性 , 但結構沒有 , 該屬性會被忽略
            // 故不能用 read2Object判斷 column , 使用 read2JsonDict 轉乘dict 判斷該dict的長度 則為 db結構中 column的數量
            var columnSize = 0
            do {
                let dict:[[String:Any]] = try read2JsonDict(query: "SELECT * FROM \(object.tableName) limit 1;") // 取1筆就好 只是要知道column 而已
                if ( dict.count > 0 ) { columnSize = dict[0].count } // 如果都沒資料 在底下也會重建table , 在有資料情況下 才去 column 是否有屬性被移除
            }
            catch {
                print(error.localizedDescription)
            }
            if ( lists.isEmpty || // 沒資料
                 (columnSize != 0 && columnSize != T.getColumnSize() ) || // db column size != new column size (屬性在此版被刪除 or 此版新增屬性)
                 lists[0].checkStructorIsUpdate() // 抓到資料長相不一致  針對 修改column名稱
               ) { // 確定要更改結構
                // 撈取全部資訊
                lists = read2Object(query: "SELECT * FROM \(object.tableName) ;")
                
                // drop table
                dropTable(tableName: "\(object.tableName)")
                // creat table
                if ( !executeQuery(query: T.createTable())) { print( "create table \(T.tableName) is failed. query:\(T.createTable())") }
                // insert Data
                for item in lists {
                    if ( !update(object: item)) { print("insert old data is failed. query:\(item.getUpdateQuery())")}
                }
            } // if
        } // func
        
        // 更新全部的 table
        updateData(object: UserData.self)
        updateData(object: FavoritePlace.self)
        updateData(object: ImageStore.self)
        // 更新版本
        userDefault.set( version, forKey: "DatabaseVersion")
    }
    

    func dropTable(tableName:String) { // 移除table
        var statement:OpaquePointer?
        let query = "DROP TABLE \(tableName);" as NSString
        defer {
            semphore.signal()
        }
        semphore.wait()
        if ( sqlite3_prepare_v2(self.db, query.utf8String, -1, &statement, nil) == SQLITE_OK ) {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Data delete Success!")
            }
            else {
                print("Data is not deleted in table!")
            }
            sqlite3_finalize(statement)
        }
        else {
            print("Query is not as per requirement")
        }
        
    } // 移除table
   
    func createDB()-> OpaquePointer? { // 建立 database
        // 若該路徑 沒有該檔案  系統會嘗試建立此檔案
        // 若該路徑 已經有檔案 單純連接database
        let mypath = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
        ).first! // 取得儲存路徑
        var db: OpaquePointer? = nil // 資料庫
        let dbStatus = sqlite3_open("\(mypath)/\(path)", &db) // 連接資料庫
        
        //print("\(mypath)/\(path)")
        if ( dbStatus != SQLITE_OK) { // 連接失敗
            print("error to create Database. Error Code:\(dbStatus)")
            return nil
        }
        else { // 連接成功
            //print("creating Database with path \(path)")
            return db
        }
    }
    
    func deleteTooOldData() {
        let deadline = threeMonthDate()
        let dQueries:[String] = [
            "DELETE FROM ImageStore WHERE lastUsed < '\(deadline)' ;"
            ]
        // 刪除圖片
        let imgQuery = "SELECT * FROM ImageStore WHERE lastUsed < '\(deadline)' ;"
        let imgs:[ImageStore] = read2Object(query: imgQuery)
        for img in imgs {
            imgDict.removeImageInFileManager(url: img.url)
        }
        
        
        for query in dQueries {
            if ( !executeQuery(query: query) ) {
                print ( "delete is failed on query :\(query)")
            }
        }
    }
    
    func executeQuery(query:String , isLock:Bool = false)->Bool {
        defer {
            if ( !isLock ) { semphore.signal() }
        }
        
        if ( isLock == false ) {
            semphore.wait()
        }
        
        var result = false
        var statement:OpaquePointer?
        let q = query as NSString
        let com = String(query.prefix(query.positionOf(sub: " ")))
        
        if ( sqlite3_prepare_v2(self.db, q.utf8String, -1, &statement, nil) == SQLITE_OK ) { // 傳遞創建刪除 的command 給 database
            if sqlite3_step(statement) == SQLITE_DONE {  // 完成
                //print("\(com) Success!")
                result = true
            }
            else {
                print( "\(com) is not Success! query:\(q)")
            }
            sqlite3_finalize(statement)
        }
        else {  // 傳遞command 失敗
            print( "Query is not as per requirement! query:\(q)")
        }
        
        return result
    }
    
    func update(object:MyDataBaseStructer)->Bool {
        executeQuery(query: object.getUpdateQuery())
    }
    
    private func threeMonthDate()->String { // 現在開始往回推三個月
//        let date = Date() - 7776000
        let date = Date().getOffsetDay(type: .month, offset: -3)
        return Theme.onlyDateDashFormatter.string(from: date)
    } // 現在開始往回推三個月
    
   
    func close() {
        sqlite3_close(db)
    }
   
    func read2Object<T:Codable>(query:String) -> [T] { // 下query 去取得物件資訊
        defer {
            semphore.signal()
        }
        semphore.wait()
        
        let jsonString = sqliteToJsonString(query:query)
        guard !jsonString.isEmpty ,
              let data = jsonString.data(using: .utf8)
        else { return [] }
        
        let decoder = JSONDecoder()
        do {
            var arr:[T] = []
            if ( jsonString.hasPrefix("[") ) {
                arr = try decoder.decode([T].self, from: data)
            }
            else {
                let item = try decoder.decode(T.self, from: data)
                arr = [item]
            }
            
            if let arr = arr as? [ImageStore] , arr.isEmpty == false { // 如果是 imageStore 才有更新使用時間
                let now = Theme.onlyDateDashFormatter.string(from: Date())
                if ( arr[0].lastUsed != now ) {
                    // 更新上次使用時間
                    let updateQ = "UPDATE ImageStore SET lastUsed = '\(now)' WHERE url =  \"\(arr[0].url)\" ; "
                    if ( !executeQuery(query: updateQ,isLock: true) ) { print("update last used faild on \(arr[0].url) . file:SQLLite3Database.")}
                } // if 上次使用日期 與 現在不同
            } // 如果是 imageStore 才有更新使用時間
            
            return arr
        }
        catch {
            print(error.localizedDescription)
        }
        return []
    }
    
    
    private func sqliteToJsonString(query:String) ->String { // sqlite data => jsonString
        var statement:OpaquePointer?
        var jsonString = ""
        if ( sqlite3_prepare_v2(self.db, query, -1, &statement,nil) == SQLITE_OK ) {
            var count = 0
            while sqlite3_step(statement) == SQLITE_ROW {
                jsonString = "\(jsonString){"
                let col_count = sqlite3_column_count(statement)
                for i in 0..<col_count {
                    let name = String(describing: String(cString:sqlite3_column_origin_name(statement, i)))
                    var data = ""
                    let type = sqlite3_column_type(statement, i)
                    switch (type) {
                    case SQLITE_TEXT :
                        data = "\"\(String(describing: String(cString: sqlite3_column_text(statement, i))))\""
                    case SQLITE_INTEGER :
                        data = String(describing: sqlite3_column_int(statement, i))
                    case SQLITE_FLOAT :
                        data = String(describing: sqlite3_column_double(statement, i))
                    default : // 類別有誤 直接跳過該類別
                        continue
                    }
                    
                    jsonString += "\"\(name)\":\(data),"
                }
                
                jsonString = String(jsonString.dropLast()) + "}," // 去掉最後的 ,
                count += 1
            }
            
            if ( count > 1 ) {
                jsonString = "[" + String(jsonString.dropLast()) + "]"
            }
            else {
                jsonString = String(jsonString.dropLast())
            }
        }
        return jsonString
    }
    
    public func read2JsonDict(query:String) throws ->[[String:Any]] { // 下query 取得 dictionary 資訊 (需要單一資訊時使用)
        defer {
            semphore.signal()
        }
        semphore.wait()
        
        return try sqliteToJsonArray(query: query).map { json in
            return try json.jsonToDictionary()
        }
    }
    
    private func sqliteToJsonArray(query:String) -> [String] { // sqlite data => [jsonDictionary]
        var statement:OpaquePointer?
        var jsonArray = [String]()
        if ( sqlite3_prepare_v2(self.db, query, -1, &statement,nil) == SQLITE_OK ) {
            while sqlite3_step(statement) == SQLITE_ROW {
                var jsonString = "{"
                let col_count = sqlite3_column_count(statement)
                for i in 0..<col_count {
                    let name = String(describing: String(cString:sqlite3_column_origin_name(statement, i)))
                    var data = ""
                    let type = sqlite3_column_type(statement, i)
                    switch (type) {
                    case SQLITE_TEXT :
                        data = "\"\(String(describing: String(cString: sqlite3_column_text(statement, i))))\""
                    case SQLITE_INTEGER :
                        data = String(describing: sqlite3_column_int(statement, i))
                    case SQLITE_FLOAT :
                        data = String(describing: sqlite3_column_double(statement, i))
                    default : // 類別有誤 直接跳過該類別
                        continue
                    }
                    
                    jsonString += "\"\(name)\":\(data),"
                }
                
                jsonString = String(jsonString.dropLast()) + "}" // 去掉最後的 ,
                
                jsonArray.append(jsonString)
            }
        }
        return jsonArray
    }
}
