//
//  ViewModelActivity.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2022/9/1.
//
import UIKit
public class ViewModelActivity:NSObject {
    var isLoading = false
    
    var showLoading:((_ isLoading:inout Bool) -> ())?
    var removeLoading:((_ isLoading:inout Bool) -> ())?
    var showAlert:((_ alertText:String,_ alertMessage:String) -> ())?
    var updateRecyculerView:((_ :Bool) -> ())?
    var scrollToTop:(()->())?
//    var showAlert2:((_ alertText:String,_ alertMessage:String,_ testAG:Int) -> ())! // ??????
    
    
    var onBackgroundTime = Date()
    
    var taskID: UIBackgroundTaskIdentifier?
    
    var group = DispatchGroup()
    
    func beginBackgroundUpdateTask() -> UIBackgroundTaskIdentifier {
        return UIApplication.shared.beginBackgroundTask(expirationHandler: ({}))
    }

    func endBackgroundUpdateTask(taskID: inout UIBackgroundTaskIdentifier?) {
        if taskID == nil { return }
        
        UIApplication.shared.endBackgroundTask(taskID!)
        taskID = nil
    }
    
    // 現在開始往回推三個月
    func threeMonthDate()->String { // 現在開始往回推三個月
//        let date = Date() - 7776000
        let date = Date().getOffsetDay(type: .month, offset: -3)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: date)
    }
    
    
    @objc func updateData( completion:@escaping ()->Void){}
    
    func checkBackToApp()->Bool { // 檢查是否要重撈 先設定為10秒鐘後 重新整理資訊
        let currentTime = Date().timeIntervalSince1970
        let beforeTime = onBackgroundTime.timeIntervalSince1970
        if ( currentTime - beforeTime > 10 ) { // 超過10秒
            /*ServerStack.stacks.releaseAllConnect()
            DispatchQueue.main.async {
                if let scrollToTop = self.scrollToTop {
                    scrollToTop()
                }
                self.updateData(usedLoading:true)
                // 如果有 group notify 出現的話 裡面的 self = null 會執行不到 結束taskID
                self.endBackgroundUpdateTask(taskID: &self.taskID) // 取消 taskID 如果沒取消的話
                //self.removeLoading(&self.isLoading)
            }*/
            return true
            //ServerStack.stacks.releaseAllConnect()
            
        }
        return false
    }
}

