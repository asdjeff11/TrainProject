//
//  ErrorCase.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/13.
//

import Foundation
enum ErrorCase:Error {
    /// 資料抓取時錯誤
    case fetchError(String)
    
    /// 抓取ID時錯誤
    case IDServerError(String)
    
    /// 更新command時錯誤
    case updateError(String)
    
    /// 沒有預期應該抓到的資料
    case wantGetError(String)
}
