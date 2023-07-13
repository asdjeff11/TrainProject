//
//  TakePictureView.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/16.
//

import Foundation
import UIKit
import AVFoundation
import Combine
class TakePictureView : UIViewController {
    enum CameraState {
        case 前鏡頭
        case 後鏡頭
    }
    
    
    var deviceCanUse:Int = 0b00  // 最高bit為前鏡頭 最低bit為後鏡頭
    var state:CameraState = .後鏡頭 {
        didSet {
            do {
                if let backInput = backInput {
                    session.removeInput(backInput)
                }
                if let frontInput = frontInput {
                    session.removeInput(frontInput)
                }
                
                switch ( state ) {
                case .前鏡頭 :
                    try frontInput?.device.lockForConfiguration()
                    frontInput?.device.videoZoomFactor = 1
                    frontInput?.device.unlockForConfiguration()
                    session.addInput(frontInput!)
                case .後鏡頭 :
                    try backInput?.device.lockForConfiguration()
                    backInput?.device.videoZoomFactor = 1
                    backInput?.device.unlockForConfiguration()
                    session.addInput(backInput!)
                }
            }
            catch {
                print(error.localizedDescription)
            }
            
        }
    }
    
    let size : CGFloat = 500 * Theme.factor // 框框大小
    var circlePath = UIBezierPath()
    var preview:UIView!
    var session: AVCaptureSession = AVCaptureSession() // 管理輸入輸出音視訊流
    // 更改畫質方式
    //session.sessionPreset = AVCaptureSession.Preset.vga640x480
    //session.sessionPreset = AVCaptureSession.Preset.iFrame1280x720 //輸出畫質
    
    var stillImageOutput: AVCapturePhotoOutput! // 輸出圖片 ;
    var previewLayer: AVCaptureVideoPreviewLayer! // 顯示當前相機正在採集的狀況
    var frontInput:AVCaptureDeviceInput? // 前鏡頭輸入
    var backInput:AVCaptureDeviceInput? // 後鏡頭輸入
    
    var rotation = 0 // 旋轉角度
    
    let noSupportCameraView = UIView()
    let takePicBtn = UIButton()
    let changeStateBtn = UIButton()
    var cancelList = [AnyCancellable]()
    
    var photoDoneCallBack:((UIImage)->Void)?
    var isLoading = false
    var taskID:UIBackgroundTaskIdentifier?
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        setBtnAct()
        setUpCamera()
        setDefaultData()
        setupLivePreView()
        layout()
        
        Task.detached(priority:.background) { // 開始運行
            await self.session.startRunning()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIButton.intervalTime = 0 // 不要設定按鈕點擊時間間隔
        
        //感知设备方向 - 开启监听设备方向
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        //添加通知，监听设备方向改变
        NotificationCenter.default.addObserver(self, selector: #selector(receivedRotation),
                                               name: UIDevice.orientationDidChangeNotification, object: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIButton.intervalTime = 0.5 // 恢復 防止連續點擊
        DispatchQueue.global(qos:.background).async {
            self.session.stopRunning()
        }
        
        UIDevice.current.endGeneratingDeviceOrientationNotifications() // 取消方向感之
        NotificationCenter.default.removeObserver(self)
        
        if let taskID = taskID {
            self.endBackgroundUpdateTask(taskID: taskID)
        }
        cancelList.removeAll()
        super.viewWillDisappear(animated)
    }
    
}

extension TakePictureView:AVCapturePhotoCaptureDelegate{
    func setBtnAct() {
        takePicBtn.publisher()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] _ in
                guard let self = self else { return }
                if #available(iOS 10, *) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred() // 手機震動
                }
                else {
                    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate)) // 手機震動(比較傳統粗魯的那種)
                }
                self.blackMaskFlash() // 拍完當下的黑色淡出效果
                
                self.loading(isLoading: &self.isLoading)
                self.taskID = self.beginBackgroundUpdateTask()
                // 輸出圖片
                let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
                self.stillImageOutput.capturePhoto(with: settings, delegate: self)
                
            }).store(in: &cancelList)
        
        changeStateBtn.publisher()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] _ in
                guard let self = self else { return }
                let rotation = CABasicAnimation(keyPath: "transform.rotation")
                rotation.fromValue = 0
                rotation.toValue = Double.pi
                rotation.duration = 0.5
                self.changeStateBtn.layer.add(rotation,forKey:nil)
                Task {
                    self.state = (self.state == .前鏡頭) ? .後鏡頭 : .前鏡頭
                }
                
            }).store(in: &cancelList)
        
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        // 剛剛輸出的圖片 會呼叫此function  將photo 轉成image  放入圖片庫當中
        if let data = photo.fileDataRepresentation() {
            DispatchQueue.global(qos:.background).async { [weak self] in
                guard let self = self else { return }
                
                var image = UIImage(data: data)!
                if ( self.state == .前鏡頭 ) { image = UIImage(cgImage: image.cgImage!, scale: 1, orientation: .leftMirrored) } // 鏡像選轉
                
                print("Take and saves in memories")
                image = UIImage.rotateImage(image, withAngle: Double(self.rotation))! // 調正旋轉角度
                image = image.fixOrientation()// 修正角度
                
                
                
                let x = self.circlePath.bounds.origin.x / Theme.fullSize.width * image.size.width
                let y = self.circlePath.bounds.origin.y / Theme.fullSize.height * image.size.height
                let width = self.size / Theme.fullSize.width * image.size.width
                let height = self.size / Theme.fullSize.height * image.size.height
                
                let cropArea = CGRect(x:x,
                                      y:y,
                                      width: width ,
                                      height: height )
                
                let croppedCGImage = (image.cgImage?.cropping(to: cropArea))!
                image = UIImage(cgImage: croppedCGImage)
//                image = UIImage.resize_no_cut(image: image, newSize: CGSize(width: self.size, height: self.size))
//                DispatchQueue.main.async {
//                    AssessPicture.imgs.addImg(img:image)
//                }
                let img = UIImage.scaleImage(image: image, newSize: CGSize(width: self.size, height: self.size))
                Task.detached(operation:{ @MainActor in
                    self.removeLoading(isLoading:&self.isLoading)
                    self.endBackgroundUpdateTask(taskID: self.taskID)
                    self.photoDoneCallBack?(img)
                    self.leftBtnAct()
                })
                
            }
        }
    }
    
}

extension TakePictureView {
    func setUp() {
        setUpNav(title: "拍照", backButtonVisit: true)
        self.view.backgroundColor = .clear
        let photoImage = UIImage.resize_no_cut(image: UIImage(named: "photo")!, newSize: CGSize(width: 150 * Theme.factor, height: 150 * Theme.factor))
        let photoImage_tint = photoImage.withRenderingMode(.alwaysTemplate)
        let cycleImage = UIImage.resize_no_cut(image: UIImage(named: "cycle")!, newSize: CGSize(width: 130 * Theme.factor, height: 130 * Theme.factor))
        let cycleImage_tint = cycleImage.withRenderingMode(.alwaysTemplate)
        
        takePicBtn.setImage(photoImage_tint, for: .normal)
        takePicBtn.tintColor = .white
        
        changeStateBtn.setImage(cycleImage_tint, for: .normal)
        changeStateBtn.tintColor = .white
        
        noSupportCameraView.backgroundColor = .white
        // 手勢縮放功能
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        view.addGestureRecognizer(pinch)
    }
    
    func layout() {
        let bottomView = UIView()
        bottomView.backgroundColor = Theme.navigationBarBG
        
        
        let noSupportLabel = UILabel.createLabel(size: 16, color: .black,alignment: .center, text:"本功能需要實機測試\n請返回上一頁")
        
        
        view.addSubviews(preview, bottomView,noSupportLabel)
        noSupportCameraView.addSubview(noSupportLabel)
        bottomView.addSubviews(takePicBtn,changeStateBtn)
        
        noSupportLabel.centerYToSuperview()
        noSupportLabel.centerXToSuperview()
        noSupportLabel.size(CGSize(width: 500 * Theme.factor, height: 500 * Theme.factor))
        
        preview.edgesToSuperview()
        
        bottomView.bottomToSuperview()
        bottomView.widthToSuperview()
        bottomView.height(250 * Theme.factor)
        bottomView.centerXToSuperview()
        
        takePicBtn.centerInSuperview()
        takePicBtn.size(CGSize(width: 150 * Theme.factor, height: 150 * Theme.factor))
        
        changeStateBtn.centerYToSuperview()
        changeStateBtn.trailingToSuperview(offset: 70 * Theme.factor)
        changeStateBtn.size(CGSize(width: 130 * Theme.factor, height: 130 * Theme.factor))
        
        view.bringSubviewToFront(bottomView)
    }
    
    func setDefaultData() {
        if ( deviceCanUse == 0b00 ) {
            view.backgroundColor = .white
        }
        else { // set session
            view.backgroundColor = .clear
            noSupportCameraView.isHidden = true
            
            // 設定輸出
            stillImageOutput = AVCapturePhotoOutput()
            session.addOutput(stillImageOutput)
            // 設定輸入
            if ( deviceCanUse & 0b01 == 0b01 ) { // 後鏡頭可以用 先用後鏡頭
                state = .後鏡頭
            }
            else {
                state = .前鏡頭
            }
            
            if ( deviceCanUse != 0b11) { // 只有提供一個鏡頭
                changeStateBtn.isHidden = true
            }
        }
    }
}

extension TakePictureView {
    func layer(x: CGFloat,y: CGFloat,width: CGFloat,height: CGFloat,cornerRadius: CGFloat) // 畫框框 在 preview 上
    {
        let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: Theme.fullSize.height, height: Theme.fullSize.height))
        circlePath = UIBezierPath(roundedRect: CGRect(x: x, y: y, width: width, height: height), cornerRadius: cornerRadius)
        path.append(circlePath)
        path.usesEvenOddFillRule = true
        let fillLayer = CAShapeLayer()
        fillLayer.path = path.cgPath
        fillLayer.fillRule = CAShapeLayerFillRule.evenOdd
        fillLayer.opacity = 0.7
        fillLayer.fillColor = UIColor.lightGray.cgColor
        preview.layer.addSublayer(fillLayer)
    }
    
    func setupLivePreView() {
        preview = UIView(frame: view.frame)
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        // AVLayerVideoGravityResizeAspect: 保持解析度比例,如果螢幕解析度與視訊解析度不一致會留下黑邊.
        // AVLayerVideoGravityResizeAspectFill: 保持解析度比例去填充螢幕,即以較小的邊來準填充螢幕,會犧牲掉一些畫素,因為超出螢幕.
        // AVLayerVideoGravityResize:以拉伸的方式來填充螢幕,不會犧牲畫素,但是畫面會被拉伸.
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.connection!.videoOrientation = .portrait
        
        previewLayer.frame = CGRect(x: 0, y: 0, width: Theme.fullSize.width, height: Theme.fullSize.height)
        
        preview.layer.addSublayer(previewLayer)
        
        layer(x: (self.view.frame.size.width / 2) - (size/2), y: preview.frame.size.height/2 - size/2, width: size, height: size, cornerRadius: 0) // 加入框框於畫面上
    }
}

extension TakePictureView {
    func setUpCamera() {
        if let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            do {
                // 調整相機功能時都要先鎖起來
                try camera.lockForConfiguration()
                // 調整曝光(隨時監測亮度)
                camera.exposureMode = .continuousAutoExposure
                // 調整曝光時間，不然拍照的那一下手會抖導致照片會糊
                camera.activeMaxExposureDuration = CMTime(seconds: 0.02, preferredTimescale: CMTimeScale(0.005))
                // 解鎖
                camera.unlockForConfiguration()
                
                frontInput = try AVCaptureDeviceInput(device: camera)
                deviceCanUse |= 0b10
            }
            catch {
                print("前鏡頭功能失敗:" + error.localizedDescription)
            }
        }
        
        if let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            do {
                // 調整相機功能時都要先鎖起來
                try camera.lockForConfiguration()
                // 調整曝光(隨時監測亮度)
                camera.exposureMode = .continuousAutoExposure
                // 調整曝光時間，不然拍照的那一下手會抖導致照片會糊
                camera.activeMaxExposureDuration = CMTime(seconds: 0.02, preferredTimescale: CMTimeScale(0.005))
                // 解鎖
                camera.unlockForConfiguration()
                
                backInput = try AVCaptureDeviceInput(device: camera)
                deviceCanUse |= 0b01
            }
            catch {
                print("後鏡頭功能失敗:" + error.localizedDescription)
            }
        }
    } // setUpCamera
}

extension TakePictureView {
    @objc func receivedRotation(){ // 透過手機陀螺儀判斷旋轉方向
        let device = UIDevice.current
           switch device.orientation{
           case .portrait:
                rotation = 0
                print("面向设备保持垂直，Home键位于下部")
           case .portraitUpsideDown:
                rotation = 180
                print("面向设备保持垂直，Home键位于上部")
           case .landscapeLeft:
                rotation = 270
                print("面向设备保持水平，Home键位于右侧")
           case .landscapeRight:
                rotation = 90
                print("面向设备保持水平，Home键位于左侧")
           case .faceUp:
                print("设备平放，Home键朝上")
           case .faceDown:
                print("设备平放，Home键朝下")
           case .unknown:
                print("方向未知")
               default:
                print("方向未知")
           }
    } // 透過手機陀螺儀判斷旋轉方向
}

extension TakePictureView {
    
    // 拍完當下的黑色淡出效果
    private func blackMaskFlash() {
        let tmpMask = UIView(frame: CGRect(x: 0, y: 0, width: Theme.fullSize.width, height: Theme.fullSize.height))
        tmpMask.backgroundColor = .black
        preview.addSubview(tmpMask)
        preview.bringSubviewToFront(tmpMask)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveLinear) {
            tmpMask.alpha = 0
        } completion: { _ in
            tmpMask.removeFromSuperview()
        }
    }
    
    // 視角縮小
    @objc func zoomOut() {
        
        // 改變相機裝置鏡頭縮放程度
        guard let camera = ( state == .前鏡頭 ?  frontInput?.device : backInput?.device ) else { return }

        if camera.videoZoomFactor > 1.0 { // 最遠距離為 1
            let newZoomFactor = max(camera.videoZoomFactor - 0.5 , 1.0)
            do {
                // 縮放前先獲取裝置的鎖
                try camera.lockForConfiguration()
                // 讓不同縮放因子能夠平滑轉換
                camera.ramp(toVideoZoomFactor: newZoomFactor, withRate: 3) // withRate 縮放速度
                // 新的縮放因子完成縮放效果後，解鎖
                camera.unlockForConfiguration()
            } catch {
                print(error)
            }
        }
    }

    // 視角放大
    @objc func zoomIn() {
        
        // 改變相機裝置鏡頭縮放程度
        guard let camera = ( state == .前鏡頭 ?  frontInput?.device : backInput?.device ) else { return }
        
        if camera.videoZoomFactor < 5.0 { // 如果現在比例 < 5 則開始放大
            let newZoomFactor = min(camera.videoZoomFactor + 0.25 , 5.0) // 取最小值 最大到 5 倍
            do {
                // 縮放前先獲取裝置的鎖
                try camera.lockForConfiguration()
                // 讓不同縮放因子能夠平滑轉換
                camera.ramp(toVideoZoomFactor: newZoomFactor, withRate: 5) // withRate 縮放速度
                // 新的縮放因子完成縮放效果後，解鎖
                camera.unlockForConfiguration()
            } catch {
                print(error)
            }
        }
    }
    
    
    @objc func handlePinch(gesture: UIPinchGestureRecognizer) {
        let beginScale = 1.0
        if gesture.state == .changed { // gesture 為 使用者縮放的比例 ( 不是相機目前縮放比例 )
            (beginScale < gesture.scale) ? zoomIn() : zoomOut()
        }
    }
    
}
