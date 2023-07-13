//
//  ImagePreviewVC.swift
//  iCloudApp
//
//  Created by 楊宜濱 on 2022/4/8.
//  Copyright © 2022 ICL Technology CO., LTD. All rights reserved.
//

import UIKit

//图片浏览控制器

class ImagePreviewVC: UIViewController {
    var photos = [Photo]()
    var selectRow:IndexPath = IndexPath(row: 0, section: 0)
    lazy var collectionView:UICollectionView = {
        let collectionViewLayout = UICollectionViewFlowLayout()   //collectionView尺寸样式设置
        collectionViewLayout.minimumLineSpacing = 0
        collectionViewLayout.minimumInteritemSpacing = 0
        collectionViewLayout.scrollDirection = .horizontal  //横向滚动
        
        
        let collectionView = UICollectionView(frame: self.view.bounds,collectionViewLayout: collectionViewLayout)  //collectionView初始化
        collectionView.backgroundColor = UIColor.black
        collectionView.register(ImagePreviewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        
        if #available(iOS 11.0, *) {  //不自动调整内边距，确保全屏
            collectionView.contentInsetAdjustmentBehavior = .never

        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
        return collectionView
    }()
    
    var needRefresh = false
  
    init(image_urls:[String], index:Int = 0){ //初始化
        self.photos = image_urls.map({ url in
            if let img = imgDict.getImg(url: url) {
                return Photo(state: .Done, url: url, image:img)
            }
            else {
                return Photo(state: .NotDone, url: url, image: nil )
            }
        })
        self.selectRow = IndexPath(row:index,section: 0)
        super.init(nibName: nil, bundle: nil)
     }

    init(image:UIImage) {
        super.init(nibName: nil, bundle: nil)
        self.photos.append(Photo(state: .Done, image:image))
        self.selectRow = IndexPath(row: 0, section: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

     
    //初始化
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = .gray
        let item = UIBarButtonItem(title: "返回", style: .plain, target: self, action: nil)
        self.navigationItem.backBarButtonItem = item
        
        self.view.backgroundColor = UIColor.black //背景设为黑色

        //单击监听
        let tapSingle = UITapGestureRecognizer(target:self, action:#selector(tapSingleDid))
        tapSingle.numberOfTapsRequired = 1
        tapSingle.numberOfTouchesRequired = 1
        view.addGestureRecognizer(tapSingle)
        
        let tapDouble = UITapGestureRecognizer(target: self, action: #selector(tapDoubleDid))
        tapDouble.numberOfTapsRequired = 2
        tapDouble.numberOfTouchesRequired = 1
        view.addGestureRecognizer(tapDouble)
        tapSingle.require(toFail: tapDouble)
        
        NotificationCenter.default.addObserver(self, selector:#selector(backToApp), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(onBackGround), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        self.view.addSubview(collectionView)
    }
    
    //视图显示时
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)  //隐藏导航栏
    }

    //视图消失时
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)  //显示导航栏
    }

    //将要对子视图布局时调用（横竖屏切换时）

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        collectionView.frame.size = self.view.bounds.size //重新设置collectionView的尺寸
        collectionView.collectionViewLayout.invalidateLayout()
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension ImagePreviewVC {
    //图片单击事件响应
    @objc func tapSingleDid(_ ges:UITapGestureRecognizer){
        //显示或隐藏导航栏
        if let nav = self.navigationController{
            let hide = nav.isNavigationBarHidden
            nav.setNavigationBarHidden(!hide, animated: true)
        }
    }
    
    @objc func tapDoubleDid(_ ges:UITapGestureRecognizer) {
    }
}


//ImagePreviewVC的CollectionView相关协议方法实现

extension ImagePreviewVC:UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    
    //collectionView单元格创建
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell",for: indexPath) as! ImagePreviewCell
        let photoDetail = photos[indexPath.row]
        
        if ( photoDetail.image == nil ) {
            if let img = imgDict.getImg(url: photoDetail.url ) {
                cell.imageView.image = img
                photos[indexPath.row].state = .Done
                photos[indexPath.row].image = img
            }
            else {
                cell.imageView.image = nil
            }
        }
        
        
        switch ( photoDetail.state ) {
        case .NotDone :
            fetchImage(url_str: photoDetail.url, completion: { [weak self] (result) in
                guard let self = self else { return }
                if ( result != "" ) { print("row:\(indexPath.row) is error  :\(result)")}
                DispatchQueue.main.async {
                    self.collectionView.reloadItems(at: [indexPath])
                }
            })
            break
        case .Done :
            cell.imageView.image = photoDetail.image
        case .Failed :
            cell.imageView.image = UIImage(named: "cancel")
        }
        
        cell.numOfLabel.text = "\(indexPath.row + 1) / \(photos.count)"
        return cell
    }
    
        
    //collectionView单元格数量
    func collectionView(_ collectionView: UICollectionView,numberOfItemsInSection section: Int) -> Int {
        return self.photos.count
    }


    //collectionView单元格尺寸
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.view.bounds.size
    }

    //collectionView里某个cell将要显示
    func collectionView(_ collectionView: UICollectionView,willDisplay cell: UICollectionViewCell,forItemAt indexPath: IndexPath) {
        if let cell = cell as? ImagePreviewCell{
            //由于单元格是复用的，所以要重置内部元素尺寸
            cell.resetSize()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        //当前显示的单元格
//        let visibleCell = collectionView.visibleCells[0]
        //设置页控制器当前页
//        self.pageControl.currentPage = collectionView.indexPath(for: visibleCell)!.item
    }
}

extension ImagePreviewVC {
    func fetchImage(url_str:String, completion:@escaping (String) -> Void) {
        guard let url = URL(string: url_str) else { completion("Error to analysis URL") ; return }
        
        URLSession.shared.dataTask(with: url, completionHandler: { data, response , error in
            if let error = error {
                completion("request failed (\(error))")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { completion("response failed") ;return}
            guard let data = data , let image = UIImage(data:data ) else {  completion("parse data error") ;return }
            imgDict.putIntoDict(url: url_str, img: image)
            completion("")
        }).resume()
    }
}

extension ImagePreviewVC { // backGround action
    
    @objc func onBackGround() {
        if ( navigationController?.viewControllers.last is ImagePreviewVC ) {
            imgDict.onBackGround(photos: photos)
        }
    }
    
    @objc func backToApp() {
        if ( navigationController?.viewControllers.last is ImagePreviewVC ) {
            imgDict.onFrontGround()
        }
    }
}
