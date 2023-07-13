//
//  TestVolumnView.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/3/21.
//

import Foundation
import UIKit
import Speech
import AVFoundation

// ViewController
class TestVolumnView: UIViewController, AVCaptureAudioDataOutputSampleBufferDelegate {
    enum ErrorType:Error {
        case 獲取功能失敗
    }
    
    var label = UILabel.createLabel(size: 16, color: .black,text: "0")
    var button = UIButton()

    var captureSession:AVCaptureSession? = AVCaptureSession()
    let captureQueue = DispatchQueue(label: "capture")
    var captureActive = false
    
    var recordTime = Date()
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
        captureSession = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        layout()
        checkAuth()
    }
   
    func setUp() {
        view.layer.contents = Theme.backGroundImage
        setUpNav(title: "音量測試")
        button.setTitle("開始測量音量", for: .normal)
        button.layer.cornerRadius = 15
        button.backgroundColor = Theme.navigationBarBG
        button.addTarget(self, action: #selector(onButtonClick), for: .touchUpInside)
    }
    
    func layout() {
        view.addSubviews(label,button)
        label.centerInSuperview()
        button.centerX(to: view)
        button.bottom(to: view , offset: -70 * Theme.factor)
        button.size(CGSize(width: 200 * Theme.factor, height: 60 * Theme.factor))
    }
    
    func showErrorMsg(_ error:ErrorType? = nil) {
        let alertAction = UIAlertAction(title: "確認", style: .default) { _ in
            self.leftBtnAct()
        }
        
        guard let error = error else { showAlert(alertText: "未知錯誤", alertMessage: "",alertAction: alertAction) ; return }
        switch ( error ) {
        case .獲取功能失敗 :
            showAlert(alertText: "獲取錄音功能錯誤", alertMessage: "",alertAction: alertAction)
        }
    }
    
    private func checkAuth() {
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            setupCaptureSession()
        } else {
          AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
              // 如果一開始不允許使用相機權限，那麼就會再次向使用者要求權限
              // 如果允許則建置 QR code 掃瞄器
              if granted {
                  self.setupCaptureSession()
              } else {
                  // 若是沒有允許使用相機權限，則跳出一個 Alert
                  // 點選取消，那麼就 dismiss 回首頁
                  let alertController = UIAlertController(title: "開啟失敗", message: "請先開啟麥克風權限", preferredStyle: .alert)
                  let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: { _ in
                      self.leftBtnAct()
                  })
                  // 若點選設定，那麼則會跳到此 App 的設定畫面，可以對 App 開啟權限的設定
                  let okAction = UIAlertAction(title: "設定", style: .default, handler: { _ in
                      let url = URL(string: UIApplication.openSettingsURLString)
                      if let url = url, UIApplication.shared.canOpenURL(url) {
                          if #available(iOS 10, *) {
                              UIApplication.shared.open(url, options: [:],
                                                        completionHandler: {
                                                          (success) in
                              })
                          } else {
                              UIApplication.shared.openURL(url)
                          }
                      }
                  })
                  alertController.addAction(cancelAction)
                  alertController.addAction(okAction)
                  self.present(alertController, animated: true, completion: nil)
              }
          })
      }
    }
    
    // キャプチャセッションの準備
    func setupCaptureSession() {
        do {
            if let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio) {
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                let audioDataOut = AVCaptureAudioDataOutput()
                audioDataOut.setSampleBufferDelegate(self, queue: self.captureQueue)
                captureSession?.addInput(audioInput)
                captureSession?.addOutput(audioDataOut)
                captureActive = false
            }
            else {
                throw ErrorType.獲取功能失敗
            }
        }
        catch ErrorType.獲取功能失敗 {
            showErrorMsg(ErrorType.獲取功能失敗)
        }
        catch {
            showErrorMsg()
        }
    }
   
    // バッファ出力を通知
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection) {

        let now = Date()
        if ( now.timeIntervalSince1970 - recordTime.timeIntervalSince1970 < 1 ) {  // 抓取現在時間 單位秒
            return
        }
        
        recordTime = now
        
        var averagePowerLevel: Float = 0
        //var peakHoldLevel: Float = 0
        for audioChannel in connection.audioChannels {
            averagePowerLevel += audioChannel.averagePowerLevel
//peakHoldLevel += audioChannel.peakHoldLevel
        }
        averagePowerLevel = averagePowerLevel/Float(connection.audioChannels.count)
        //peakHoldLevel = peakHoldLevel/Float(connection.audioChannels.count)
       
        //let progress:CGFloat = (1.0 / 160.0) * ( CGFloat(averagePowerLevel) + 160.0);
            
        //averagePowerLevel = averagePowerLevel + 160  - 50;
        
        var db = 20 * (log10(5) + averagePowerLevel/20 + log10(160)) + 50
        //dB = abs(Int(pow(10,averagePowerLevel / 20 ) * 65536))
        //dB = Int(96 - abs(20 * Float(log10( averagePowerLevel / 32767)) ))
        /*if (averagePowerLevel < 0) {
        dB = 0;
        } else if (averagePowerLevel < 40) {
        dB = Int(averagePowerLevel * 0.875);
        } else if (averagePowerLevel < 100) {
        dB = Int(averagePowerLevel - 15);
        } else if (averagePowerLevel < 110) {
        dB = Int(averagePowerLevel * 2.5 - 165);
        } else {
        dB = 110;
        }*/

        DispatchQueue.main.async {
            
            self.label.text = String(format:"%.2f",db)
        }
    }
  
    @objc func onButtonClick(_ sender: UIButton) {
        if (!self.captureActive) {
            self.captureActive = true
            self.button.setTitle("停止取得音量", for: .normal)
            self.label.text = ""

            Task.detached(priority: .background, operation: {
                await self.captureSession?.startRunning()
            })
            
        }
        else {
            self.captureActive = false
            self.button.setTitle("開始測量音量", for: .normal)
            
            Task.detached(priority: .background, operation: {
                await self.captureSession?.stopRunning()
            })
            
        }
    }
}
