//
//  GoogleMapTestViewModel.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/8.
//

import Foundation
import UIKit
class GoogleMapTestViewModel:ViewModelActivity {
    var places:[FavoritePlace] = [] 
    var images:[String:UIImage] = [:]
    override func updateData(completion: @escaping () -> Void) {
        // 撈取本機資料庫資訊 ....
        taskID = beginBackgroundUpdateTask()
        DispatchQueue.global(qos:.background).async {
            let query = "SELECT * FROM `FavoritePlace` ORDER BY `date` DESC;"
            self.places = db.read2Object(query: query)
            self.setUpImageDict()
            self.endBackgroundUpdateTask(taskID: &self.taskID)
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    private func setUpImageDict() {
        for place in places {
            if let image = imgDict.getImg(url: place.picURL) {
                images[place.ID] = image
            }
        }
    }
}


extension GoogleMapTestViewModel {
    func getLen()->Int {
        return places.count
    }
    
    func getItem(index:Int)->FavoritePlace? {
        return index < places.count ? places[index] : nil
    }
    
    func getItemImage(ID:String)->UIImage? {
        return images[ID]
    }
}

