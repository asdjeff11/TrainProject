//
//  RestManager.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2022/9/1.
//
import UIKit
class RestManager {
    var requestHttpHeaders = RestEntity() // 請求 http 標頭
    var urlQueryParameters = RestEntity() // 要加入到 URL 後面的參數
    var httpBodyParameters = RestEntity() // 請求 http body ( post 修改值的時候 可以使用它 )
    var httpBody:Data?
    
    
    private func addURLQueryParameters(toURL url: URL) -> URL { // 加入 參數 至 url 中
        guard ( urlQueryParameters.totalItems() != 0 ) else { return url } // no parametters
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url } // cant get component
        
        // 取得 所有 parameters => URLQueryItem
        var queryItems = [URLQueryItem]()
        for (key, value) in urlQueryParameters.allValues() {
            let item = URLQueryItem(name: key, value: value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed))

            queryItems.append(item)
        }
        
        urlComponents.queryItems = queryItems // 設定url parameters
        guard let updatedURL = urlComponents.url else { return url } // urlComponents => url
        return updatedURL
    }
    
    
    private func getHttpBody() -> Data? { // 取得 http body
        guard let content_type = requestHttpHeaders.value(forKey: "Content-Type") else { return httpBody } // 確定使否已經有 content-Type(需要判斷是哪種形式 送 url)
        // 依照 類別 製造對應的 httpBody
        if content_type.contains("application/json") { // json 方式
            // 將 httpbody dict 轉成 json data
            return try? JSONSerialization.data(withJSONObject: httpBodyParameters.allValues(), options: [.prettyPrinted, .sortedKeys])
        }
        else if content_type.contains("application/x-www-form-urlencoded") { // 參數 以 & split
            // name=John&year=18
            let bodyString = httpBodyParameters.allValues().map { "\($0)=\(String(describing: $1.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)))" }.joined(separator: "&")
            return bodyString.data(using: .utf8)
        }
        else { // 其他
            return httpBody
        }
    }
    
    
}

extension RestManager { // url 連線
    private func prepareRequest(withURL url: URL?, httpBody: Data?, httpMethod: HttpMethod) -> URLRequest? { // 準備 URL 請求
        guard let url = url else { return nil }
        var request =  URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue // 請求動作
        // 設定 header
        for ( header,value) in requestHttpHeaders.allValues() {
            request.setValue(value, forHTTPHeaderField: header)
        }
        // 設定body
        request.httpBody = httpBody
        return request
    }
    
    func makeRequest<T>(toURL url: URL,
                     withHttpMethod httpMethod: HttpMethod,
                        completion: @escaping (Result<[T],CustomError>) -> Void) where T:Codable {
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let targetURL = self?.addURLQueryParameters(toURL: url) // 將查詢參數加入url
            let httpBody = self?.getHttpBody() // 取得 http body
            // 取得 url 請求 物件
            guard let request = self?.prepareRequest(withURL: targetURL, httpBody: httpBody, httpMethod: httpMethod) else
            { // 建立失敗 則回報錯誤
                completion(.failure(CustomError.invalidUrl) )
                return
            }
            
            // 開始建立連線
            let sessionConfiguration = URLSessionConfiguration.default
            let session = URLSession(configuration: sessionConfiguration)
            session.dataTask(with: request) { (data, response, error) in
                // 連線結果放入此
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { completion(.failure(.invalidResponse)) ; return }
                
                let decoder = JSONDecoder()
                if let data = data {
                    do {
                        let response = try decoder.decode([T].self, from: data)
                        completion(.success(response))
                    }
                    catch {
                        completion(.failure(.invalidData))
                    }
                }
                else if let error = error {
                    completion(.failure(.requestFailed(error)))
                }
            }.resume()
        }

    }
    
}


extension RestManager {
    enum HttpMethod: String { // Http 指令
        case get
        case post
        case put
        case patch
        case delete
    }
    
    struct RestEntity { // dictionary
        private var values: [String: String] = [:]

        mutating func add(value: String, forKey key: String) {
            values[key] = value
        }

        func value(forKey key: String) -> String? {
            return values[key]
        }

        func allValues() -> [String: String] {
            return values
        }
        
        func totalItems() -> Int {
            return values.count
        }
    }
    
    struct Response { // server 回應
        var response: URLResponse? // server 回應物件 ( 不含實際資料 )
        var httpStatusCode: Int = 0 // http code 請求狀態碼
        var headers = RestEntity() // header 的內容  含 content-type ,Server ....
        
        init(fromURLResponse response: URLResponse?) { // contructor
            guard let response = response else { return } // 回應物件為 null 則 返回
            self.response = response
            guard let httpURLResponse = (response as? HTTPURLResponse) else { return } // 轉換失敗 則 返回
            
            httpStatusCode = httpURLResponse.statusCode // 設定狀態碼
            for (key, value) in httpURLResponse.allHeaderFields { // 解析 server 回應 的 header 資訊
                headers.add(value: "\(value)", forKey: "\(key)")
            }
            
        }
    }
    
    
    
    
    struct Results { // server 回應 ( 包含結果 )
        var data: Data? // 實際資料 ( real data )
        var response: Response? // server 回應資訊 ( header, statusCode ... )
        var error: Error? // error message
        
        init(withData data: Data?, response: Response?, error: Error?) {
            self.data = data
            self.response = response
            self.error = error
        }

        init(withError error: Error) {
            self.error = error
        }
    }
}
