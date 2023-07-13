//
//  LabelTextField.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/7.
//

import Foundation
import UIKit
class LabelTextField:UIView{
    let label:UILabel
    let textField:TextField
    
    init(labelName:String, textSize:CGFloat,textColor:UIColor) {
        label = UILabel.createLabel(size: textSize, color: textColor, text:labelName)
        textField = TextField()
        textField.layer.borderColor = UIColor.black.cgColor
        textField.layer.cornerRadius = 10
        textField.layer.borderWidth = 0.5
        super.init(frame: CGRect.zero)
        layout()
    }
    
    private func layout() {
        self.addSubviews(label,textField)
        NSLayoutConstraint.useAndActivateConstraints(constraints: [
            label.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            label.widthAnchor.constraint(equalToConstant: 100),
            label.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            label.heightAnchor.constraint(equalTo: self.heightAnchor),
            
            textField.leadingAnchor.constraint(equalTo: label.trailingAnchor,constant: 10),
            textField.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            textField.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            textField.heightAnchor.constraint(equalTo:label.heightAnchor)
        ])
    }
    
    
    func setLabelText(size:CGFloat,color:UIColor) {
        label.font = .systemFont(ofSize: size)
        label.textColor = color
    }
    
    func setTextField(color:UIColor?,hint:String?,hintColor:UIColor?) {
        if let color = color {
            textField.textColor = color
        }
        
        if let hint = hint {
            textField.attributedPlaceholder = NSAttributedString(string: hint,attributes: [NSAttributedString.Key.foregroundColor: hintColor ?? UIColor(hex:0xA9A9A9)])
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
