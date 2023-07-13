//
//  CombineCell.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/7.
//

import Foundation
import UIKit
class CombineCell:UITableViewCell {
    let nameLabel = UILabel.createLabel(size: 16, color: .black,text:"姓 名：")
    let emailLabel = UILabel.createLabel(size: 16, color: .black,text:"信    箱：")
    let passwordLabel = UILabel.createLabel(size: 16, color: .black,text:"密 碼：")
    let dateLabel = UILabel.createLabel(size: 16, color: .black,text:"創建日期：")
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clear
        
        let stackView = UIStackView(arrangedSubviews: [dateLabel,nameLabel,emailLabel,passwordLabel])
        stackView.distribution = .equalSpacing
        stackView.axis = .vertical
        
        let myView = UIView()
        myView.layer.cornerRadius = 10
        myView.layer.borderColor = UIColor.black.cgColor
        myView.layer.borderWidth = 1
        myView.addSubview(stackView)
        
        contentView.addSubview(myView)
        
        NSLayoutConstraint.useAndActivateConstraints(constraints: [
            myView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,constant: 30),
            myView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,constant: -30),
            myView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            myView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.8),
            
            stackView.topAnchor.constraint(equalTo: myView.topAnchor , constant: 10),
            stackView.bottomAnchor.constraint(equalTo: myView.bottomAnchor , constant: -10),
            stackView.leadingAnchor.constraint(equalTo: myView.leadingAnchor , constant: 10),
            stackView.trailingAnchor.constraint(equalTo: myView.trailingAnchor , constant: -10)
        ])
    }
    
    func setData(userData:UserData) {
        self.nameLabel.text = "姓 名：\(userData.name)"
        self.emailLabel.text = "信    箱：\(userData.email)"
        self.passwordLabel.text = "密 碼：\(userData.password)"
        self.dateLabel.text = "創建日期：\(String(userData.date.prefix(10)))"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
