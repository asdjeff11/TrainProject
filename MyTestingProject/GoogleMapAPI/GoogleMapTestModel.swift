//
//  GoogleMapTestModel.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/8.
//

import Foundation
import CoreLocation

struct FavoritePlace: MyDataBaseStructer {
    static var tableName: String = "FavoritePlace"
    
    var ID:String // 編號
    var name:String // 地方名稱
    var address:String // 地址
    var date:String // 加入最愛時間
    var picURL:String // base64
    var latitude:Double // 緯度
    var longitude:Double // 經度
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case ID = "ID"
        case name = "name"
        case address = "address"
        case date = "date"
        case picURL = "picURL"
        case latitude = "latitude"
        case longitude = "longitude"
    }
    
    static func getColumnSize() -> Int {
        return CodingKeys.allCases.count
    }
    
    static func createTable()->String {
        return  """
                create table if not exists FavoritePlace
                ( ID text primary key,
                name text,
                address text,
                date text,
                picURL text,
                latitude double NOT NULL,
                longitude double NOT NULL);
                """
    }
}

extension FavoritePlace {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        ID = try values.decodeIfPresent(String.self, forKey: .ID) ?? "~"
        name = try values.decodeIfPresent(String.self, forKey: .name) ?? "~"
        address = try values.decodeIfPresent(String.self, forKey: .address) ?? "~"
        date = try values.decodeIfPresent(String.self, forKey: .date) ?? "~"
        picURL = try values.decodeIfPresent(String.self, forKey: .picURL) ?? "~"
        latitude = try values.decodeIfPresent(Double.self, forKey: .latitude) ?? -1
        longitude = try values.decodeIfPresent(Double.self, forKey: .longitude) ?? -1
    }
}

struct Place {
    var name:String
    var address:String
    var pointID:String
    var photoReference:String? // 有機會沒有 
    var location:CLLocationCoordinate2D // 經緯度
}
