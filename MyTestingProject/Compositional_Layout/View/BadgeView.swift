//
//  BadgeView.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/7/6.
//

import UIKit
class BadgeView:UICollectionReusableView {
    static let reuseIdentify = "BadgeView"
    let label = UILabel.createLabel(size: 9, color: .white,alignment: .center, text: "hot")
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .red
        
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        self.addSubview(label)
        label.centerInSuperview()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = bounds.height/2
    }
}
