//
//  GoogleMapTestCell.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/8.
//

import Foundation
import UIKit
class GoogleMapTestCell:UITableViewCell {
    private let nameLabel = UILabel.createLabel(size: 16, color: .black)
    private let myImageView = MyImageView(imageMode:.fillAndClip)
    private let addressLabel = UILabel.createLabel(size: 12, color: .black)
    private let dateLabel = UILabel.createLabel(size: 12, color: .black)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        
        let detailView = UIStackView(arrangedSubviews: [nameLabel,addressLabel,dateLabel])
        detailView.distribution = .equalSpacing
        detailView.axis = .vertical
        detailView.spacing = 10 * Theme.factor
        detailView.layer.borderWidth = 1
        detailView.layer.borderColor = UIColor.black.cgColor
        
        contentView.addSubviews(myImageView,detailView)
        NSLayoutConstraint.useAndActivateConstraints(constraints: [
            myImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            myImageView.widthAnchor.constraint(equalToConstant: 500 * Theme.factor),
            myImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            myImageView.heightAnchor.constraint(equalTo: myImageView.widthAnchor),
            
            detailView.topAnchor.constraint(equalTo: myImageView.bottomAnchor),
            detailView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            detailView.leadingAnchor.constraint(equalTo: myImageView.leadingAnchor),
            detailView.trailingAnchor.constraint(equalTo: myImageView.trailingAnchor)
        ])
    }
    
    
    func setData(place:FavoritePlace) {
        nameLabel.text = "地點：" + place.name
        addressLabel.text = "地址：" + place.address
        dateLabel.text = "加入最愛日期：" + place.date
    }
    
    func setPic(image:UIImage?) {
        myImageView.image = image
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


