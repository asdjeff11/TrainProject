//
//  ReactiveViewModel.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/6.
//

import Foundation

class ReactiveViewModel {
    deinit {
        subscription = nil
    }
    var subscription:MySubscription?
    func userPressButton(url:URL) {
        // 原理介紹
        // 只要呼叫 subcribe 就會開始執行動作
        // 1.建立一個 Publisher 設定好 subscribe被呼叫後的動作 (這裡還沒確定做完後要幹嘛)
        // 2.用此 Pub.map 在建立一個Publishsher 設定好 subscribe被呼叫的動作 (這裡還沒確定做完後要幹嘛)
        // 3.呼叫 第二個 publisher.subscribe 告知他你做完後做我指定的事情(這裡是打印長度)
        // 4.第二個pub.sub 開始執行動作 ( 裡面第一步就是呼叫 第一個Publisher 的 subscribe , 並告知他做完之後做什麼 在這裡是 data => str )
        // 5.開始執行 第一個publisher 的 subscribe( url => data) , 做完後 做第二個 pub的動作 ( data => str )
        // 6.做完後, 最後執行最後一層的動作 ( 打印長度 )
        
        // 一訂閱 訂開始運作
        
        subscription =
        URLSession.shared
            .dataTaskPublisher(with: url) // 1. 發布者：Combine 中的建造者。  主要在建構 ( subscribe 在撈資料 )
            .map{ String(data: $0, encoding: .utf8) } // 2. 操作者：Combine 中的建構資訊。  主要在對資料進行加工 ( publisher 的 map 在 創建一個新的 publisher 將 上個 publisher 的資料進行加工 ) 
            .subscribe { str in // 3. 訂閱者：Combine 中的 build()  主要在顯示 加工後的資訊
                print(str?.count ?? 0 )
            }
    }
}
