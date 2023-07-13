//
//  itemModel.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/7/6.
//

import Foundation
struct itemModel:Hashable {
    static func == (lhs: itemModel, rhs: itemModel) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(num)
        hasher.combine(section)
    }
    
    var num:String
    var section:Int
    
    init(n:Int , section:Int) { self.num = String(n) ; self.section = section }
    
}
