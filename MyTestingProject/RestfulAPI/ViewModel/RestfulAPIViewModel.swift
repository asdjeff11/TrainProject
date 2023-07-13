//
//  RestfulAPIViewModel.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2022/9/1.
//
import UIKit
class RestfulAPIViewModel:ViewModelActivity {
    private var restManager = RestManager()
    private var models:[RestfulModel] = []
    private var queue = TaskQueue()
    public var isSuspend = false
    
    func fetchData(url:String, completion: @escaping (String)->Void) {
        guard let url = URL(string:url) else { return }
        restManager.makeRequest(toURL: url, withHttpMethod: .get, completion:{ (result: Result<[StarsData], CustomError>) in
            switch ( result ) {
            case .success(let startDatas) :
                self.isSuspend = false 
                self.models = startDatas.map({ data in
                    return RestfulModel(data: data)
                })
                completion("")
                break
            case .failure(let error) :
                switch ( error ) {
                case .invalidData :
                    completion("Json Parser Error")
                case .invalidUrl :
                    completion("URL analysis Error")
                case .invalidResponse :
                    completion("URL Connect Response Error")
                case .requestFailed(let error) :
                    completion("URL RequestFailed Error(\(error))")
                case .isCanceled :
                    completion("URL is canceled")
                    
                }
            }
        })
    }
    
    func fetchImage(url:String,indexPath:IndexPath? = nil, completion: @escaping(Result<UIImage,CustomError>)->Void) {
        guard let url_data = URL(string:url) else { completion(.failure(.invalidUrl)) ; return  }
        var task:URLSessionDownloadTask?
        task = URLSession.shared.downloadTask(with: url_data) { data, response , error in
            if let error = error {
                if ( error.localizedDescription.contains("cancelled") ) { completion(.failure(.isCanceled)) }
                else { completion(.failure(.requestFailed(error))) }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { completion(.failure(.invalidResponse)) ;return}
            /*guard let data = data , let image = UIImage(data:data ) else {  completion(.failure(.invalidData)) ;return }*/
            // completion(.success(image))
            if let downloadUrl = data {
                //用檔案在手機內的位置去產生一個Data
                do{
                    let downloadData = try Data(contentsOf: downloadUrl)
                    guard let loadedImage = UIImage(data: downloadData) else { throw CustomError.invalidData }
                    imgDict.putIntoDict(url: url, img: loadedImage)
                    
                    try Task.checkCancellation()
                    
                    completion(.success(loadedImage))
                }
                catch {
                    if ( error.localizedDescription.contains("cancelled") ) { completion(.failure(.isCanceled)) }
                    completion(.failure(.requestFailed(error)))
                    //print(error.localizedDescription)
                }
            }
        }
        
        if let indexPath = indexPath {
            queue.addTask(indexPath: indexPath, task: task!)
        }
        task?.resume()
    }
    
}

extension RestfulAPIViewModel {
    func getTotalSize() -> Int {
        return models.count
    }
    
    
    func getItem(indexPath:IndexPath) -> RestfulModel {
        return models[indexPath.row]
    }
    
    func getImage(indexPath:IndexPath,completion: @escaping (UIImage?)->Void) {
        if isSuspend { return }
        
        let model = models[indexPath.row]
        if let img = imgDict.getImg(url: model.starsData.url) {
            self.models[indexPath.row].photo.image = img
            self.models[indexPath.row].photo.state = .Done
            completion(img)
            return
        }
        
        fetchImage(url: model.starsData.url, indexPath: indexPath, completion: { result in
            self.queue.removeTask(indexPath: indexPath)
            switch ( result ) {
            case .success(let img) :
                imgDict.putIntoDict(url: model.starsData.url, img: img)
                self.models[indexPath.row].photo.image = img
                self.models[indexPath.row].photo.state = .Done
                completion(img)
            case .failure(let error) :
                switch ( error ) {
                case .invalidUrl :
                    print("row:\(indexPath.row) url is error")
                case .invalidData :
                    print("row:\(indexPath.row) data is error")
                case .requestFailed(let error) :
                    print("row:\(indexPath.row) request is error(\(error)")
                case .invalidResponse :
                    print("row:\(indexPath.row) response is error")
                case .isCanceled : // 滑動太快而取消  這不算是個錯誤資訊 只是被取消
                    print("row:\(indexPath.row) is Cancel")
                    return
                }
                self.models[indexPath.row].photo.state = .Failed
                completion(nil)
            }
        })
    }
    
    func removeAllTaskInQueue() {
        queue.removeAllTask()
    }
}
