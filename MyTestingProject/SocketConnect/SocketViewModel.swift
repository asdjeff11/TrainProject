//
//  SocketViewModel.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/13.
//

import Foundation
class SocketViewModel:ViewModelActivity {
    private let PORT = Port.testPort
    private var receiveData:Data = Data()
    func sendMsg(_ text:String, completion:@escaping ((String)->Void)) {
        taskID = beginBackgroundUpdateTask()
        Task.detached(priority: .background) {
            let server = ConnectStack.stacks.getServer(port: self.PORT.rawValue)
            defer {
                self.endBackgroundUpdateTask(taskID: &self.taskID)
                server.close()
            }
            server.send(text)
            server.sendComplete() // -1 告知傳送完畢
            
            self.receiveData.removeAll()
            server.read(&self.receiveData) // 讀取 server 回傳資訊
            print(self.receiveData)
            
            Task.detached(operation: { @MainActor [weak self] in
                guard let self = self else { return }
                completion(self.receiveData.string ?? "nil")
            })
        }
       
    }
}
