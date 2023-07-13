//
//  ScratchCardView.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/7/10.
//

import UIKit
class ScratchCardView:UIView { // 最底下View
    var scratchMask:ScratchMask = ScratchMask(frame: .zero) // 上層的 maskView
    var bottomImageView:UIImageView! // 要顯示的底下ImageView
    
    weak var delegate:ScratchCardDelegate?
    {
        didSet {
            scratchMask.delegate = delegate
        }
    }
    
    public func setUp(couponImage: UIImage, maskImage: UIImage,
                 scratchWidth: CGFloat = 15, scratchType: CGLineCap = .square) {
        
        //let childFrame = CGRect(x: 0, y: 0, width: self.frame.width,
        //                        height: self.frame.height)
        
        bottomImageView = UIImageView()
        bottomImageView.image = couponImage
        addSubview(bottomImageView)
        bottomImageView.centerInSuperview()
        bottomImageView.widthToSuperview()
        bottomImageView.heightToSuperview()
        
        scratchMask.setUpBackImage(backImg: couponImage)
        //scratchMask.frame = childFrame
        scratchMask.image = maskImage
        scratchMask.lineType = scratchType
        scratchMask.lineWidth = scratchWidth
        addSubview(scratchMask)
        scratchMask.centerInSuperview()
        scratchMask.widthToSuperview()
        scratchMask.heightToSuperview()
    }
    
    /*public init(frame: CGRect, couponImage: UIImage, maskImage: UIImage,
                scratchWidth: CGFloat = 15, scratchType: CGLineCap = .square) {
        super.init(frame: frame)
        
        let childFrame = CGRect(x: 0, y: 0, width: self.frame.width,
                                height: self.frame.height)
        
        bottomImageView = UIImageView(frame: childFrame)
        bottomImageView.image = couponImage
        addSubview(bottomImageView)
        
        scratchMask = ScratchMask(frame: childFrame)
        scratchMask.image = maskImage
        scratchMask.lineType = scratchType
        scratchMask.lineWidth = scratchWidth
        addSubview(scratchMask)
    }*/
    /*
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }*/
}
