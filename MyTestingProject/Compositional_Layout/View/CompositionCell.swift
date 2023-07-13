//
//  CompositionCell.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/7/6.
//
import UIKit
class CompositionCell:UICollectionViewCell {
    private let label = UILabel.createLabel(size: 20 * Theme.factor, color: .black)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = nil
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.black.cgColor
        contentView.addSubview(label)
        label.centerInSuperview()
        
    }
    
    override var isSelected: Bool {
        didSet {
            backgroundColor = isSelected ? .systemCyan : .clear
            label.textColor = isSelected ? .white : .black
        }
    }
    
    func setContent(str:String) {
        self.label.text = str
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
