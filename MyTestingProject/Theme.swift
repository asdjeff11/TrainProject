//
//  Theme.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2022/9/1.
//

import UIKit

class Theme {
    static var fullSize = UIScreen.main.bounds.size
    static let factor = UIScreen.main.bounds.width / 720
    static let navigationBarTitleFont = UIFont(name:"Helvetica Neue", size:25)
    static let navigationBarBG =  UIColor(hex:0xFFCC00)
    static var yellowBtn = #colorLiteral(red: 0.9840000272, green: 0.7730000019, blue: 0.2630000114, alpha: 1)
    static var yellowBtnShadow = #colorLiteral(red: 0.949000001, green: 0.6819999814, blue: 0.2039999962, alpha: 1)
    static let backGroundImage = UIImage(named: "backgroundImage")?.cgImage
    static let navigationBtnSize = CGRect(x:0,y:0,width: 50 * factor, height: 50 * factor)
    static let labelFont = UIFont(name: "Helvetica-Light", size: 20)!
    
    static var formatter: DateFormatter {
        return customFormatter(dateType: "yyyy/MM/dd ahh:mm")
    }
    
    static var normalDateFormatter: DateFormatter {
        return customFormatter(dateType: "yyyy/MM/dd HH:mm")
    }
    
    static var baseDateFormatter: DateFormatter {
        return customFormatter(dateType: "yyyy/MM/dd HH:mm:ss")
    }
    
    static var serverDateFormatter: DateFormatter {
        return customFormatter(dateType: "yyyy-MM-dd HH:mm:ss")
    }
    
    static var onlyDateFormatter: DateFormatter {
        return customFormatter(dateType: "yyyy/MM/dd")
    }
    
    static var onlyDateDashFormatter: DateFormatter {
        return customFormatter(dateType: "yyyy-MM-dd")
    }
    
    // 時間格式 "HH:mm"
    static var timeFormatter: DateFormatter {
        let formater = customFormatter(dateType: "HH:mm")
        return formater
    }
    
    static func customFormatter(dateType:String)->DateFormatter {
        let format = DateFormatter()
        format.locale = Locale(identifier: "zh-TW")
        format.timeZone = TimeZone(identifier: "Asia/Taipei")
        format.dateFormat = dateType
        return format
    }
    
    
    static func DateConvert(_ string:String,_ transStyle:String)-> String {
        let OriDateStyle = ["yyyy-MM-dd HH:mm:ss","yyyy/MM/dd HH:mm:ss","yyyy/MM/dd aHH:mm","yyyy/MM/dd HH:mm"]
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Asia/Taipei")
        formatter.locale = Locale(identifier: "zh-TW")
        
        var date:Date?
        for i in OriDateStyle {
            formatter.dateFormat = i
            date = formatter.date(from: string)
            if (date != nil) { break }
        }
        if(date == nil){
            print("the form is :\(string)")
            return "no correct dateForm,\nthe form is :\(string)"
        }
        
        formatter.dateFormat = transStyle   //2020 07 13 10 12 12
        let dateFormatString: String = formatter.string(from: date!)
        return dateFormatString
    }
    
    static var numFormatter: NumberFormatter {
        let format = NumberFormatter()
        format.locale = Locale(identifier: "zh-TW")
        format.numberStyle = .decimal
        format.minimumFractionDigits = 0
        return format
    }
}

