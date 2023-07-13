//
//  OperationVie.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/17.
//

import Foundation
import UIKit

class OperationView:UIViewController {
    var isLoading = false
    let viewModel = OperationViewModel()
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
        
        viewModel.updateCell = { [weak self] (indexPath:IndexPath) in
            self?.collectionView.reloadItems(at:[indexPath])
        }
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
}

extension OperationView:UICollectionViewDelegate,UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.getTotalSize()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "item", for: indexPath) as? RestfulAPIViewCell else { return UICollectionViewCell() }
        let detail = viewModel.getItem(indexPath: indexPath)
        cell.setup(detail: detail)
        cell.imageView.image = nil
        
        switch ( detail.photo.state ) {
        case .NotDone :
            viewModel.startOperation(at: indexPath)
        case .Done :
            if let img = imgDict.getImg(url: detail.starsData.url) { // 某種原因被釋放了 ( 退至後台 返回前台 有機會imgDict被釋放 取決於系統的臉色  ) 
                cell.imageView.image = img
            }
            else {
                viewModel.resetItemState(indexPath: indexPath)
            }
            //cell.loadingView.isHidden = true
            //cell.loadingView.image = nil
            //cell.imageView.image = detail.photo.image
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


extension OperationView:UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) { // 滑動監聽
        let currentOffset = scrollView.contentOffset
        let currentTiem = Date.timeIntervalSinceReferenceDate
        let timeDiff = currentTiem - lastOffsetCapture
        if ( lastOffsetCapture != .zero && timeDiff > 0.02 ) {
            let distance = currentOffset.y - lastOffset.y
            let scrollSpeedNotAbs = (distance * 10) / 1000
            let scrollSpeed = fabsf(Float(scrollSpeedNotAbs))
            if ( scrollSpeed > 0.7 ) {
                print("suspending")
                viewModel.isSuspend = true
            }
            else if ( viewModel.isSuspend == true && scrollSpeed < 0.7 ) {
                print("unlock")
                viewModel.isSuspend = false
                viewModel.loadImageOnScreen(showingIndex: Set(collectionView.indexPathsForVisibleItems) )
            }
        }
        lastOffset = currentOffset
        lastOffsetCapture = currentTiem
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) { // 停止滑動
        // 2
        if !decelerate {
            viewModel.isSuspend = false
            collectionView.reloadData()
        }
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // 3
        
        viewModel.isSuspend = false
        if ( scrollView.contentOffset.y < 0.0 ) {
            return
        }
        viewModel.loadImageOnScreen(showingIndex: Set(collectionView.indexPathsForVisibleItems) )
    }
    
}
extension OperationView {
    /// 取消上次的任務 並 加入新的任務
    func loadImagesForOnscreenCells() {
        let allPendingOperations = Set(viewModel.pendingOperations.downloadsInProgress.keys) // 所有運行中的 operation 的 IndexPath
        
        let pathsArray = collectionView.indexPathsForVisibleItems
        let visiblePaths = Set(pathsArray) // 目前可視的 IndexPath
        
        
        var toBeCancelled = allPendingOperations
        toBeCancelled.subtract(visiblePaths) // 將被取消任務的 IndexPath
        _ = toBeCancelled.map{ viewModel.pendingOperations.cancel(path: $0) } // cancel 原先的 任務
        
        
        var toBeStarted = visiblePaths
        toBeStarted.subtract(allPendingOperations) // 將要開始任務的 IndexPath
        
        for indexPath in toBeStarted { // 加入 新的任務
            var num = indexPath.row
            
            let recordToProcess = viewModel.models[num].photo
            if ( recordToProcess.state != .Done ) { // 沒完成 再撈
                viewModel.startOperation(at: indexPath)
            }
        }
    }
}

extension OperationView {
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
