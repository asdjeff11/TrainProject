//
//  MainViewController.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2022/9/1.
//
import UIKit
import Combine
import Charts
class MainViewController:UIViewController {
    class ImageData {
        // 初始設定 指向自己
        init(current:UIImage) {
            image = current
            lastImageData = self
            nextImageData = self
        }
        var image = UIImage()
        var lastImageData:ImageData! // 最少都有自己 所以一定有值
        var nextImageData:ImageData!
        func getNext()->UIImage { return nextImageData.image }
        func getForward()->UIImage { return lastImageData.image }
    }
    
    var collectionView:UICollectionView!
    let name_list = ["Restful API","Reactive Program","Combine Program",
                     "GoogleMapAPI","WebView","WebViewConnect",
                     "Bluetooth","SocketConnect","ChartView",
                     "KLine","Photo","OperationQueue" , "TestVolumn","CompositionView","ScratchMask"]
    
    // 圖片跑馬燈
    var images:[ImageData] = []
    var scrollView = UIScrollView()
    var currentIndex : NSInteger = 0 // 現在圖片位置
    var leftImageView = MyImageView(imageMode:.fillAndClip) // 上一張顯示的圖片
    var rightImageView = MyImageView(imageMode:.fillAndClip) // 下一張顯示的圖片
    var currentImageView = MyImageView(imageMode:.fillAndClip) // 目前顯示的圖片
    var timer = Timer() // 計時器 多久推下一張
    var isScrolling = false
    var cancelList = Set<AnyCancellable>()
    
    var emitterCell_particle:CAEmitterCell = {
        let emitterCell = CAEmitterCell()
        emitterCell.name = "emitterCell"
        emitterCell.alphaRange = 0.2
        emitterCell.alphaSpeed = -1
        
        emitterCell.duration = 0.1 // 發射 0.1秒
        emitterCell.lifetime = 0.7 // 栗子消逝0.7秒
        emitterCell.lifetimeRange = 0.2
        emitterCell.birthRate = 500
        emitterCell.velocity = 40
        emitterCell.velocityRange = 10
        emitterCell.yAcceleration = 50
        emitterCell.scale = 0.005
        emitterCell.scaleRange = 0.002
        emitterCell.contents = #imageLiteral(resourceName: "particle.png").cgImage
        
        return emitterCell
    }()
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //timer.invalidate()
        cancelList.removeAll()
    }
   
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if ( images.count > 1 ) {
            Timer.publish(every: 2, on: .main, in: .default)
                .autoconnect()
                .sink(receiveValue: { [weak self] _ in
                    if ( self?.isScrolling == false ) {
                        self?.timeChanged()
                    }
                })
                .store(in: &cancelList)
            //setupTimer() // 重新計時
        }
    }
  
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layer.contents = Theme.backGroundImage // backGround Image
        setUp()
        layout()
        if ( images.count > 1 ) { // 圖片大於1張 才開啟這些功能
            scrollView.delegate = self
            reloadImage() // 更新圖片
            //setupTimer() // 重新計時
        }
        
        let layer = CAEmitterLayer()
        layer.name = "clickLayer"
        // sphere = 範圍區域內 隨機發射
        // point = 單點發射
        // circle = 圓周為發射點
        // cuboid
        layer.emitterShape = .sphere
        layer.emitterMode = .surface
        layer.renderMode = .oldestFirst
        
        self.view.layer.addSublayer(layer)
        let gis = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        self.view.addGestureRecognizer(gis)
        //createDropAnimate()
    }
    
    @objc func tapped(_ sender:UITapGestureRecognizer) {
        guard let layer = self.view.layer.sublayers?.first(where: {$0.name == "clickLayer"} ) as? CAEmitterLayer else { return }
    
        layer.emitterPosition = sender.location(in: view)
        layer.emitterSize = CGSize(width: 30, height: 10)
        emitterCell_particle.beginTime = CACurrentMediaTime()
        layer.emitterCells = [emitterCell_particle]
    }
}

extension MainViewController {
    func setUp() {
        setUpNav(title: "主頁" , backButtonVisit: false ,homeButtonRemove: true)
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        //layout.itemSize = CGSize(width: (UIScreen.main.bounds.size.width - 90 * Theme.factor)/2,
       //                          height: (UIScreen.main.bounds.size.width - 90 * Theme.factor)/2 * 2/3)
        //layout.estimatedItemSize = .zero
        layout.sectionInset = UIEdgeInsets(top: 5 * Theme.factor, left: 30 * Theme.factor,
                                           bottom: 5 * Theme.factor, right: 30 * Theme.factor)
        
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.layoutSubviews()
        collectionView.bounces = false
        collectionView.register(MainCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.backgroundColor = nil
        collectionView.delegate = self
        collectionView.dataSource = self
        
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentSize = CGSize(width: Theme.fullSize.width * 3, height: 400 * Theme.factor)
        scrollView.contentOffset = CGPoint(x: Theme.fullSize.width, y: 0)
        scrollView.isPagingEnabled = true // 以一頁為單位滑動
        
        rightImageView.frame = CGRect(x: Theme.fullSize.width * 2, y: 0, width: Theme.fullSize.width, height: 400 * Theme.factor)
        currentImageView.frame = CGRect(x: Theme.fullSize.width * 1, y: 0, width: Theme.fullSize.width, height: 400 * Theme.factor)
        leftImageView.frame = CGRect(x: Theme.fullSize.width * 0, y: 0, width: Theme.fullSize.width, height: 400 * Theme.factor)
        
        scrollView.addSubviews(rightImageView,currentImageView,leftImageView)
        
        
        setImageData()
    }
    
    func layout() {
        view.addSubviews(scrollView, collectionView)
        let margins = view.layoutMarginsGuide
        scrollView.centerXToSuperview()
        scrollView.widthToSuperview()
        scrollView.top(to: margins)
        scrollView.height(400 * Theme.factor)
        
        collectionView.topToBottom(of: scrollView,offset: 50 * Theme.factor)
        collectionView.centerXToSuperview()
        collectionView.bottomToSuperview()
        collectionView.widthToSuperview()
    }
    
    func setImageData() {
        let imgs = [#imageLiteral(resourceName: "slideshow1.jpg"),#imageLiteral(resourceName: "slideshow2.jpg"),#imageLiteral(resourceName: "slideshow3.jpg"),#imageLiteral(resourceName: "slideshow4.jpg"),#imageLiteral(resourceName: "slideshow5.jpg"),#imageLiteral(resourceName: "slideshow6.jpg"),#imageLiteral(resourceName: "slideshow7.jpg")].compactMap({
            UIImage.scaleImage(image:$0, newSize:CGSize(width: Theme.fullSize.width, height: 400 * Theme.factor))
        })
        for (i,img) in imgs.enumerated() {
            // 調整圖片大小 因為 太大的話 第一次載入會很慢 造成圖片還在載入 2秒秒數就到 的問題
            let imageData = ImageData(current: img)
            if ( i != 0 ) {
                //增加連結
                imageData.lastImageData = images[i - 1] // 設定我的上一張
                images[i - 1].nextImageData = imageData // 設定上一張 的 下一張 是我
                if ( i == imgs.count - 1 ) { // 最後一個 要多去設定第一個資料的上一個是我~
                    // recycle 連結
                    images[0].lastImageData = imageData
                    imageData.nextImageData = images[0]
                }
            }
            images.append(imageData) // 放入陣列中
        }
    }
}


extension MainViewController:UICollectionViewDelegate,UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return name_list.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (UIScreen.main.bounds.size.width - 90 * Theme.factor)/2,
                       height: (UIScreen.main.bounds.size.width - 90 * Theme.factor)/2 * 2/3)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? MainCell else { return UICollectionViewCell() }
        cell.setText(title: name_list[indexPath.row])
        /*let colors = ChartColorTemplates.vordiplom()
        + ChartColorTemplates.joyful()
        + ChartColorTemplates.colorful()
        + ChartColorTemplates.liberty()
        + ChartColorTemplates.pastel()
        cell.backgroundColor = colors.randomElement()
        */
        cell.button.addTarget(self, action: #selector(buttonClick(_:)), for: .touchUpInside)
        return cell
    }
    
    @objc func buttonClick(_ sender:UIButton) {
        guard let text = sender.titleLabel?.text else { return }
        
        var vc:UIViewController?
        switch ( text ) {
        case "Restful API" :
            vc = RestfulAPIViewController()
        case "Reactive Program":
            vc = ReactiveView()
        case "Combine Program":
            vc = CombineView()
        case "GoogleMapAPI" :
            vc = GoogleMapTestView()
        case "WebView" :
            vc = WebViewTest()
        case "WebViewConnect":
            vc = WebViewTestConmmunicate()
        case "Bluetooth":
            vc = BluetoothView()
        case "SocketConnect":
            vc = SocketConnectView()
        case "ChartView" :
            vc = ChartViewController()
        case "KLine":
            vc = KLineViewController()
        case "Photo":
            vc = PhotoViewController()
        case "OperationQueue":
            vc = OperationView()
        case "TestVolumn":
            vc = TestVolumnView()
        case "CompositionView" :
            vc = CompostionView()
        case "ScratchMask":
            vc = ScratchMaskViewController()
        default :
            break
        }
        
        if let vc = vc {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}


extension MainViewController {
    func reloadImage() { // 圖片更新
        // 更改左右圖片與現在的圖片
        //let imgs = viewModel.getImages(index: currentIndex)
        leftImageView.image = images[currentIndex].lastImageData.image
        currentImageView.image = images[currentIndex].image
        rightImageView.image = images[currentIndex].nextImageData.image
        
        self.scrollView.setContentOffset(CGPoint(x: Theme.fullSize.width, y: 0), animated: false ) // 水平移動scrollView
        
    } // 圖片更新
    func setupTimer() { // 計時器
        cancelList.removeAll()
        //timer.invalidate()
        //timer = Timer.scheduledTimer(timeInterval: 2,target:self,selector:#selector(timeChanged),userInfo:nil,repeats:true)
        //RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
    } // 計時器
    @objc func timeChanged(){ // 2秒已到
        currentIndex = (currentIndex + 1) % images.count //更新圖片+scrollView
        UIView.animate(withDuration: 0.5, delay: 0.0, options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.scrollView.setContentOffset(CGPoint(x: 2 * Theme.fullSize.width, y: 0), animated: false )
        }, completion: nil)
        
        reloadImage()
    } // 2秒已到
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) { // 開始滑動scrollview
        if scrollView == collectionView { return } // 不要讓 collectionView 觸發到  (單純給 scrollView 用的)
        isScrolling = true
        //sink.cancel()
        //timer.invalidate()
    } // 開始滑動 scrollview
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { // 停止滑動
        if scrollView == collectionView { return } // 不要讓 collectionView 觸發到  (單純給 scrollView 用的)
        
        //向右拖動
        if scrollView.contentOffset.x > Theme.fullSize.width {
            currentIndex = (currentIndex + 1) % images.count
        }
        //向左拖動
        if scrollView.contentOffset.x < Theme.fullSize.width{
            currentIndex = (currentIndex - 1 + images.count ) % images.count
        }
        reloadImage() // 更新圖片
        
        isScrolling = false
        //setupTimer() // 重新計時
    } // scrollView 滑動停止監聽
    
} //timer related

extension MainViewController {
    func createDropAnimate() {
        let myCell = CAEmitterCell()
        let img = #imageLiteral(resourceName: "flower.png").cgImage //UIImage.scaleImage(image: #imageLiteral(resourceName: "flower.png"), newSize: CGSize(width: 20 * Theme.factor, height: 20 * Theme.factor)).cgImage
        myCell.contents = img
        
        myCell.scale = 0.03 // 控制大小
        myCell.scaleRange = 0.01 // +- 概念  大小為 0.3 +- 0.2 ( 0.1 ~ 0.5 )
        myCell.alphaSpeed = 0.2
        myCell.alphaRange = 0.3
        myCell.scaleSpeed = -0.01 // 縮放速度 ( < 0 會縮小 但到最小時 如果還沒結束 會再次放大 , > 0 會放大 )
        
        myCell.emissionRange = .pi // 隨機方向 發射(斜射)
        myCell.lifetime = 5 // 生命週期
        myCell.birthRate = 4 // 生成速度
       
        myCell.velocity = 30 // 下降速度
        myCell.velocityRange = 10 // 下降速度 +- 20
        myCell.yAcceleration = 100 // 向下移動加速度 > 0 向下 , < 0 向上
        myCell.xAcceleration = 5 // 向右加速度 > 0 向右 , < 0 向左
        
        myCell.spin = -0.5 // 旋轉弧度
        myCell.spinRange = 1 // +- 1 ( 0.5 ~ -1.5 )
        
        let layer = CAEmitterLayer()
        layer.emitterCells = [myCell]
        layer.emitterPosition = CGPoint(x: view.bounds.width / 2 , y: 300)
        layer.emitterSize = CGSize(width: view.bounds.width, height: 0)
        layer.emitterShape = CAEmitterLayerEmitterShape.line
        
        self.view.layer.addSublayer(layer)
    }
}

