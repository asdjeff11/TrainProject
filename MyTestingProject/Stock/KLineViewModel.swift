//
//  KLineViewModel.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/15.
//

import Foundation

class KLineViewModel:ViewModelActivity {
    enum TypeError:Error {
        case toURLError
        case dataError
        case toJSonStringError
        case responseError
    }
    
    var stockKLine_Dict:[String:[StockKLine]] = [:] // Date -> [StockKLine]
    var tradingInfo_Dict:[String:[MarketTradingInfo]] = [:] // Date -> [MarketTradingInfo]
    let keyDateFormat = Theme.customFormatter(dateType: "yyyyMM") // 放入Dict規則
    
    
    // offset = 要撈多少個月以前的資料 ( 含本月 )
    @Sendable func getMoreMonth(startDate:Date, offset:Int) async throws-> ([StockKLine],[MarketTradingInfo]) { // Get stockLine of more date
        taskID = beginBackgroundUpdateTask()
        let semaphore = DispatchSemaphore(value: 1)
       
        let stockLines = try await withThrowingTaskGroup(of: [StockKLine].self, body:{ group in
            for temp in 0..<offset {
                let date = startDate.getOffsetDay(type: .month, offset: -temp)
                group.addTask(priority: .background) {
                    let list = try await self.getDateData(date: date)
                    let key = self.keyDateFormat.string(from: date)
                    semaphore.wait()
                    self.stockKLine_Dict[key] = list
                    semaphore.signal()
                
                    return list
                }
            }
            
            var totalList = [StockKLine]()
            for try await result in group {
                totalList.append(contentsOf: result)
            }
            return totalList.compactMap({$0}).sorted(by: { $0.dateString < $1.dateString})
        })
        
        let marketTradingInfos = try await withThrowingTaskGroup(of: [MarketTradingInfo].self, body: { group in
            for temp in 0..<offset {
                let date = startDate.getOffsetDay(type: .month, offset: -temp)
                group.addTask(priority: .background) {
                    let list = try await self.getTradingInfoData(date: date)
                    let key = self.keyDateFormat.string(from: date)
                    semaphore.wait()
                    self.tradingInfo_Dict[key] = list
                    semaphore.signal()
                
                    return list
                }
            }
            
            var totalList = [MarketTradingInfo]()
            for try await result in group {
                totalList.append(contentsOf: result)
            }
            return totalList.compactMap({$0}).sorted(by: { $0.date < $1.date})
        })
        
        endBackgroundUpdateTask(taskID: &taskID)
        return (stockLines,marketTradingInfos)
    }
    
    @Sendable func getDateData(date:Date) async throws -> [StockKLine] { // Get stockKLine of one date
        let key = self.keyDateFormat.string(from: date)
        if let list = stockKLine_Dict[key] {
            return list
        }
        
        let result = await requestStockKLine(date:date)
        
        switch ( result ) {
        case .success(let data_list) :
            return data_list
        case .failure(let error) :
            throw error
        }
    }
    
    func requestStockKLine(date:Date) async -> (Result<[StockKLine],Error>) { // Restful API get Data
        let formate = Theme.customFormatter(dateType: "yyyyMMdd")
        let myDate = formate.string(from: date)
        
        let urlStr = "https://www.twse.com.tw/en/indicesReport/MI_5MINS_HIST?response=csv&date=\(myDate)"
        guard let url = URL(string: urlStr) else { return .failure(TypeError.toURLError)}
            
        guard let (data,response) = try? await URLSession.shared.data(from:url),
              let response = response as? HTTPURLResponse,
              (200...299).contains(response.statusCode) else { return .failure(TypeError.responseError) }
        do {
            let kLine_List = try strToKLineList(data)
            return .success(kLine_List)
        }
        catch {
            return .failure(TypeError.dataError)
        }
        
    }
    
    func strToKLineList(_ data:Data) throws -> [StockKLine] { // csv data -> [StockKLine]
        var kLine = [StockKLine]()
        guard let str = data.string , !str.isEmpty else { throw TypeError.dataError }
        let KLineDataArray = str.components(separatedBy: "\r\n").dropFirst(2) // 移除前兩個 因為前兩個為標題 與屬性名稱 ...
        for KLineData in KLineDataArray {
            if ( KLineData.isEmpty ) { break }
            
            let KLineData_List = KLineData.dropLast(2).dropFirst().components(separatedBy: "\",\"") // 去掉最後一個 ","
            // 0:日期 , 1:開盤 , 2:峰值 , 3:最低價 , 4:收盤價
            guard KLineData_List.count == 5 ,
                  let open = Double(KLineData_List[1].replacingOccurrences(of: ",", with: "")) ,
                  let highest = Double(KLineData_List[2].replacingOccurrences(of: ",", with: "")) ,
                  let lowest = Double(KLineData_List[3].replacingOccurrences(of: ",", with: "")) ,
                  let close = Double(KLineData_List[4].replacingOccurrences(of: ",", with: ""))
            else {
                throw TypeError.dataError
            }
          
            kLine.append(StockKLine(stockCode: "Taiex",
                                    stockName: "台股加權指數",
                                    dateString: KLineData_List[0],
                                    open: open,
                                    highest: highest,
                                    lowest: lowest,
                                    close: close ))
        }
        
        return kLine
    }
    
    
    private func getTradingInfoData(date:Date) async throws -> [MarketTradingInfo] { // Get stockKLine of one date
        let key = self.keyDateFormat.string(from: date)
        if let list = tradingInfo_Dict[key] {
            return list
        }
        
        let result = await requestTradingInfo(date:date)
        
        switch ( result ) {
        case .success(let data_list) :
            return data_list
        case .failure(let error) :
            throw error
        }
    }
    
    @Sendable func requestTradingInfo(date:Date) async -> (Result<[MarketTradingInfo],Error>) {
        let formate = Theme.customFormatter(dateType: "yyyyMMdd")
        let myDate = formate.string(from: date)
        
        let urlStr = "https://www.twse.com.tw/en/exchangeReport/FMTQIK?response=csv&date=\(myDate)"
        guard let url = URL(string: urlStr) else { return .failure(TypeError.toURLError)}
            
        guard let (data,response) = try? await URLSession.shared.data(from:url),
              let response = response as? HTTPURLResponse,
              (200...299).contains(response.statusCode) else { return .failure(TypeError.responseError) }
        do {
            let kLine_List = try strToTradingInfoList(data)
            return .success(kLine_List)
        }
        catch {
            return .failure(TypeError.dataError)
        }
    }
    
    func strToTradingInfoList(_ data:Data) throws -> [MarketTradingInfo] { // csv data -> [MarketTradingInfo]
        var marketTrading = [MarketTradingInfo]()
        guard let str = data.string , !str.isEmpty else { throw TypeError.dataError }
        let tradingDataArray = str.components(separatedBy: "\r\n").dropFirst(2) // 移除前兩個 因為前兩個為標題 與屬性名稱 , 最後一個為備註
        for tradingData in tradingDataArray {
            if ( tradingData.isEmpty ) { break }
            
            let trading_List = tradingData.dropLast(2).dropFirst().components(separatedBy: "\",\"") // 去掉最後一個 ","
            // 0:日期 , 1:成交股數 , 2:成交金額 , 3:成交筆數 , 4:發行量加權股價指數 , 5: 漲跌點數
            if trading_List.count == 6 ,
                  let trade_vol = Double(trading_List[1].replacingOccurrences(of: ",", with: "")) ,
                  let trade_value = Double(trading_List[2].replacingOccurrences(of: ",", with: "")) ,
                  let transaction = Double(trading_List[3].replacingOccurrences(of: ",", with: "")) ,
                  let taiex = Double(trading_List[4].replacingOccurrences(of: ",", with: "")) ,
               let change = Double(trading_List[5].replacingOccurrences(of: ",", with: "")) {
                
                marketTrading.append(MarketTradingInfo(date: trading_List[0],
                                                       tradeVolume: trade_vol,
                                                       tradeValue: trade_value,
                                                       transaction: transaction,
                                                       taiex: taiex,
                                                       change: change))
            }
        }
        
        return marketTrading
    }
    
}
