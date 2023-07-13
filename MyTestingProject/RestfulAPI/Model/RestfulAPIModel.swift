//
//  RestfulAPIMolde.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2022/9/1.
//

import UIKit

struct RestfulModel {
    var starsData:StarsData
    var photo:Photo
    
    init(data:StarsData) {
        self.starsData = data
        let img = imgDict.getImg(url: data.url)
        self.photo = Photo(url:data.url,image: img)
        if img != nil {
            self.photo.state = .Done
        }
    }
}

struct StarsData: Codable {
    var title: String
    var copyright: String
    var date: String
    var url: String
    var hdurl: String
    var description: String
    
    //var apod_site: String
    //var media_type: String
}

struct Photo {
    enum State {
        case NotDone,Done,Failed
    }
    
    var state:State = .NotDone
    var url:String = ""
    var image:UIImage?
}



enum CustomError: Error {
    case invalidUrl
    case requestFailed(Error)
    case isCanceled
    case invalidData
    case invalidResponse
}
