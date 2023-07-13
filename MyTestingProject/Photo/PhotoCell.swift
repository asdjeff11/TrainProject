//
//  PhotoCell.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/16.
//

import Foundation
import UIKit
class PhotoCell:UICollectionViewCell {
    let imageView = UIImageView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        contentView.addSubview(imageView)
        
        imageView.edgesToSuperview()
    }
    
    func setImage(img:UIImage) {
        imageView.image = img
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
