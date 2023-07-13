//
//  MyImageView.swift
//  iCloudApp
//
//  Created by 楊宜濱 on 2023/06/20.
//  Copyright © 2023 ICL Technology CO., LTD. All rights reserved.
//

import UIKit
class MyImageView : UIImageView {
    enum Mode:Equatable {
        case fillAndClip
        case fillAndWhiteBG
        case nothing
        case FitImgSize(CGSize)
    }
    
    private var hashCode:String?
    private var size:CGSize?
    private var mode:Mode = .nothing
    
    
    func setHashCode(hash:String) {
        self.hashCode = hash
    }
    
    func getHashCode()->String? {
        return self.hashCode
    }
    
    init(image: UIImage? = nil, imageMode: Mode = .nothing) {
        super.init(image: image)
        
        self.mode = imageMode
        switch ( imageMode ) {
        case .fillAndClip :
            contentMode = .scaleAspectFill
            clipsToBounds = true
        case .fillAndWhiteBG :
            contentMode = .scaleAspectFit
        case .FitImgSize(let size) :
            self.size = size
        case .nothing :
            return
        }
    }
    
    func setImage(image:UIImage) {
        if let size = size {
            self.image = ( mode == .fillAndWhiteBG ) ? UIImage.resize_no_cut(image: image, newSize: size) :
                                                       UIImage.scaleImage(image: image, newSize: size)
        }
    }
    
    func setMode(_ mode:Mode) {
        self.mode = mode
        // 重製
        self.clipsToBounds = false
        contentMode = .center
        
        switch ( mode ) {
        case .fillAndClip :
            contentMode = .scaleAspectFill
            clipsToBounds = true
        case .fillAndWhiteBG :
            contentMode = .scaleAspectFit
        case .FitImgSize(let size) :
            self.size = size
        case .nothing :
            return
        }
    }
    
    func setSize(_ size:CGSize) {
        self.size = size
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
