//
//  OperationViewModel.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/17.
//

import Foundation
import UIKit
class OperationViewModel:ViewModelActivity {
    private var restManager = RestManager()
    var models:[RestfulModel] = []
    var pendingOperations = PendingOperations()
    public var isSuspend = false {
        didSet {
            if ( isSuspend ) {
                pendingOperations.downloadQueue.isSuspended = true
                pendingOperations.cancelAll()
            }
            else {
                pendingOperations.downloadQueue.isSuspended = false
            }
        }
    }
    public var updateCell:((IndexPath)->())?
    
    func fetchData(url:String, completion: @escaping (String)->Void) {
        guard let url = URL(string:url) else { return }
        restManager.makeRequest(toURL: url, withHttpMethod: .get, completion:{ (result: Result<[StarsData], CustomError>) in
            switch ( result ) {
            case .success(let startDatas) :
                self.isSuspend = false
                self.models = startDatas.map({ RestfulModel(data: $0) })
                
                //self.models = [self.models.first!]
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
   
}

extension OperationViewModel {
    func getTotalSize() -> Int {
        return models.count
    }
    
    
    func getItem(indexPath:IndexPath) -> RestfulModel {
        return models[indexPath.row]
    }
    
    func resetItemState(indexPath:IndexPath) {
        if ( indexPath.row < models.count ) {
            models[indexPath.row].photo.state = .NotDone
            startOperation(at: indexPath)
        }
    }
    
   
    func startOperation( at indexPath:IndexPath) {
        let photoRecord = models[indexPath.row].photo
        guard pendingOperations.downloadsInProgress[indexPath] == nil else { return } // 查找該是否已經在列隊中  有就不加入列隊
        
        let downloader = ImageDownloader(photoRecord) // new 一個 operation
        downloader.completionBlock = { // ImageDownLoader main 結束後 執行
            self.pendingOperations.downloadsInProgress.removeValue(forKey: indexPath) // 移除列隊標記
            
            if ( downloader.isCancelled ) { return }
            self.models[indexPath.row].photo = downloader.photoRecord
            // 執行結束 後續動作
           
            DispatchQueue.main.async { // 刷新cell
                self.updateCell?(indexPath)
            }
        }
        
        // 加入列隊中
        if taskID == nil { taskID = beginBackgroundUpdateTask() } // 申請後臺延長時間
        pendingOperations.addTask(path: indexPath, downloader: downloader)
    }
    
    
    func removeAllTaskInQueue() {
        let myQueue = DispatchQueue(label: "Release Memory",
                                    qos: .userInitiated,
                                    attributes: .concurrent)
        myQueue.async(flags: .barrier) {
            self.pendingOperations.downloadQueue.isSuspended = true // 停止加入新任務
            let urls = self.models.map({ return $0.starsData.url })
            imgDict.memoryIsFull(needSafeHash: urls)
            Task.detached(operation: { @MainActor in
                self.updateRecyculerView?(false) // 重新刷新collectionView
            })
        }
    }
    
    func loadImageOnScreen(showingIndex:Set<IndexPath> ) {
        let allPendingOperations = Set(pendingOperations.downloadsInProgress.keys) // 所有運行中的 operation 的 IndexPath
        
        // 取消原先的工作 如果目前可見的 與此有相同的資料 則不需要取消
        var toBeCancelled = allPendingOperations
        toBeCancelled.subtract(showingIndex) // 將被取消任務的 IndexPath
        _ = toBeCancelled.map{ pendingOperations.cancel(path: $0) } // cancel 原先的 任務
        
        // 加入新的工作 要去除掉 剛剛沒有被清掉的工作 避免重複加入
        var toBeStarted = showingIndex
        toBeStarted.subtract(allPendingOperations) // 將要開始任務的 IndexPath
        
        for indexPath in toBeStarted { // 加入 新的任務
            if ( models[indexPath.row].photo.state != .Done ) { // 沒完成 再撈
                startOperation(at: indexPath)
            }
        }
    }
}
