//
//  ScratchMask.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/7/10.
//

import UIKit

@objc protocol ScratchCardDelegate {
    @objc optional func scratchBegan(point:CGPoint)
    @objc optional func scratchMoved(progress:Float)
    @objc optional func scratchEnd(point:CGPoint)
}

class ScratchMask:UIImageView {
    weak var delegate: ScratchCardDelegate?
    
    var backImage:UIImage?
    var lineType:CGLineCap! // 線條形狀
    var lineWidth:CGFloat! // 線條粗細
    var lastPoint: CGPoint? // 上次停留位置
    
    override init(frame:CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
    }
    
    func setUpBackImage(backImg:UIImage) {
        self.backImage = backImg
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return } // 第一觸擊點
        
        lastPoint = touch.location(in: self)
        
        delegate?.scratchBegan?(point: lastPoint!)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first ,  // 第一觸擊點
              let point = lastPoint, // 上次點擊結束的點
              let img = image // 圖片
        else { return }
        
        let newPoint = touch.location(in: self)
        
        eraserMask(fromPoint:point,toPoint:newPoint) // 清除兩點之間
        
        lastPoint = newPoint // 更新上次點
        
        // 計算目前的清除面積
        if img.size.width > frame.size.width || img.size.height > frame.size.height {
            return
        }
        let progress = getAlphaPixelPercent(img: img)
        
        delegate?.scratchMoved?(progress: progress)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        delegate?.scratchEnd?(point: touch.location(in: self))
    }
    
    func eraserMask(fromPoint:CGPoint,toPoint:CGPoint) {
        UIGraphicsBeginImageContextWithOptions(self.frame.size, false, UIScreen.main.scale)
        
        image?.draw(in: self.bounds)
        let path = CGMutablePath()
        path.move(to: fromPoint)
        path.addLine(to: toPoint)
        
        let context = UIGraphicsGetCurrentContext()
        context?.setShouldAntialias(true)
        context?.setLineCap(lineType)
        context?.setLineWidth(lineWidth)
        context?.setBlendMode(.clear)
        context?.addPath(path)
        context?.strokePath()
        
        image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
    }
    
    func dismissView() {
        let clearView = UIImageView(image: backImage)
        clearView.center = self.center
        clearView.frame = self.frame
        self.addSubview(clearView)
        
        let maskView = UIView()
        maskView.frame.size = CGSize(width: 1, height: 1)
        maskView.center = self.center
        maskView.backgroundColor = .black // 不會顯示顏色 只是確保版中所有像素是不透明的
        maskView.layer.cornerRadius = 0.5
        clearView.mask = maskView
        
        let maxY = center.y
        let maxX = center.x
        let maxSize = max(maxY, maxX) * 4
        
        UIView.animate(
            withDuration: 0.5,
                delay: 0,
                options: [.curveEaseOut],
                animations: {
                    maskView.frame.size = CGSize(width: maxSize, height: maxSize)
                    maskView.layer.cornerRadius = maxSize / 2.0
                    maskView.center = self.center
        }) { (flag) in
            clearView.removeFromSuperview()
            self.image = nil
        }
    }
    
    private func getAlphaPixelPercent(img: UIImage) -> Float {
            //计算像素总个数
            let width = Int(img.size.width)
            let height = Int(img.size.height)
            let bitmapByteCount = width * height
             
            //得到所有像素数据
            let pixelData = UnsafeMutablePointer<UInt8>.allocate(capacity: bitmapByteCount)
            let colorSpace = CGColorSpaceCreateDeviceGray()
            let context = CGContext(data: pixelData,
                                    width: width,
                                    height: height,
                                    bitsPerComponent: 8,
                                    bytesPerRow: width,
                                    space: colorSpace,
                                    bitmapInfo: CGBitmapInfo(rawValue:
                                        CGImageAlphaInfo.alphaOnly.rawValue).rawValue)!
            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            context.clear(rect)
            context.draw(img.cgImage!, in: rect)
             
            //计算透明像素个数
            var alphaPixelCount = 0
            for x in 0...Int(width) {
                for y in 0...Int(height) {
                    if pixelData[y * width + x] == 0 {
                        alphaPixelCount += 1
                    }
                }
            }
             
            free(pixelData)
             
            return Float(alphaPixelCount) / Float(bitmapByteCount)
        }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
