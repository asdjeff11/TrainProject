//
//  CombineViewModel.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/7.
//

import Foundation
import Combine
class CombineViewModel:ViewModelActivity {
    private var userDatas:[UserData] = []
    
    @Published var name:String = ""
    @Published var email:String = ""
    @Published var pwd:String = ""
    @Published var confirmPwd:String = ""
    @Published var accept:Bool = false
    
    var validToRegisterPublisher:AnyPublisher<Bool,Never> {
        let parms1 = Publishers.CombineLatest($name, $email)
        let parms2 = Publishers.CombineLatest3($pwd,$confirmPwd,$accept)

        return parms1.combineLatest(parms2)
            .map{ (arg0,arg1) in
                let (pwd, confirmPwd, accept) = arg1
                let (name, email) = arg0
                return name.count > 0 &&
                    self.checkEmail(email: email) &&
                    pwd == confirmPwd &&
                    accept == true
            }
            .eraseToAnyPublisher()
    }
    
    override func updateData(completion:@escaping ()->Void) {
        // 撈取本機資料庫資訊 ....
        taskID = beginBackgroundUpdateTask()
        DispatchQueue.global(qos:.background).async {
            let query = "SELECT * FROM `UserData` ORDER BY `date` DESC;"
            self.userDatas = db.read2Object(query: query)
            self.endBackgroundUpdateTask(taskID: &self.taskID)
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    private func checkEmail(email:String)->Bool {
        let regex = """
         [a-zA-Z0-9._]+@([a-zA-Z0-9_]+.[a-zA-Z0-9_]+)+
         """
        
        return email.range(of: regex ,options:.regularExpression) != nil && userDatas.first(where: {$0.email == email}) == nil
    }
}

extension CombineViewModel {
    func setDataToDb(completion:@escaping (Bool)->Void) {
        taskID = beginBackgroundUpdateTask()
        DispatchQueue.global(qos:.background).async {
            let now = Theme.serverDateFormatter.string(from: Date())
            let insertQuery = "INSERT INTO UserData (`email`, `name`, `password`, `date`) values (\"\(self.email)\",\"\(self.name)\",\"\(self.pwd)\",\"\(now)\") ;"
            let result = db.executeQuery(query: insertQuery)
            if ( result ) {
                let query = "SELECT * FROM `UserData` ORDER BY `date` DESC;"
                self.userDatas = db.read2Object(query: query) 
            }
            DispatchQueue.main.async {
                self.endBackgroundUpdateTask(taskID: &self.taskID)
                completion(result)
            }
        }
    }
}

extension CombineViewModel {
    func getLen()->Int {
        return userDatas.count
    }
    
    func getUserData(index:Int)->UserData? {
        return (index < userDatas.count) ? userDatas[index] : nil
    }
}


