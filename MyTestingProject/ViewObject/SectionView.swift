//
//  SectionView.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/13.
//

import Foundation
import UIKit
import Combine
protocol SectionViewDelegate {
    func sectionView(_ section:SectionView,_ didPressTag:Int,_ isExpand:Bool)
}


class SectionView:UITableViewHeaderFooterView {
    let titleLabel = UILabel.createLabel(size: 16, color: .black,text:"default")
    let arrowBtn = UIButton()
    
    var delegate:SectionViewDelegate?
    var buttonTag = 0
    var isExpand = true
    
    let upImage = UIImage.rotateImage( UIImage(named:"arrow")!, withAngle: 90)
    let downImage = UIImage.rotateImage( UIImage(named:"arrow")!, withAngle: -90)
    
    var cancelList:AnyCancellable!
    override init(reuseIdentifier: String?){
        super.init(reuseIdentifier: reuseIdentifier)
        self.arrowBtn.setImage(self.upImage, for: .normal)
        //arrowBtn.addTarget(self, action: #selector(btnAct), for: .touchUpInside)
        cancelList = arrowBtn.publisher().sink(receiveValue: { [weak self] _ in
            guard let self = self else { return }
            self.isExpand = !self.isExpand
            if ( self.isExpand ) {
                self.arrowBtn.setImage(self.upImage, for: .normal)
            }
            else {
                self.arrowBtn.setImage(self.downImage, for: .normal)
            }
            self.delegate?.sectionView(self, self.buttonTag, self.isExpand)
        })
        
        
        self.addSubviews(titleLabel,arrowBtn)
        
        titleLabel.centerY(to: self)
        titleLabel.leading(to: self,offset: 10 * Theme.factor)
        titleLabel.trailingToLeading(of: arrowBtn,offset: -20 * Theme.factor)
        titleLabel.height(to: self)
        
        arrowBtn.centerY(to: self)
        arrowBtn.trailing(to: self,offset: -10 * Theme.factor)
        arrowBtn.size(CGSize(width: 50 * Theme.factor, height: 50 * Theme.factor))
        
        layer.borderColor = UIColor.black.cgColor
        layer.borderWidth = 1
    }
    
    
    @objc func btnAct() {
        self.isExpand = !self.isExpand
        if ( self.isExpand ) {
            self.arrowBtn.setImage(self.upImage, for: .normal)
        }
        else {
            self.arrowBtn.setImage(self.downImage, for: .normal)
        }
        self.delegate?.sectionView(self, self.buttonTag, self.isExpand)
    }
    
    func setTitle(title:String) {
        self.titleLabel.text = title
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
