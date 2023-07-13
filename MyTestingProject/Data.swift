//
//  Data.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/7.
//

import Foundation
struct SplitedResult { // 正規表達式 切割字串
    let fragment: String
    let isMatched: Bool
    let captures: [String?]
}
