//
//  OperationView.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/17.
//

import Foundation
import UIKit


class PendingOperations { // 追蹤每個operation狀態
    lazy var downloadsInProgress:[IndexPath:Operation] = [:] // 用於跟蹤表中 每行的活動
    lazy var downloadQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.qualityOfService = .background
        //queue.name = "download Image"
        queue.maxConcurrentOperationCount = 5 // 最高開到5個
        return queue
    }()
    
    func cancel(path:IndexPath){
        self.downloadsInProgress[path]?.cancel()
        self.downloadsInProgress.removeValue(forKey: path)
    }
    
    func cancelAll(){
        _ = self.downloadsInProgress.map{ $0.value.cancel() }
        self.downloadsInProgress.removeAll()
    }
    
    func addTask(path:IndexPath, downloader:Operation){
        self.downloadsInProgress[path] = downloader
        self.downloadQueue.addOperation(downloader)
    }
}


class ImageDownloader: Operation {
    var photoRecord:Photo
    init(_ photoRecord:Photo) {
        self.photoRecord = photoRecord
        super.init() 
    }

    private func getImage(url:String) async -> Result<Data,CustomError> {
        guard let url = URL(string:url) else { return .failure(.invalidUrl) }
        
        guard let (data,response) = try? await URLSession.shared.data(from:url),
              let response = response as? HTTPURLResponse,
              (200...299).contains(response.statusCode) else { return .failure(.invalidResponse) }
        
        return .success(data)
    }
    
    override func main() {
        if isCancelled {
            return
        }
        
        if photoRecord.state == .Done {
            return
        }
        else {
            let url = photoRecord.url
            if ( url == "" ) {
                photoRecord.state = .Failed
            }
            else if let img = imgDict.getImg(url: url) { // 本地圖片
                photoRecord.state = .Done
                photoRecord.image = img
            }
            else {
                let group = DispatchGroup()
                group.enter()
                Task {
                    let result = await getImage(url: url)
                    switch ( result ) {
                    case .failure(let error) :
                        print(error.localizedDescription)
                        photoRecord.state = .Failed
                    case .success(let data) :
                        guard let img = UIImage(data:data) else { photoRecord.state = .Failed ; return }
                       // let scaleImg = UIImage.scaleImage(image: img, newSize: CGSize(width: 200 * Theme.factor, height: 100 * Theme.factor)) // 為了降低空間
                        photoRecord.state = .Done
                        //photoRecord.image = img
                        imgDict.putIntoDict(url: url, img: img)
                    }
                    group.leave()
                }
                group.wait()
            }
        }
    }
    
    func compressImageSize(image:UIImage) -> UIImage{ // 壓縮圖片大小
        let zipImageData = image.jpegData(compressionQuality: 0.1)!
        print(zipImageData.count)
        return UIImage(data: zipImageData)!
    } // 壓縮圖片大小
}
