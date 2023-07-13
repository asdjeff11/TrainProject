//
//  ChartCell.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/13.
//

import Foundation
import UIKit
import TinyConstraints
class ChartCell:UITableViewCell {
    private let titleLabel = UILabel.createLabel(size: 16, color: .black)
    private let numLabel = UILabel.createLabel(size: 16, color: .black,alignment: .right)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        
        let bgView = UIView()
        bgView.backgroundColor = .white
        bgView.layer.cornerRadius = 15
        //bgView.layer.borderColor = UIColor.black.cgColor
        //bgView.layer.borderWidth = 1
        
        contentView.addSubview(bgView)
        bgView.center(in: contentView)
        bgView.widthToSuperview(offset: -80 * Theme.factor)
        bgView.heightToSuperview()
        
        bgView.addSubviews(titleLabel,numLabel)
        titleLabel.centerYToSuperview()
        titleLabel.leadingToSuperview(offset: 30 * Theme.factor)
        titleLabel.width(150 * Theme.factor)
        titleLabel.height(to: bgView , multiplier: 0.8)
        
        numLabel.centerYToSuperview()
        numLabel.trailingToSuperview(offset: 30 * Theme.factor)
        numLabel.width(150 * Theme.factor)
        numLabel.height(to: bgView , multiplier: 0.8)
        /*
        NSLayoutConstraint.useAndActivateConstraints(constraints: [
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,constant: 30 * Theme.factor),
            titleLabel.widthAnchor.constraint(equalToConstant: 150 * Theme.factor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor,multiplier: 0.8) ,
            
            numLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            numLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            numLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            numLabel.heightAnchor.constraint(equalTo: titleLabel.heightAnchor)
        ])*/
        
    }
    
    func setData(model:ChartModel) {
        self.titleLabel.text = model.name
        self.numLabel.text = String(Int(model.value)) + "元"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
