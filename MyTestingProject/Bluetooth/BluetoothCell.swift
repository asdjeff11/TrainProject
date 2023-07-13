//
//  BluetoothCell.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/10.
//

import Foundation
import UIKit

class BluetoothCell:UICollectionViewCell {
    let logoImageView = UIImageView()
    let titleLabel = UILabel.createLabel(size: 14, color: .black)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UIColor(hex: 0xFFDEAD)
        contentView.layer.cornerRadius = 15
        contentView.addSubviews(titleLabel,logoImageView)
        
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byCharWrapping
        
        NSLayoutConstraint.useAndActivateConstraints(constraints: [
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,constant: 10),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor,constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,constant: -10),
            titleLabel.heightAnchor.constraint(equalToConstant: 50 * Theme.factor),
            
            logoImageView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            logoImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30 * Theme.factor),
            logoImageView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            logoImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,constant: -10 * Theme.factor)
        ])
    }
    
    public func setTitle(text:String) {
        titleLabel.text = text
        //switch ( text ) {
        //case "傳接測試" :
            logoImageView.image = UIImage(named: "testLogo")
        //default :
        //    break
        //}
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
