//
//  CombineModel.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/7.
//

import Foundation

struct UserData: MyDataBaseStructer {
    static var tableName: String = "UserData"
    // 社區
    var name:String = ""
    var email:String = ""
    var password:String = ""
    var date:String = ""
    
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case name = "name"
        case email = "email"
        case password = "password"
        case date = "date"
    }
    
    static func getColumnSize() -> Int {
        return CodingKeys.allCases.count
    }
    
    static func createTable()->String {
        return  """
                create table if not exists UserData
                ( name text,
                email text,
                password text,
                date text,
                PRIMARY KEY(email,password)
                );
                """
    }
}

extension UserData {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decodeIfPresent(String.self, forKey: .name) ?? "~"
        email = try values.decodeIfPresent(String.self, forKey: .email) ?? "~"
        password = try values.decodeIfPresent(String.self, forKey: .password) ?? "~"
        date = try values.decodeIfPresent(String.self, forKey: .date) ?? "~"
    }
}

