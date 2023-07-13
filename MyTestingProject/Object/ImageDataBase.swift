//
//  ImageDataBase.swift
//  iCloudApp
//
//  Created by 楊宜濱 on 2023/6/20.
//  Copyright © 2023 ICL Technology CO., LTD. All rights reserved.
//

import UIKit

let imgDict = ImageDataBase() 

struct ImageStore: MyDataBaseStructer {
    static var tableName: String = "ImageStore"
    // 圖片儲存
    let url:String
    let lastUsed:String
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case url = "url"
        case lastUsed = "lastUsed"
    }
    
    static func getColumnSize() -> Int {
        return CodingKeys.allCases.count
    }
    
    
    static func createTable() -> String {
        return  """
                create table if not exists ImageStore
                ( url text primary key,
                lastUsed text
                );
                """
    }
}

extension ImageStore {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        url = try values.decodeIfPresent(String.self, forKey: .url) ?? "~"
        lastUsed = try values.decodeIfPresent(String.self, forKey: .lastUsed) ?? "~"
    }
}

class ImageDataBase {
    class ImageObj {
        var image = [UIImage]()
        init(imgs:[UIImage]) {
            self.image = imgs
        }
    }
    
    private var images = NSCache<NSString,ImageObj>()
    private var images_index:[String:ImageObj] = [:]
    private var semphore = DispatchSemaphore(value: 1)
    
    fileprivate let pathURL:URL? = {
        let documentDirectory = FileManager.SearchPathDirectory.documentDirectory

        let userDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        guard let path = NSSearchPathForDirectoriesInDomains(documentDirectory, userDomainMask, true).first
        else { return nil }
    
        return URL(fileURLWithPath: path)
    }()
    
    func putIntoDict(url:String,img:UIImage) {
        semphore.wait()
        defer {
            semphore.signal()
        }
        images.setObject(ImageObj(imgs:[img]), forKey: url as NSString)
        saveImageInFileManager(url: url, image: img)
    }
    
    func getImgs(hash:String)->[UIImage]? { // 拿圖片集
        semphore.wait()
        defer {
            semphore.signal()
        }
        
        if let imageObj = images.object(forKey: hash as NSString) {
            return imageObj.image
        }
        else {
            return nil
        }
    }
    
    func getImg(url:String, size:CGSize? = nil)->UIImage? { // 拿單張
        semphore.wait()
        defer {
            semphore.signal()
        }
        
        if let imageObj = images.object(forKey: url as NSString) , imageObj.image.isEmpty == false {
            return ( size == nil ? imageObj.image[0] : UIImage.scaleImage(image: imageObj.image[0], newSize: size!) )
        }
        else {
            if let img = getImageInFileManager(url: url) {
                images.setObject(ImageObj(imgs:[img]), forKey: url as NSString)
                return img
            }
        
            return nil
        }
    }
    
    func isInDict(hash:String)->Bool { return images.object(forKey: hash as NSString) != nil }
    
    private func getImageInFileManager(url:String)->UIImage? {
        guard let url_data = URL(string: url) else { return nil }
        let name = url_data.lastPathComponent
        var image:UIImage? = nil
        if let pathURL = pathURL {
            let imgUrl = pathURL.appendingPathComponent(name)
            image = UIImage(contentsOfFile: imgUrl.path)
            if ( image != nil ) {
                let now = Theme.onlyDateDashFormatter.string(from: Date())
                let updateQ = "UPDATE ImageStore SET lastUsed = '\(now)' WHERE url = \"\(url)\" ; "
                if ( !db.executeQuery(query: updateQ) ) { print("update ImageStore lastused error on query:\(updateQ). file:ImageDataBase") }
            }
        }
        return image
    }
    
    private func saveImageInFileManager(url:String , image:UIImage) {
        //guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        guard let url_data = URL(string: url) else { return }
        let name = url_data.lastPathComponent
        
        if let pathURL = pathURL {
            let fileURL = pathURL.appendingPathComponent(name)
            guard let data = image.pngData() else { return }

            //Checks if file exists, removes it if so.
            if FileManager.default.fileExists(atPath: fileURL.path) {
                /*do {
                    try FileManager.default.removeItem(atPath: fileURL.path)
                    print("Removed old image")
                } catch let removeError {
                    print("couldn't remove file at path", removeError)
                }*/
                return
            }

            do {
                try data.write(to: fileURL)
            } catch let error {
                print(name)
                print("error saving file with error", error)
            }
        }
    }
    
    func removeImageInFileManager(url:String) {
        guard let url_data = URL(string: url) else { return }
        let name = url_data.lastPathComponent
        
        
        if let pathURL = pathURL {
            let fileURL = pathURL.appendingPathComponent(name)
            do {
                try FileManager.default.removeItem(atPath: fileURL.path)
                print("Removed old image")
            } catch let removeError {
                print("couldn't remove file at path", removeError)
            }
        }
        else {
            print("path URL is null.")
        }
    }
    
    
    func onBackGround(photos:[Photo]) {
        for photo in photos {
            if let imgObj = images.object(forKey: photo.url as NSString) {
                images_index[photo.url] = imgObj
            }
        }
        images.removeAllObjects()
    }
    
    func onFrontGround() {
        for entry in images_index {
            let hash = entry.key as NSString
            let imgObj = entry.value
            images.setObject(imgObj, forKey: hash)
        }
        images_index.removeAll()
    }
    
    func memoryIsFull(needSafeHash:[String]) {
        /*
        semphore.wait()
        defer {
            semphore.signal()
        }
        
        if ( needSafeHash.isEmpty ) {
            images.removeAll()
            return
        }
        
        var index_img:[String:[UIImage]] = [:] // 存放當前頁面需要的圖片
        for hash in needSafeHash {
            if let img = images[hash] {
                // 因為記憶體快不夠用了 怕 多copy 一份直接掛掉  故 每copy 一張 就 刪一個
                images.removeValue(forKey: hash)
                index_img[hash] = img
            }
        }
        images.removeAll() // 全部釋放
        images = index_img // 只保留我當前頁面需要的資料
        */
    }
    
}
