//
//  ReactiveModel.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/6.
//

import Foundation
class MySubscription {
    let cancel: () -> Void
    init(cancel: @escaping () -> Void) {
        self.cancel = cancel
    }
    deinit {
        cancel()
    }
}

struct MyPublisher<Value> {
    let subscribe: (@escaping (Value) -> Void) -> MySubscription
    //let subscribe2: (@escaping (Value) -> Void) -> Subscription
}

extension MyPublisher {
    func map<NewValue>(_ transform: @escaping (Value) -> NewValue) -> MyPublisher<NewValue> {
        return MyPublisher<NewValue>(subscribe:{ newValueHandler in // 創建第二個 Publisher 主要在加工資料 str->Void
            return self.subscribe { value in // 呼叫第一個 Publisher.subscribe 後 執行task  , value = Data
                // 將 value 進行加工(transform 邏輯在外面)
                let newValue = transform(value) // 呼叫外部傳進來的 closure{ data->String }
                newValueHandler(newValue) // 呼叫外部  第一個 Publisher subscribe 的 completion  打印的 closure
            }
        })
    }
}


extension URLSession {
    func dataTaskPublisher(with url: URL) -> MyPublisher<Data> {
        return MyPublisher<Data>(subscribe: { valueHandler in // 設定 subscribe ( valueHandler = subscribe的closure = map.subscribe的 completion(26行~28行)
            // map.subscribe 後執行
            let task = self.dataTask(with: url) { data, response, error in
                if let data = data {
                    valueHandler(data) // 執行後 返回呼叫 map.subscribe 內的 completion
                }
            }
            task.resume()
            return MySubscription {
                task.cancel()
            }
        })
    }
}
