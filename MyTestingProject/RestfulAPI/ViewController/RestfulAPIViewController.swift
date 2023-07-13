//
//  RestfulAPIViewController.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2022/9/1.
//

import UIKit

class RestfulAPIViewController:UIViewController {
    var isLoading = false
    let viewModel = RestfulAPIViewModel()
    var lastOffset:CGPoint = .zero
    var lastOffsetCapture:TimeInterval = .zero
    
    lazy var collectionView:UICollectionView = {
        let pic_cell_size = CGSize(width: 200 * Theme.factor, height: 200 * Theme.factor)
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        flowLayout.minimumLineSpacing = 10
        flowLayout.itemSize = pic_cell_size

        let colView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        colView.backgroundColor = .clear
        colView.bounces = false
        colView.register(RestfulAPIViewCell.self, forCellWithReuseIdentifier: "item")
        colView.delegate = self
        colView.dataSource = self
        return colView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.contents = Theme.backGroundImage
        layout()
        setUpNav(title: "RestfulAPI 測試")
        self.loading(isLoading: &isLoading)
        viewModel.fetchData(url:"https://raw.githubusercontent.com/cmmobile/NasaDataSet/main/apod.json", completion: { [weak self] (result) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.removeLoading(isLoading: &self.isLoading)
                if ( result == "" ) {
                    self.collectionView.reloadData()
                }
                else {
                    self.showAlert(alertText: "資料錯誤", alertMessage: result)
                }
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("Memory warning")
    }
}

extension RestfulAPIViewController:UICollectionViewDelegate,UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.getTotalSize()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "item", for: indexPath) as? RestfulAPIViewCell else { return UICollectionViewCell() }
        let detail = viewModel.getItem(indexPath: indexPath)
        cell.setup(detail: detail)
        cell.imageView.image = nil
        
        //removeImgViewLoading(imageView: cell.imageView)
        
        switch ( detail.photo.state ) {
        case .NotDone :
            //addLoading(imageView: cell.imageView)
            viewModel.getImage(indexPath: indexPath, completion: {[weak self] (img) in
                DispatchQueue.main.async {
                    self?.collectionView.reloadItems(at: [indexPath])
                }
            })
        case .Done :
            //cell.loadingView.isHidden = true
            //cell.loadingView.image = nil
            cell.imageView.image = detail.photo.image
        case .Failed :
            //cell.loadingView.isHidden = true
            //cell.loadingView.image = nil
            cell.imageView.image = UIImage(named: "cancel")
        }
        
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let detail = viewModel.getItem(indexPath: indexPath)
        let vc = RestfulAPIDetailView()
        vc.detail = detail
        navigationController?.pushViewController(vc, animated: true)
    }
    
}


extension RestfulAPIViewController:UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) { // 滑動監聽
        /*let currentOffset = scrollView.contentOffset
        let currentTiem = Date.timeIntervalSinceReferenceDate
        let timeDiff = currentTiem - lastOffsetCapture
        if ( lastOffsetCapture != .zero && timeDiff > 0.02 ) {
            let distance = currentOffset.y - lastOffset.y
            let scrollSpeedNotAbs = (distance * 10) / 1000
            let scrollSpeed = fabsf(Float(scrollSpeedNotAbs))
            if ( scrollSpeed > 0.7 ) {
                print("suspending")
                viewModel.isSuspend = true
                viewModel.removeAllTaskInQueue()
            }
            else if ( viewModel.isSuspend == true && scrollSpeed < 0.7 ) {
                print("unlock")
                loadImagesForOnscreenCells()
            }
        }
        lastOffset = currentOffset
        lastOffsetCapture = currentTiem
        */
        
        let currentOffset = scrollView.contentOffset
        let currentTiem = Date.timeIntervalSinceReferenceDate
        let timeDiff = currentTiem - lastOffsetCapture
        
        if ( timeDiff > 0.3 ) {
            if ( lastOffsetCapture != 0 ) {
                let distance = currentOffset.y - lastOffset.y
                let scrollSpeedNotAbs = (distance * 10) / 1000
                let scrollSpeed = fabsf(Float(scrollSpeedNotAbs))
                if ( scrollSpeed > 7 ) {
                    print("suspending")
                    viewModel.isSuspend = true
                    viewModel.removeAllTaskInQueue()
                }
                else if ( viewModel.isSuspend == true && scrollSpeed < 7 ) {
                    print("unlock")
                    viewModel.isSuspend = false
                }
            }
           /* else if ( isSuspend == true ) {
                isSuspend = false
                loadImagesForOnscreenCells()
                resumeAllOperations()
            }*/
          
            lastOffsetCapture = currentTiem
            lastOffset = currentOffset
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) { // 停止滑動
        // 2
        if !decelerate {
            viewModel.isSuspend = false
            loadImagesForOnscreenCells()
        }
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // 3
        
        viewModel.isSuspend = false
        loadImagesForOnscreenCells()
    }
    
}

extension RestfulAPIViewController {
    fileprivate func addLoading(imageView:UIImageView) { // loading 動畫
        imageView.layoutIfNeeded()
        let cycleLayer: CAShapeLayer = CAShapeLayer()
        cycleLayer.lineWidth = 4
        cycleLayer.fillColor = UIColor.clear.cgColor
        cycleLayer.strokeColor = UIColor.white.cgColor
        
        //cycleLayer.lineCap = CAShapeLayerLineCap.round
        //cycleLayer.lineJoin = CAShapeLayerLineJoin.round
       
        //let x = imageView.bounds.size.width * 0.7 / 2
        //let y = imageView.bounds.size.height * 0.7 / 2
        
        let height = imageView.bounds.size.height * 0.3
        let width = imageView.bounds.size.height * 0.3
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: width, height: height))
        cycleLayer.frame = imageView.bounds // 讓 形狀層的框架與 imageView的相同 這會使 形狀層 大小 imageView 相同 , 中心在 imageView 中心 (0,0)
        cycleLayer.path = UIBezierPath(ovalIn: rect).cgPath // 告知要繪製的路徑
        cycleLayer.bounds = rect // 把形狀層 變的跟 路徑一樣大
        // ovalIn 是畫圓圈的意思
        let strokeStartAnimation = CABasicAnimation(keyPath: "strokeStart") // 清除效果
        strokeStartAnimation.fromValue = -1
        strokeStartAnimation.toValue = 1.0
        strokeStartAnimation.repeatCount = Float.infinity
        cycleLayer.add(strokeStartAnimation, forKey: "strokeStartAnimation")
        
        let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd") // 開始畫圓
        strokeEndAnimation.fromValue = 0
        strokeEndAnimation.toValue = 1.0
        strokeEndAnimation.repeatCount = Float.infinity
        cycleLayer.add(strokeEndAnimation, forKey: "strokeEndAnimation")
        
        let animationGroup = CAAnimationGroup() // 兩個動畫同時執行 繪畫速度為1.5秒
        animationGroup.repeatCount = Float.infinity
        animationGroup.animations = [strokeStartAnimation, strokeEndAnimation]
        animationGroup.duration = 1.5
        cycleLayer.add(animationGroup, forKey: "animationGroup")
        
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation") // 旋轉整個物件 其目的是修改起點
        rotateAnimation.fromValue = 0
        rotateAnimation.toValue = Double.pi * 2
        rotateAnimation.repeatCount = Float.infinity
        rotateAnimation.duration = 1.5 * 4
        cycleLayer.add(rotateAnimation, forKey: "rotateAnimation")
        
        imageView.layer.addSublayer(cycleLayer)
    } // loading 動畫
    
    func removeImgViewLoading(imageView:UIImageView) {
        imageView.layer.sublayers?.forEach{ $0.removeFromSuperlayer() }
    }
}

extension RestfulAPIViewController {
    /// 取消上次的任務 並 加入新的任務
    func loadImagesForOnscreenCells() {
        viewModel.isSuspend = false
        let pathsArray = collectionView.indexPathsForVisibleItems
        /*for i in 0...4 {
            let ind = IndexPath(row: pathsArray[pathsArray.count-1].row + i + 1, section: 0)
            pathsArray.append(ind)
        }*/
        collectionView.reloadItems(at: pathsArray)
    }
}

extension RestfulAPIViewController {
    func layout() {
        let margins = view.layoutMarginsGuide
        view.addSubview(collectionView)
        NSLayoutConstraint.useAndActivateConstraints(constraints: [
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: margins.topAnchor,constant: 30 * Theme.factor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
