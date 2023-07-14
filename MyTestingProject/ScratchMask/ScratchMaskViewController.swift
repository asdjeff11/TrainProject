//
//  PathTesting.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/7/10.
//

import Foundation
import UIKit
class ScratchMaskViewController:UIViewController {
    lazy var scratchCard = ScratchCardView()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.contents = Theme.backGroundImage
        setUpNav(title: "刮刮樂")
        /*
        let myVie = myView()
        view.addSubview(myVie)
        myVie.centerInSuperview()
        myVie.backgroundColor = .clear
        myVie.size(CGSize(width: 150, height: 150))*/
        scratchCard.delegate = self
        scratchCard.setUp(couponImage:#imageLiteral(resourceName: "slideshow7.jpg"),
                          maskImage:#imageLiteral(resourceName: "grayImage.png"))
        view.addSubview(scratchCard)
    }
    
    /*override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        layout()
    }*/
    
    func layout() {
        let size = ( UIDevice.current.orientation.isLandscape ) ? CGSize(width: 400, height: 200) : CGSize(width: 250, height: 300) 
        scratchCard.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        scratchCard.center = view.center
    }
    
    override func viewWillLayoutSubviews() {
        layout()
    }
}

extension ScratchMaskViewController:ScratchCardDelegate {
    //滑动开始
    func scratchBegan(point: CGPoint) {
        print("开始刮奖：\(point)")
    }
     
    //滑动过程
    func scratchMoved(progress: Float) {
        print("当前进度：\(progress)")
         
        //显示百分比
        let percent = String(format: "%.1f", progress * 100)
        if ( progress >= 0.3 && scratchCard.scratchMask.isUserInteractionEnabled == true ) {
            scratchCard.scratchMask.isUserInteractionEnabled = false
            scratchCard.scratchMask.dismissView()
        }
        print(percent)
    }
     
    //滑动结束
    func scratchEnd(point: CGPoint) {
        print("停止刮奖：\(point)")
    }
}



// 測試用
class myView:UIView {
    override func draw(_ rect: CGRect) {
        let centerPoint = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let radiusLength = rect.width / 2 - 5
        
        let color = UIColor.blue
        color.set()
        
        let endValue:Int = 300
        
        let startA:CGFloat = 0
        let endA:CGFloat = Double.pi * ( Double(endValue) / 180)
        
        let aPath = UIBezierPath()
        aPath.addArc(withCenter: centerPoint, radius: radiusLength, startAngle: endA , endAngle:  startA, clockwise: false)
        aPath.stroke() // 畫路徑
        
        
        let context = UIGraphicsGetCurrentContext()
        
        for i in 0..<endValue {
            let alpha = CGFloat(i) / CGFloat(endValue)
            let color = UIColor.red.withAlphaComponent(alpha)
            color.set()
            
            context?.setLineWidth(0)
            context?.move(to: centerPoint)
            context?.addArc(center: centerPoint, radius: radiusLength, startAngle:CGFloat(Double(i) * Double.pi / 180), endAngle: CGFloat(Double(i + 1) * Double.pi / 180), clockwise: false)
            // clockwise = 順時針 or 逆時針
            context?.fillPath(using: .winding)
            context?.strokePath()
            //context?.closePath()
            //context?.drawPath(using: CGPathDrawingMode.fillStroke)
        }
        
    }
}
