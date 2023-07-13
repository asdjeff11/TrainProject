//
//  ImagePreviewCell.swift
//  iCloudApp
//
//  Created by 楊宜濱 on 2022/4/8.
//  Copyright © 2022 ICL Technology CO., LTD. All rights reserved.
//

import UIKit

 

class ImagePreviewCell: UICollectionViewCell {
    var scrollView:UIScrollView!

    var imageView:UIImageView!  //用于显示图片的imageView
    
    var numOfLabel:UILabel!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        scrollView = UIScrollView(frame: self.contentView.bounds)
        scrollView.delegate = self
        scrollView.maximumZoomScale = 3.0
        scrollView.minimumZoomScale = 1.0

        //imageView初始化
        imageView = UIImageView()
        imageView.frame = scrollView.bounds
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFit

        numOfLabel = UILabel.createLabel(size: 16, color: .gray)
        
        self.contentView.addSubview(scrollView)
        self.contentView.addSubview(numOfLabel)
        scrollView.addSubview(imageView)

        NSLayoutConstraint.useAndActivateConstraints(constraints: [
            numOfLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            numOfLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,constant: -30 * Theme.factor),
            numOfLabel.heightAnchor.constraint(equalToConstant: 30 * Theme.factor)
        ])
        
        
        //双击监听
        let tapDouble = UITapGestureRecognizer(target:self,action:#selector(tapDoubleDid(_:)))
        tapDouble.numberOfTapsRequired = 2
        tapDouble.numberOfTouchesRequired = 1

        self.imageView.addGestureRecognizer(tapDouble)
    }


    //视图布局改变时（横竖屏切换时cell尺寸也会变化）
    override func layoutSubviews() {
        super.layoutSubviews()
        resetSize()  //重置单元格内元素尺寸
    }


    //图片双击事件响应
    @objc func tapDoubleDid(_ ges:UITapGestureRecognizer){
        //缩放视图（带有动画效果）
        UIView.animate(withDuration: 0.5, animations: {
            //如果当前不缩放，则放大到3倍。否则就还原
            if self.scrollView.zoomScale == self.scrollView.minimumZoomScale {
                //以点击的位置为中心，放大3倍
                
                let pointInView = ges.location(in: self.imageView)
                let newZoomScale:CGFloat = self.scrollView.maximumZoomScale
                let scrollViewSize = self.scrollView.bounds.size
                let w = scrollViewSize.width / newZoomScale
                let h = scrollViewSize.height / newZoomScale
                let x = pointInView.x - (w / 2.0)
                let y = pointInView.y - (h / 2.0)

                let rectToZoomTo = CGRect(x:x, y:y, width:w, height:h)
                self.scrollView.zoom(to: rectToZoomTo, animated: true)

            }else{
                self.scrollView.zoomScale = self.scrollView.minimumZoomScale
            }
        })
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    
}


extension ImagePreviewCell {
    
    //重置单元格内元素尺寸
    func resetSize(){
        scrollView.frame = self.contentView.bounds // scrollView重置，不缩放
        scrollView.zoomScale = self.scrollView.minimumZoomScale

        //imageView重置
        if let image = self.imageView.image {
            imageView.frame.size = scaleSize(size: image.size) // 设置imageView的尺寸确保一屏能显示的下
            imageView.center = scrollView.center // imageView居中
        }
        print("reset size")
    }
    
    
    //获取imageView的缩放尺寸（确保首次显示是可以完整显示整张图片）
    func scaleSize(size:CGSize) -> CGSize {
        let width = size.width
        let height = size.height
        let widthRatio = width/UIScreen.main.bounds.width
        let heightRatio = height/UIScreen.main.bounds.height

        let ratio = max(heightRatio, widthRatio)
        return CGSize(width: width/ratio, height: height/ratio)
    }
    
}

//ImagePreviewCell的UIScrollViewDelegate代理实现
extension ImagePreviewCell: UIScrollViewDelegate {

    //缩放视图
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }

    //缩放响应，设置imageView的中心位置
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        var centerX = scrollView.center.x
        var centerY = scrollView.center.y
        centerX = scrollView.contentSize.width > scrollView.frame.size.width ? scrollView.contentSize.width/2 : centerX // 內容比 scrollView大 (表示放大 ) 中心點為 當前顯示的內容的中心
        centerY = scrollView.contentSize.height > scrollView.frame.size.height ? scrollView.contentSize.height/2 : centerY  // 內容比 scrollView大 (表示放大 ) 中心點為 當前顯示的內容的中心
        print(centerX,centerY)
        imageView.center = CGPoint(x: centerX, y: centerY) // 圖片中心點也設為此點
    }
    
}


// unuse function
extension ImagePreviewCell {
    
    //查找所在的ViewController (目前沒用到)
    func responderViewController() -> UIViewController? {
        for view in sequence(first: self.superview, next: { $0?.superview }) {
            if let responder = view?.next {
                if responder.isKind(of: UIViewController.self){
                    return responder as? UIViewController
                }
            }
        }
        return nil
    }
    
}
