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
        
    }
}

extension StringProtocol {
    var asciiValues: [UInt8] { compactMap(\.asciiValue) }
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
