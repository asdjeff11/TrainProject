//
//  AppDelegate.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2022/9/1.
//

import UIKit
import CoreData
import GoogleMaps
@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?
    var nav = UINavigationController()
    static let googleMapAPIkey = "" // Google Map API Key
    static var googleMapKeyIsVaild = false
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if #available(iOS 15.0, *) {
            UITableView.appearance().sectionHeaderTopPadding = CGFloat(0)
        }
        
        // app 啟動最先執行
        // Override point for customization after application launch.
        UIButton.initializeMethod() // button 防止重複點擊
        
        nav.viewControllers =  [MainViewController()]
        self.window = UIWindow(frame: UIScreen.main.bounds)
      
        self.window?.rootViewController = nav // root
        self.window?.makeKeyAndVisible()
        self.window?.backgroundColor = UIColor.white
        
        if ( GMSServices.provideAPIKey(AppDelegate.googleMapAPIkey) ) {
            AppDelegate.googleMapKeyIsVaild = true
            GMSServices.setMetalRendererEnabled(true)
        }
       
        // 推播權限要求
        // iOS 10 support
        if #available(iOS 10, *) {
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            // set the type as sound or badge
            center.requestAuthorization(options: [.sound,.alert,.badge]) { (granted, error) in
                if granted {
                    print("Notification Enable Successfully")
                    DispatchQueue.main.async {
                        application.registerForRemoteNotifications()
                    }
                    
                }else{
                    print("Some Error Occure")
                }
            }
            
        }
        else {
            let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) { // 取得deviceToken
        // 只要呼叫 UIApplication.shared.registerForRemoteNotifications() 就會執行此行
        var tokenString = ""
        for byte in deviceToken {
            let hexString = String(format: "%02x", byte)
            tokenString += hexString
        }
        print("token: \(tokenString)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) { // 取得deviceToken 失敗
        print("doesnt accept recive push Notification")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void){
        // 點擊推播之後 觸發
        let content: UNNotificationContent = response.notification.request.content
        UIApplication.shared.applicationIconBadgeNumber = -1
        let message = content.userInfo["message"] as? String ?? ""
        var body:String? = nil
        if let aps = content.userInfo["aps"] as? [String:Any] , let alert = aps["alert"] as? [String:String]  {
            body = alert["body"]
        }
        
        print("payloadData:\(message)" )
        print("推播的body文字:\(body ?? "" )")
        completionHandler()
    }
    
    /*
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // 後台 掛起  靜默推播  目前無用途 silent notification 切換app不知道為什麼就收不到了 問題很多
        print(" Entire message \(userInfo)")
        /*if let info:[String:String] = userInfo["data"] as? [String : String] {
            let noti = UNMutableNotificationContent()
            noti.title = info["title"] ?? "標題"
            noti.body = info["body"] ?? "身體"
            noti.sound = UNNotificationSound.default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: "notification", content: noti, trigger: trigger)
            UNUserNotificationCenter.current().add(request,withCompletionHandler: nil)
        }*/
        let noti = UNMutableNotificationContent()
        noti.title = "標題"
        noti.body = "身體"
        noti.sound = UNNotificationSound.default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "notification", content: noti, trigger: trigger)
        UNUserNotificationCenter.current().add(request,withCompletionHandler: nil)
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    */
}
