//
//  MyButton.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/7/11.
//

import UIKit

enum ButtonColor {
    case yellow
}

struct ButtonStyle {
    var color:ButtonColor
    var text:String?
    var fontSize:CGFloat = 28
    init(color:ButtonColor , text:String? = nil , fontSize:CGFloat? = nil) {
        self.color = color
        self.text = text
        if let fontSize = fontSize {
            self.fontSize = fontSize
        }
    }
}

class MyButton:UIButton {
    var shadowColor: UIColor = UIColor.clear {
        didSet {
            layer.shadowOffset = CGSize(width: 0, height: 5)
            layer.shadowOpacity = 1
            layer.shadowRadius = 0
            layer.shadowColor = shadowColor.cgColor
        }
    }
    
    var cornerRadius: CGFloat = 8 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    
    var fontSize: CGFloat = 28 {
        didSet {
            titleLabel?.font = .systemFont(ofSize: fontSize)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = cornerRadius
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.minimumScaleFactor = 0.2
        titleLabel?.baselineAdjustment = .alignCenters
        titleLabel?.font = .systemFont(ofSize: fontSize)
    }
    
    convenience init(style:ButtonStyle) {
        self.init()
        layer.cornerRadius = cornerRadius
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.minimumScaleFactor = 0.2
        titleLabel?.baselineAdjustment = .alignCenters
        updateStyle(style: style)
    }
    
    convenience init( color:ButtonColor , fontSize:CGFloat? = nil ) {
        self.init()
        layer.cornerRadius = cornerRadius
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.minimumScaleFactor = 0.2
        titleLabel?.baselineAdjustment = .alignCenters
        titleLabel?.font = .systemFont(ofSize: fontSize ?? self.fontSize)
        
        switch ( color ) {
        case .yellow :
            self.backgroundColor = Theme.yellowBtn
            self.shadowColor = Theme.yellowBtnShadow
        }
        
        layer.shadowOffset = CGSize(width: 0, height: 5)
        layer.shadowOpacity = 1
        layer.shadowRadius = 0
        layer.shadowColor = shadowColor.cgColor
    }
    
    public func updateStyle(style:ButtonStyle) {
        titleLabel?.font = .systemFont(ofSize: style.fontSize)
        
        switch ( style.color ) {
        case .yellow :
            self.backgroundColor = Theme.yellowBtn
            self.shadowColor = Theme.yellowBtnShadow
        }
        
        if let text = style.text {
            self.setTitle(text, for: .normal)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }}
