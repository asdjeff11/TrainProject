//
//  AppDelegate.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2022/9/1.
//

import UIKit

class CustomSegmentedControl: UIControl{
    var loading = false
    var buttons = [UIButton]()
    var selector: UIView!
    var selectedSegmentIndex = 0
    
    var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    
    var borderColor: UIColor = .clear{
        didSet{
            layer.borderColor = borderColor.cgColor
        }
    }
    
    var commaSeperatedButtonTitles: String = "" {
        
        didSet {
            updateView()
        }
    }
    
    var textColor: UIColor = .lightGray {
        didSet {
            for i in 0..<buttons.count {
                if ( i != selectedSegmentIndex ) {
                    buttons[i].setTitleColor(textColor, for: .normal)
                }
            }
        }
    }
    
    var selectorColor: UIColor = .darkGray {
    
        didSet {
            selector.backgroundColor = selectorColor
        }
    }
    
    var selectorTextColor: UIColor = .green {
        
        didSet {
            if ( selectedSegmentIndex < buttons.count ) {
                buttons[selectedSegmentIndex].setTitleColor(selectorTextColor, for: .normal)
            }
        }
    }
    
    override init(frame: CGRect){
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateView() {

        buttons.removeAll()
        // remove at once all subviews from a superview instead of removing them one by one.
        subviews.forEach { (view) in
            view.removeFromSuperview()
        }
        // remove at once all subviews from a superview instead of removing them one by one.
        
        let buttonTitles = commaSeperatedButtonTitles.components(separatedBy: ",")
        
        for buttonTitle in buttonTitles {
            
            let button = UIButton.init(type: .system)
            button.setTitle(buttonTitle, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 16)
            button.setTitleColor(textColor, for: .normal)
            button.addTarget(self, action: #selector(buttonTapped(button:)), for: .touchUpInside) // 點擊 呼叫buttontapped
            buttons.append(button)
        }
     
        buttons[0].setTitleColor(selectorTextColor, for: .normal)
        
        
        
        let selectorWidth = frame.width / CGFloat(buttonTitles.count)
        
        let y = (self.frame.maxY - self.frame.minY) - 3.0
        
        selector = UIView.init(frame: CGRect.init(x: 5, y: y, width: selectorWidth, height: 3.0))
        
        selector.backgroundColor = selectorColor
        addSubview(selector)
        
        // Create a StackView
        
        let stackView = UIStackView.init(arrangedSubviews: buttons)
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 0.0
        addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        stackView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        stackView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        
        // Drawing code
        
        // layer.cornerRadius = frame.height/2
        
    }
    
    @objc func buttonTapped(button: UIButton) {
        if ( loading ) {
            return
        }
        for (buttonIndex,btn) in buttons.enumerated() {
            // 將button Array 變成 [buttonIndex,btn]
            // buttonIndex為一序列 所對應到多少個btn
            btn.setTitleColor(textColor, for: .normal)
            
            if btn == button {
                selectedSegmentIndex = buttonIndex // 選定我所選的button
                
                var padding: CGFloat = 0
                
                if buttonIndex != buttons.count - 1 {
                    padding = 5
                } else {
                    padding = 0
                }
                
                let  selectorStartPosition = frame.width / CGFloat(buttons.count) * CGFloat(buttonIndex)
                
                UIView.animate(withDuration: 0.3, animations: {
                    
                    self.selector.frame.origin.x = selectorStartPosition + padding
                })
                
                btn.setTitleColor(selectorTextColor, for: .normal)
            }
        }
        
        sendActions(for: .valueChanged) // 傳遞資訊告知 值被更改 讓上一個view controller 去呼叫對應函數
        
        // 會叫committeeMainViewController 去呼叫segmentChange函數 刷新tableView
        
    }
    
    func updateSegmentedControlSegs(index: Int) {
        
        for btn in buttons {
            btn.setTitleColor(textColor, for: .normal)
        }
        
        let  selectorStartPosition = frame.width / CGFloat(buttons.count) * CGFloat(index)
        
        UIView.animate(withDuration: 0.3, animations: {
            
            self.selector.frame.origin.x = selectorStartPosition
        })
        
        buttons[index].setTitleColor(selectorTextColor, for: .normal)
        
    }
}
