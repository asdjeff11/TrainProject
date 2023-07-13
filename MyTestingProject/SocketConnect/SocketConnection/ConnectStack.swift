//
//  ServerStack.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/13.
//

import Foundation
enum Port:Int {
    case testPort = 9366
    case IDServer = 9367
    case PicPort = 9368
}

class ConnectStack {
    static let stacks = ConnectStack() // 外部呼叫 單例
    static var IDcount = 0 // 給予標記編號
    
    var idleServer = [UInt16:[SocketConnector]]() // 閒置的連線
    var usingServer = [Int:SocketConnector]() // 使用中的連線
    
    private var semphore = DispatchSemaphore(value: 1) // 同步控制
    
    func getServer(port:Int)->SocketConnector { // 取得一個連線
        defer {
            semphore.signal()
        }
        semphore.wait()
        
        var server:SocketConnector!
        let p = UInt16(port)
        var servers = idleServer[p] ?? []
        if ( servers.isEmpty == false ) { // dict 有 該連線
            while ( server == nil && servers.isEmpty == false ) { // 找到可用的連線
                let s = servers.popLast()! // 取得該連線
                
                //print( "server ID:\(s.getID()) , state:\(s.getIsLive())")
                
                if ( s.getIsLive() ) { // 若該連線還可以使用
                    server = s // 取得連線
                    break
                }
            }
            
            idleServer[p] = servers // 剛剛如果有檢測到不能使用的連線 則會被修改掉
            if server != nil { // 若有找到可以使用的
                usingServer[server!.getID()] = server! // 放入使用區域
            }
        } // dict 有 該連線
       
        if ( server == nil ) { // 找不到任何閒置的連線可以使用
            //print("create new server ID:\(ServerStack.IDcount)")
            server = SocketConnector.Instance(port: p,ID: ConnectStack.IDcount) // 建立新的
            usingServer[ConnectStack.IDcount] = server! // 放入使用區域
            ConnectStack.IDcount += 1
        }
        
        server.removeData()
        return server
    }
    
    func finishUsedServer(_ server:SocketConnector) { // 使用完畢連線後 歸還給我
        defer {
            semphore.signal()
        }
        semphore.wait()
        
        usingServer.removeValue(forKey: server.getID())
        if ( server.getIsLive() ) {
            //server.setTime()
            var servers = idleServer[server.getPort().rawValue] ?? []
            servers.append(server)
            idleServer[server.getPort().rawValue] = servers
        }
    }
    
    func releaseServerConnect(server:SocketConnector) { // 如果連線被關閉(socketConnector.close() ) 就會呼叫此 去斷開連接
        defer {
            semphore.signal()
        }
        semphore.wait()
        var servers = idleServer[server.getPort().rawValue] ?? []
        var find = false
        var i = 0
        while ( i < servers.count ) {
            if ( servers[i].getID() == server.getID() ) {
                servers.remove(at: i)
                find = true
                break
            }
            i = i + 1
        }
        
        
        if ( find == true ) {
            idleServer[server.getPort().rawValue] = servers
        }
        else {
            usingServer.removeValue(forKey: server.getID())
        }
    }
    
    func checkPortIsNoConnection(port:Int)->Bool {
        return ( idleServer[UInt16(port)] == nil || idleServer[UInt16(port)]!.isEmpty )
    }
    
    func releaseAllConnect() {
        for (_,server) in usingServer {
            server.close()
        }
        for (_,servers) in idleServer {
            for server in servers {
                server.close()
            }
        }
        idleServer.removeAll()
        usingServer.removeAll()
    }
}
