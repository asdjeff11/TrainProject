//
//  DatabaseObject.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/6/20.
//

import Foundation

protocol MyDataBaseStructer:Codable {
    static var tableName:String { get }
    
    static func createTable()->String
    
    static func getColumnSize()->Int
}

extension MyDataBaseStructer {
    func getUpdateQuery()->String {
        let mirror = Mirror(reflecting: self)
        var columnInfo = ""
        var valueInfo = ""
        
        for child in mirror.children {
            let label:String = child.label!
            if ( label == "tableName" ) { continue }
            let valueType = "\(type(of: child.value))"
            
            // value 修改
            var value = "\(child.value)"
            if ( value == "nil" ) { value = "" }
            
            if ( valueType.contains("String") ) { // 字串
                if ( value == "~" ) { value = "\"\"" } // 改回空字串
                else { value = "\"\(value)\"" } // 補string \"\"符號
            }
            else {
                if ( value == "-1" ) { // integer default
                    value = "0"
                }
            }
            
            columnInfo = "\(columnInfo)\(label),"
            valueInfo = "\(valueInfo)\(value),"
        }
        
        return """
        REPLACE INTO \(Self.tableName) ( \(String(columnInfo.dropLast())) ) VALUES ( \(String(valueInfo.dropLast())) ) ;
        """
    }
    
    func checkStructorIsUpdate() -> Bool {
        let mirror = Mirror(reflecting: self)
        
        for child in mirror.children {
            let label:String = child.label!
            if ( label == "tableName" ) { continue }
            
            let valueType = "\(type(of: child.value))"
            let value = "\(child.value)"
            if ( valueType.contains("String") ) {
                if ( value == "~" ) {
                    return true
                }
            }
            else {
                if ( value == "-1" ) {
                    return true
                }
            }
        }
        
        return false
    }
}
