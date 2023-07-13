//
//  Extension.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2022/9/1.
//
import UIKit
import Combine
extension UIColor {
    convenience init(hex:Int, alpha:CGFloat = 1.0) {
        self.init(
            red:   CGFloat((hex & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((hex & 0x00FF00) >> 8)  / 255.0,
            blue:  CGFloat((hex & 0x0000FF) >> 0)  / 255.0,
            alpha: alpha
        )
    }
}


extension UIView {
    func addSubviews(_ views:UIView...) {
        if let stackView = self as? UIStackView {
            for view in views {
                stackView.addArrangedSubview(view)
            }
        }
        else {
            for view in views {
                addSubview(view)
            }
        }
    }
 
    func clearConstraints() {
        for subview in self.subviews {
            subview.clearConstraints()
        }
        self.removeConstraints(self.constraints)
    }
}

extension NSLayoutConstraint {
    public class func useAndActivateConstraints(constraints: [NSLayoutConstraint]) {
        for constraint in constraints {
            if let view = constraint.firstItem as? UIView {
                 view.translatesAutoresizingMaskIntoConstraints = false
            }
        }
        activate(constraints)
    }
}

// 防止按钮连点
public extension UIButton {
    private struct AssociatedKeys {
        static var eventInterval = "eventInterval"
        static var eventUnavailable = "eventUnavailable"
    }
    
    static var intervalTime:TimeInterval = 0.5
    /// 重复点击的时间 属性设置
    var eventInterval: TimeInterval {
        get {
            if let interval = objc_getAssociatedObject(self, &AssociatedKeys.eventInterval) as? TimeInterval {
                return interval
            }
            return UIButton.intervalTime
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.eventInterval, newValue as TimeInterval, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// 按钮不可点 属性设置
    private var eventUnavailable : Bool {
        get {
            if let unavailable = objc_getAssociatedObject(self, &AssociatedKeys.eventUnavailable) as? Bool {
                return unavailable
            }
            return false
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.eventUnavailable, newValue as Bool, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// 新建初始化方法,在这个方法中实现在运行时方法替换
    class func initializeMethod() {
        let selector = #selector(UIButton.sendAction(_:to:for:))
        let newSelector = #selector(new_sendAction(_:to:for:))
        
        let method: Method = class_getInstanceMethod(UIButton.self, selector)!
        let newMethod: Method = class_getInstanceMethod(UIButton.self, newSelector)!
        
        if class_addMethod(UIButton.self, selector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)) {
            class_replaceMethod(UIButton.self, newSelector, method_getImplementation(method), method_getTypeEncoding(method))
        } else {
            method_exchangeImplementations(method, newMethod)
        }
    }

    /// 在这个方法中
    @objc private func new_sendAction(_ action: Selector, to target: Any?, for event: UIEvent?) {
        if eventUnavailable == false {
            eventUnavailable = true
            new_sendAction(action, to: target, for: event)
            // 延时
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + eventInterval, execute: {
                self.eventUnavailable = false
            })
        }
    }
}


extension Date {
    func getNextMonth() -> Date? { // 取得下個月份
        return Calendar.current.date(byAdding: .month, value: 1, to: self)
    } // 取得下個月份

    func getPreviousMonth() -> Date? { // 取得上個月份
        return Calendar.current.date(byAdding: .month, value: -1, to: self)
    } // 取得上個月份
    
    func dayDiff(toDate:Date)->Int { // 相差多少日
        // toDate - self
        let component = Calendar.current.dateComponents([.day], from: self,to: toDate)
        return component.day ?? 0
    }
    
    func getOffsetDay( type:Calendar.Component , offset:Int)->Date {
        return Calendar.current.date( byAdding: type, value: offset, to:self)!
    }
    
    func countOfDaysInMonth()->Int { // 當月天數
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let range = ( calendar as NSCalendar?)?.range(of: NSCalendar.Unit.day, in: NSCalendar.Unit.month, for: self)
        return (range?.length)!
    }
    
    /// 重載運算子 時間互減
    static func -(d1:Date,d2:Date)->Double {
        let timePassSec = d1.timeIntervalSince1970 - d2.timeIntervalSince1970
        return Double(String(format: "%.3f", timePassSec))!
    }
}

extension UITableView {
    func reloadDataTop() {
        self.reloadData()
        self.layoutIfNeeded()
        self.scrollToTop()
    }
    
    func scrollToTop() {
        if visibleCells.count == 0 { return }
        scrollToRow(at: [0,0], at: .top, animated: true)
        setContentOffset(.zero, animated: true)
    }
    
    func animateTable() {
        self.reloadDataTop()
        
        let cells = self.visibleCells
        let tableHeight: CGFloat = self.bounds.size.height
        
        for i in cells {
            let cell: UITableViewCell = i as UITableViewCell
            cell.transform = CGAffineTransform(translationX: 0, y: tableHeight)
        }
        
        var index = 0
        for a in cells {
            let cell: UITableViewCell = a as UITableViewCell
            UIView.animate(withDuration: 0.6, delay: 0.05 * Double(index), usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: .allowAnimatedContent, animations: {
                cell.transform = CGAffineTransform(translationX: 0, y: 0);
            }, completion: nil)
            index += 1
        }
    } // animate update Table
}

extension UICollectionView {
    
    func reloadDataTop() {
        self.reloadData()
        self.layoutIfNeeded()
        self.scrollToTop()
    }
    
    func scrollToTop() {
        if visibleCells.count == 0 { return }
//        self.scrollToItem(at: [0,0], at: .top, animated: true)
        setContentOffset(.zero, animated: true)
    }
    
}

extension UIImage {
    static func rotateImage(_ image: UIImage, withAngle angle: Double) -> UIImage? { // 旋轉圖片
        if angle.truncatingRemainder(dividingBy: 360) == 0 { return image }
        let imageRect = CGRect(origin: .zero, size: image.size)
        let radian = CGFloat(angle / 180 * Double.pi)
        let rotatedTransform = CGAffineTransform.identity.rotated(by: radian)
        var rotatedRect = imageRect.applying(rotatedTransform)
        rotatedRect.origin.x = 0
        rotatedRect.origin.y = 0
        UIGraphicsBeginImageContext(rotatedRect.size)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.translateBy(x: rotatedRect.width / 2, y: rotatedRect.height / 2)
        context.rotate(by: radian)
        context.translateBy(x: -image.size.width / 2, y: -image.size.height / 2)
        image.draw(at: .zero)
        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rotatedImage
    } // 旋轉圖片
    func fixOrientation() -> UIImage{ // 防止ios自動旋轉
        if self.imageOrientation == UIImage.Orientation.up {
            return self
        }
        
        var transform = CGAffineTransform.identity
        
        switch self.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: self.size.width, y: self.size.height)
            transform = transform.rotated(by: CGFloat(Double.pi));
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: self.size.width, y: 0);
            transform = transform.rotated(by: CGFloat(Double.pi / 2));
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: self.size.height);
            transform = transform.rotated(by: CGFloat(-Double.pi / 2));
        case .up, .upMirrored:
            break
        @unknown default:
            break
        }
        
        switch self.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: self.size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1);
        default:
            break;
        }
        
        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        let ctx = CGContext(
            data: nil,
            width: Int(self.size.width),
            height: Int(self.size.height),
            bitsPerComponent: self.cgImage!.bitsPerComponent,
            bytesPerRow: 0,
            space: self.cgImage!.colorSpace!,
            bitmapInfo: UInt32(self.cgImage!.bitmapInfo.rawValue)
        )
        
        ctx!.concatenate(transform);
        
        switch self.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            // Grr...
            ctx?.draw(self.cgImage!, in: CGRect(x:0 ,y: 0 ,width: self.size.height ,height:self.size.width))
        default:
            ctx?.draw(self.cgImage!, in: CGRect(x:0 ,y: 0 ,width: self.size.width ,height:self.size.height))
            break;
        }
        
        // And now we just create a new UIImage from the drawing context
        let cgimg = ctx!.makeImage()
        let img = UIImage(cgImage: cgimg!)
        
        return img;
    }  // 防止ios自動旋轉
    
    func toCircle() -> UIImage { // 將圖片轉成圓型
        //取最短边长
        let shotest = min(self.size.width, self.size.height)
        //输出尺寸
        let outputRect = CGRect(x: 0, y: 0, width: shotest, height: shotest)
        //开始图片处理上下文（由于输出的图不会进行缩放，所以缩放因子等于屏幕的scale即可）
        UIGraphicsBeginImageContextWithOptions(outputRect.size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return self }
        //添加圆形裁剪区域
        context.addEllipse(in: outputRect)
        context.clip()
        //绘制图片
        self.draw(in: CGRect(x: (shotest-self.size.width)/2,
                             y: (shotest-self.size.height)/2,
                             width: self.size.width,
                             height: self.size.height))
        //获得处理后的图片
        let maskedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return maskedImage ?? UIImage()
    } // 將圖片轉成圓型
    
    // 調整圖片大小  最小邊 變成設定的數值 其餘裁切
    // 小編比例縮放到定位後 切掉多餘的大邊
    
    static func scaleImage(image:UIImage, newSize:CGSize)->UIImage {
        //        获得原图像的尺寸属性
        let imageSize = image.size
        //        获得原图像的宽度数值
        let width = imageSize.width // 500
        //        获得原图像的高度数值
        let height = imageSize.height // 421

        //        计算图像新尺寸与旧尺寸的宽高比例
        let widthFactor = newSize.width/width // 0.115
        let heightFactor = newSize.height/height // 0.136579
        //        获取小邊的比例
        let scalerFactor = (widthFactor > heightFactor) ? widthFactor : heightFactor // 0.136579

        //        计算图像新的高度和宽度，并构成标准的CGSize对象
        let scaledWidth = width * scalerFactor // 68.289
        let scaledHeight = height * scalerFactor // 57.49999
        let targetSize = CGSize(width: scaledWidth, height: scaledHeight)

        //        创建绘图上下文环境，
        UIGraphicsBeginImageContextWithOptions(targetSize,false,0.0)
        image.draw(in: CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight))
        //        获取上下文里的内容，将视图写入到新的图像对象
        var newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // 裁截
        let newWidth = newSize.width
        let newHeight = newSize.height
        
        let renderer = UIGraphicsImageRenderer(size:newSize)
        if let img = newImage {
            let x = -( img.size.width - newWidth ) / 2
            let y = -( img.size.height - newHeight ) / 2
            newImage = renderer.image { (context) in
                img.draw(at: CGPoint(x: x, y: y))
            }
        }
        return newImage ?? image

    } // 調整圖片大小
    
    static func resize_no_cut(image:UIImage , newSize:CGSize)->UIImage { // 短邊縮放置 對應長度  長編會超出比例
        // 获得原图像的尺寸属性
        let imageSize = image.size
        // 获得原图像的宽度数值
        let width = imageSize.width
        // 获得原图像的高度数值
        let height = imageSize.height
        // 取最大的縮小因子
        let factor = min(newSize.width/width,newSize.height/height)
        // 比例縮放
        let scaledWidth = width * factor
        let scaledHeight = height * factor
        let targetSize = CGSize(width: scaledWidth, height: scaledHeight) // 獲取全新的size
        //        创建绘图上下文环境，
        
        //UIGraphicsBeginImageContext(targetSize)
        UIGraphicsBeginImageContextWithOptions(targetSize,false,0.0)
        image.draw(in: CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight))
        //        获取上下文里的内容，将视图写入到新的图像对象
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    //返回一个将白色背景变透明的UIImage
    func imageByRemoveWhiteBg() -> UIImage? {
        let colorMasking: [CGFloat] = [222, 255, 222, 255, 222, 255]
        return transparentColor(colorMasking: colorMasking)
    }
     
    //返回一个将黑色背景变透明的UIImage
    func imageByRemoveBlackBg() -> UIImage? {
        let colorMasking: [CGFloat] = [0, 32, 0, 32, 0, 32]
        return transparentColor(colorMasking: colorMasking)
    }
     
    func transparentColor(colorMasking:[CGFloat]) -> UIImage? {
        if let rawImageRef = self.cgImage {
            UIGraphicsBeginImageContext(self.size)
            if let maskedImageRef = rawImageRef.copy(maskingColorComponents: colorMasking) {
                let context: CGContext = UIGraphicsGetCurrentContext()!
                context.translateBy(x: 0.0, y: self.size.height)
                context.scaleBy(x: 1.0, y: -1.0)
                context.draw(maskedImageRef, in: CGRect(x:0, y:0, width:self.size.width,
                                                        height:self.size.height))
                let result = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                return result
            }
        }
        return nil
    }
}

extension UIApplication {
    static func topViewController(base: UIViewController? = UIApplication.shared.delegate?.window??.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(base: selected)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
    
    static func getLastViewController()->UIViewController? {
        let nav:UINavigationController = shared.delegate?.window??.rootViewController as! UINavigationController
        return nav.viewControllers.last
    }
}

extension UIStackView {
    var count:Int {
        get { return countStack(self) }
    }
    
    func countStack(_ stackView:UIStackView)->Int {
        var counter = 0
        for _ in stackView.subviews { counter += 1 }
        return counter
    }
    
    func removeAllArrangedSubviews() {
        arrangedSubviews.forEach {
            self.removeArrangedSubview($0)
            NSLayoutConstraint.deactivate($0.constraints)
            $0.removeFromSuperview()
        }
    }
}

extension Array {
    public func toDictionary<Key: Hashable>(with selectKey: (Element) -> Key) -> [Key:Element] {
        var dict = [Key:Element]()
        for element in self {
            dict[selectKey(element)] = element
        }
        return dict
    }
    
    func contains<T>(obj: T) -> Bool where T : Equatable {
        return self.filter({$0 as? T == obj}).count > 0
    }
}

extension UIViewController {
    func setUpNav(title:String,backButtonVisit:Bool = false, rightButton:UIButton? = nil, homeButtonRemove:Bool = false ) {
        if ( self.title == title ) { return }
        self.title = title
        if #available(iOS 15, *) {
            let navigationBarAppearance = UINavigationBarAppearance()
            navigationBarAppearance.configureWithDefaultBackground()
            navigationBarAppearance.backgroundColor = Theme.navigationBarBG
            navigationBarAppearance.titleTextAttributes = [
               .foregroundColor: UIColor.white,
               .font: Theme.navigationBarTitleFont ?? UIFont()
            ]
           
            navigationItem.setHidesBackButton(true, animated: true)
            navigationItem.scrollEdgeAppearance = navigationBarAppearance
            navigationItem.standardAppearance = navigationBarAppearance
            navigationItem.compactAppearance = navigationBarAppearance
            navigationController?.setNeedsStatusBarAppearanceUpdate()
        }
        else {
            self.navigationController?.navigationBar.barTintColor = Theme.navigationBarBG
            self.navigationController?.navigationBar.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor.white,
                NSAttributedString.Key.font: Theme.navigationBarTitleFont ?? UIFont()
            ]
        }
        
        let homeButton = UIButton(frame: Theme.navigationBtnSize)
        var img = UIImage.scaleImage(image: UIImage(named: "home")!, newSize: Theme.navigationBtnSize.size)
        homeButton.tintColor = .white
        homeButton.setImage(img, for: .normal)
        homeButton.addTarget(self, action: #selector(home), for: .touchUpInside)
        
        let backButton = UIButton(frame: Theme.navigationBtnSize)
        img = UIImage.scaleImage(image: UIImage(named: "back")!, newSize: Theme.navigationBtnSize.size)
        img.withTintColor(.white)
        backButton.tintColor = .white
        backButton.setImage(img, for: .normal)
        backButton.addTarget(self, action: #selector(leftBtnAct), for: .touchUpInside)
       
        
        var array:[UIBarButtonItem] = []
        
        if ( backButtonVisit == true ) {
            array.append(UIBarButtonItem(customView: backButton))
        }
       
        if ( homeButtonRemove == false ) {
            array.append(UIBarButtonItem(customView: homeButton))
        }
        
        self.navigationItem.leftBarButtonItems = array
        
        if let rightButton = rightButton {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightButton)
        }
    }
    
    @objc func viewWillTerminate() {
        
    }
    
    @objc func home() {
        viewWillTerminate()
        guard let vc = navigationController?.viewControllers.filter({ (vc) -> Bool in
            return vc is MainViewController
        })[0] else { return }
        navigationController?.popToViewController(vc, animated: true)
    }
    
    @objc func leftBtnAct() {
        viewWillTerminate()
        _ = navigationController?.popViewController(animated: true)
    }
    
    func loading(isLoading:inout Bool) { // 參數是給有需要的使用 不需要的 無視即可
        if( isLoading ) { return }
        spinner.view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        view.addSubview(spinner.view)
        addChild(spinner)
        spinner.didMove(toParent: self)
        isLoading = true
    }
    
    func removeLoading(isLoading:inout Bool) {
        if ( isLoading == false ) { return }
        spinner.willMove(toParent: nil)
        spinner.view.removeFromSuperview()
        spinner.removeFromParent()
        isLoading = false
    }
    
    func addViewToPresent(viewController: UIViewController) {
        viewController.providesPresentationContextTransitionStyle = true
        viewController.definesPresentationContext = true
        viewController.modalTransitionStyle = .crossDissolve
        viewController.modalPresentationStyle = .overCurrentContext
        self.present(viewController, animated: true)
    }
    
    func addViewToPresentAnimation( viewController:UIViewController ,center:CGPoint,animation:CustomTransition ) {
        animation.destinationPoint = center
        viewController.transitioningDelegate = animation
        viewController.modalPresentationStyle = .custom
        present(viewController, animated: true, completion: nil)
    }
    
    func showAlert(alertText: String, alertMessage: String, dissmiss: Bool = false, alertAction: UIAlertAction? = nil) {
        #if DEBUG
            let mes = alertMessage
        #else
            let mes = (alertText.hasSuffix("錯誤") || alertText == "建立失敗" || alertText == "儲存失敗" ) ? "連線錯誤" : alertMessage
        #endif
        
        DispatchQueue.main.async {
            let alert = UIAlertController(title: alertText, message: mes, preferredStyle: UIAlertController.Style.alert)
            if let alertAction = alertAction {
                alert.addAction(alertAction)
            }
            else {
                let closeAction = UIAlertAction(title: "確定", style: .default){ [unowned self] (_) in
                    if ( dissmiss == true ) {
                        self.dismiss(animated: true)
                    }
                }
                alert.addAction(closeAction)
            }
            
            guard let _ = self.viewIfLoaded?.window,self.presentedViewController == nil else { return }
            self.present(alert, animated: true, completion: nil)
//            print("self:\(self)")
//            print("self.presentedVC:\(String(describing: self.presentedViewController))\n")
        }
    }
    
    func beginBackgroundUpdateTask() -> UIBackgroundTaskIdentifier {
        return UIApplication.shared.beginBackgroundTask(expirationHandler: ({}))
    }

    func endBackgroundUpdateTask(taskID: UIBackgroundTaskIdentifier?) {
        if let taskID = taskID {
            UIApplication.shared.endBackgroundTask(taskID)
        }
    }
    
    // 重載整個頁面
    func reloadViewFromNib() {
        NotificationCenter.default.removeObserver(self)
        let parent = view.superview
        view.removeFromSuperview()
        view = nil
        parent?.addSubview(view) // This line causes the view to be reloaded
    }
    
    @objc func bindViewModel( viewModel: ViewModelActivity ) {
        viewModel.showLoading = { [weak self] ( isloading:inout Bool ) in
            self?.loading(isLoading: &isloading)
            if let vc = self as? UITableViewController {
                self?.removeReFreshControl(vc)
            }
        }
        viewModel.removeLoading = { [weak self] ( isloading:inout Bool ) in
            self?.removeLoading(isLoading: &isloading)
            if let vc = self as? UITableViewController {
                vc.createReFreshControl(vc)
                if let refresh = vc.refreshControl {
                    if ( refresh.isRefreshing ) {
                        refresh.endRefreshing()
                        // 推頂
                        let index = IndexPath(row: 0, section: 0)
                        if ( vc.tableView.cellForRow(at: index)) != nil {
                            vc.tableView.scrollToRow(at: index, at: .top, animated: true)
                        }
                    }
                }
            }
        }
        viewModel.showAlert = { [weak self] (text:String , mes:String) in
            self?.showAlert(alertText: text, alertMessage: mes)
        }
        
//        viewModel.showAlert2 = { [weak self] (text:String , mes:String, testAG:Int) in
//            if testAG > 1 { viewModel.showAlert2(text, mes, testAG - 1) }
//            self?.showAlert(alertText: text, alertMessage: mes)
//        }
    }
    
    // 底下三個 為了 UITableViewController 而生的  因為 spinner 擋不住 UITableViewController 故 使用底下來抵擋
    private func removeReFreshControl(_ vc:UITableViewController) {
        vc.refreshControl = nil
    }
    
    private func createReFreshControl(_ vc:UITableViewController) {
        if ( vc.refreshControl != nil ) { return }
        vc.refreshControl = UIRefreshControl()
        vc.refreshControl!.tintColor = .white
        vc.refreshControl!.attributedTitle = NSAttributedString(string: "Loading",attributes: [NSAttributedString.Key.foregroundColor : UIColor.white])
        vc.refreshControl!.addTarget(self, action: #selector(tableViewControllerRefreshData), for: UIControl.Event.valueChanged)
    }
    
    @objc func tableViewControllerRefreshData() {
        // 如果沒有override 直接 取消
        if let vc = self as? UITableViewController {
            if let refresh = vc.refreshControl {
                if ( refresh.isRefreshing ) {
                    refresh.endRefreshing()
                }
            }
        }
    }
}

class CustomTransition: NSObject, UIViewControllerTransitioningDelegate {
    // 擴散的中心點
    var destinationPoint = CGPoint.zero
 
    private lazy var presentAnimation = CustomPresentAnimation(startPoint: destinationPoint)
    private lazy var dismissAnimation = CustomDismissAnimation(endPoint: destinationPoint)
 
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
        return presentAnimation
    }
 
    func animationController(forDismissed dismissed: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
        return dismissAnimation
    }
}

class CustomPresentAnimation: NSObject , UIViewControllerAnimatedTransitioning {
    var startPoint: CGPoint // 擴散的起始點
    private let durationTime = 0.45 // 動畫時間
 
    init(startPoint: CGPoint) {
        self.startPoint = startPoint
        super.init()
    }
 
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return durationTime
    }
 
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // 取出 toView, 在上面的示意圖中代表的就是 A 畫面
        guard let toView = transitionContext.viewController(forKey: .to)?.view else {
            return
        }

        // 取出 container view
        let containerView = transitionContext.containerView

        // 建立我們的 mask view，並坐初步設置
        let maskView = UIView()
        maskView.frame.size = CGSize(width: 1, height: 1)
        maskView.center = startPoint
        maskView.backgroundColor = .black
        maskView.layer.cornerRadius = 0.5
        toView.mask = maskView
        containerView.addSubview(toView)

        // 因為最終 mask view 的圓，需要覆蓋到整個畫面，所以計算出 mask view需要的大小
        let containerFrame = containerView.frame
        let maxY = max(containerFrame.height - startPoint.y, startPoint.y)
        let maxX = max(containerFrame.width - startPoint.x, startPoint.x)
        let maxSize = max(maxY, maxX) * 2.5

        // 最後我們使用 UIView.animation 顯式動畫，將我們的 mask view 擴散到整個畫面
        UIView.animate(
                withDuration: durationTime,
                delay: 0,
                options: [.curveEaseOut],
                animations: {
                        maskView.frame.size = CGSize(width: maxSize, height: maxSize)
                        maskView.layer.cornerRadius = maxSize / 2.0
                        maskView.center = self.startPoint
        }) { (flag) in
                transitionContext.completeTransition(flag)
        }
    }
}

class CustomDismissAnimation: NSObject , UIViewControllerAnimatedTransitioning {
    let endPoint: CGPoint
    var grayView: UIView!
    private let durationTime = 0.45
    init(endPoint: CGPoint) {
        self.endPoint = endPoint
        super.init()
    }
 
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return durationTime
    }
 
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.viewController(forKey: .from)?.view else {
            return
        }
 
        let containerView = transitionContext.containerView
 
        let containerFrame = containerView.frame
        let maxY = max(containerFrame.height - endPoint.y, endPoint.y)
        let maxX = max(containerFrame.width - endPoint.x, endPoint.x)
        let maxSize = max(maxY, maxX) * 2.1
 
        let maskView = UIView()
        maskView.frame.size = CGSize(width: maxSize, height: maxSize)
        maskView.center = endPoint
        maskView.backgroundColor = .black
        maskView.layer.cornerRadius = maxSize / 2.0
 
        fromView.mask = maskView
 
        containerView.addSubview(fromView)
 
        UIView.animate(
            withDuration: durationTime,
            delay: 0,
            options: [.curveEaseOut],
            animations: {
                maskView.frame.size = CGSize(width: 1, height: 1)
                maskView.layer.cornerRadius = 0.5
                maskView.center = self.endPoint
        }) { (flag) in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

class TextField: UITextField {

    let padding = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)

    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
}

extension UILabel {
    static func createLabel(size:CGFloat,color:UIColor,alignment:NSTextAlignment? = nil,alpha:CGFloat? = nil,text:String = "")->UILabel {
        let label = UILabel()
        label.font = Theme.labelFont.withSize(size)
        label.textColor = color
        if ( text != "") {
            label.text = text
        }
        
        if let alignment = alignment {
            label.textAlignment = alignment
        }
        if let alpha = alpha {
            label.backgroundColor = UIColor(white:0 ,alpha: alpha)
        }
        return label
    }
}



extension Publishers {
    private final class UIControlSubscription<S:Subscriber,Control:UIControl>:Subscription where S.Input == Control, S.Failure == Never {
        private var subscriber:S?
        private let control:Control
        private let event:Control.Event
        
        init(subscriber:S, control:Control, event:Control.Event) {
            self.subscriber = subscriber
            self.control = control
            self.event = event
            subscribe()
        }
        
        deinit {
            print("subscribtion deinit")
        }
        
        func request(_ demand: Subscribers.Demand) { // 限制只能接收多少資訊
            
        }
        
        func cancel() {
            subscriber = nil
        }
        
        private func subscribe() { // 創建時 呼叫 (init那邊)
            self.control.addTarget(self, action: #selector(eventHandler), for: self.event)
        }
        
        @objc private func eventHandler() {
            // 發布 訊息
            _ = subscriber?.receive(self.control) // 呼叫 Publisher 的 map 對資料做加工  反回觸發的元件讓他去判斷
        }
    }
    
    struct UIControlPublisher<Control:UIControl>:Publisher {
        // 底下兩個為 Publisher Protocol , OutPut 為 要監聽的元件 , Failure 為 失敗事件
        typealias Output = Control
        typealias Failure = Never
        
        let control:Control
        let controlEvent:UIControl.Event
        
        init(control:Control, event:UIControl.Event) {
            self.control = control
            self.controlEvent = event
        }
        
        // 實現這個方法 將調用 subscribe(_:)  訂閱的訂閱者附加到發布者上  subscriber -> subscription publisher
        func receive<S>(subscriber:S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input { // 外部呼叫 sink 時  呼叫此  代表要訂閱了 ( 這是 Publisher 的 protocol )
            let subscription = UIControlSubscription(subscriber: subscriber, control: control, event: controlEvent) // 建立 Subscription
            // subscriber receive 時 主動調用subscription的 request 方法
            subscriber.receive(subscription: subscription) // 訂閱
        }
        
        // 將訂閱者附加到發布者上 內部將調用receive方法
        /*func subscribe<S>(_ subscriber:S ) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
           
        }*/
    }
}

extension String {
    //返回第一次出现的指定子字符串在此字符串中的索引
    //（如果backwards参数设置为true，则返回最后出现的位置）
    func positionOf(sub:String, backwards:Bool = false)->Int {
        var pos = -1
        if let range = range(of:sub, options: backwards ? .backwards : .literal ) {
            if !range.isEmpty {
                pos = self.distance(from:startIndex, to:range.lowerBound)
            }
        }
        return pos
    }
    
    var base64String: String {
        return Data(utf8).base64EncodedString()
    }
    var hexa2Bytes: [UInt8] {
        let hexa = Array(self)
        return stride(from: 0, to: count, by: 2).compactMap { UInt8(String(hexa[$0..<$0.advanced(by: 2)]), radix: 16) }
    }
    
    /// 字串補 base64 的等號（不然他會轉譯失敗）
    private func addBase64EqualString(_ str:String)->String {
        let addCount = str.count == 0 ? 0 : (3 - ((str.count - 1)%3 + 1))
        var equalSign = ""
        for _ in 0..<addCount { equalSign += "=" }
        return str + equalSign
    }
    
    /// 變完整的Base64再轉成 Hex(16進位) 型態
    var HexBase64Hash:String {
        let urlTurnStr = self.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        return Data(base64Encoded: addBase64EqualString(urlTurnStr))!.hexEncodedString()
    }
    
    func jsonToDictionary() throws -> [String: Any] {
        guard let data = self.data(using: .utf8) else { return [:] }
        let anyResult: Any = try JSONSerialization.jsonObject(with: data, options: [])
        return anyResult as? [String: Any] ?? [:]
    }
    
    func stringToDictionary()-> [String:String] {
        let list = self.replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: "").components(separatedBy: ",")
        var dict:[String:String] = [:]
        for item in list {
            let argument = item.replacingOccurrences(of: "\"", with: "").components(separatedBy: ":")
            dict[argument[0]] = argument[1]
        }
        return dict
    }
    
    //使用正則表達式替換
    func pregReplace(pattern: String, with: String,
                     options: NSRegularExpression.Options = []) -> String {
        let regex = try! NSRegularExpression(pattern: pattern, options: options)
        return regex.stringByReplacingMatches(in: self, options: [],
                                              range: NSMakeRange(0, self.count),
                                              withTemplate: with)
    }
    
  
    var base64Tobase64URL:String {
        return self .replacingOccurrences(of: "+", with: "-")
                    .replacingOccurrences(of: "/", with: "_")
                    .replacingOccurrences(of: "=", with: "")
    }
    
    var base64URLTobase64:String {
        var base64 = self .replacingOccurrences(of: "-", with: "+")
                          .replacingOccurrences(of: "_", with: "/")
        if ( base64.count % 4 != 0 ) {
            base64.append(String(repeating: "=", count: 4 - base64.count % 4))
        }
        return base64
    }
    
    var hexadecimal: Data? {
        var data = Data(capacity: count / 2)
        
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, range: NSRange(startIndex..., in: self)) { match, _, _ in
            let byteString = (self as NSString).substring(with: match!.range)
            let num = UInt8(byteString, radix: 16)!
            data.append(num)
        }
        
        guard data.count > 0 else { return nil }
        
        return data
    }
    
    // data -> Hex String
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }
    
    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0 as! CVarArg) }.joined()
    }
    
    /// 正则分割字符串
    func split(
        usingRegex pattern: String,
        options: NSRegularExpression.Options = .dotMatchesLineSeparators
    ) -> [SplitedResult] {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: options)
            let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: utf16.count))
            
            var currentIndex = startIndex
            var range: Range<String.Index>
            var captures: [String?] = []
            var results: [SplitedResult] = []
            for match in matches {
                range = Range(match.range, in: self)!
                if range.lowerBound > currentIndex {
                    results.append(SplitedResult(fragment: String(self[currentIndex..<range.lowerBound]), isMatched: false, captures: []))
                }
                
                if match.numberOfRanges > 1 {
                    for i in 1..<match.numberOfRanges {
                        if let _range = Range(match.range(at: i), in: self) {
                            captures.append(String(self[_range]))
                        } else {
                            captures.append(nil)
                        }
                    }
                }
                
                results.append(SplitedResult(fragment: String(self[range]), isMatched: true, captures: captures))
                currentIndex = range.upperBound
                captures.removeAll()
            }
            
            if endIndex > currentIndex {
                results.append(SplitedResult(fragment: String(self[currentIndex..<endIndex]), isMatched: false, captures: []))
            }
            
            return results
        } catch {
            fatalError("正则表达式有误，请更正后再试！")
        }
    }

}

extension Data {
    var integer: Int {
        return withUnsafeBytes { $0.load(as: Int.self) }
    }
    var int32: Int32 {
        return withUnsafeBytes { $0.load(as: Int32.self) }
    }
    var float: Float {
        return withUnsafeBytes { $0.load(as: Float.self) }
    }
    var double: Double {
        return withUnsafeBytes { $0.load(as: Double.self) }
    }
    var string: String? {
        return String(data: self, encoding: .utf8)
    }
    
    init?(base64EncodedURLSafe string: String, options: Base64DecodingOptions = []) {
        let string = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        self.init(base64Encoded: string, options: options)
    }
    
    // data -> Hex String
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
    
    func fourBytesToInt()->Int {
        var value : UInt32 = 0
        let data = self.reserve()
        
        let nsData = NSData(bytes: [UInt8](data), length: self.count)
        nsData.getBytes(&value, length: self.count)
        value = UInt32(bigEndian: value)
        return Int(value)
    }
    
    func reserve()->Data {
        let count:Int = self.count ;
        var array = Data(count:count)
        for i in 0..<count {
            array[i] = self[count - 1 - i]
        }
        
        return array
    }
    
}
