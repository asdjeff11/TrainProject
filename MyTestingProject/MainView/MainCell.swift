//
//  MainCell.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2022/9/1.
//

import UIKit

class MainCell:UICollectionViewCell {
    let button = UIButton()
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = nil
        
        button.backgroundColor = UIColor(hex: 0xCBD1C7)
        button.layer.cornerRadius = 10
        button.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 5)
        button.layer.shadowOpacity = 1.0
        button.layer.shadowRadius = 10.0
        button.layer.masksToBounds = false
        button.center = contentView.center
        contentView.addSubviews(button)
        button.centerXToSuperview()
        button.centerYToSuperview()
        button.size(CGSize(width: 300 * Theme.factor, height: 70 * Theme.factor))
    }
    
    public func setText(title:String) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = Theme.labelFont.withSize(16)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
