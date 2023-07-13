//
//  HeaderView.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/7/6.
//

import UIKit
class HeaderView:UICollectionReusableView {
    static let reuseIdentify = "headerView"
    let label = UILabel.createLabel(size: 25 * Theme.factor, color: .darkGray,alignment: .left)
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(label)
        
        label.centerYToSuperview()
        label.leadingToSuperview(offset:15)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
