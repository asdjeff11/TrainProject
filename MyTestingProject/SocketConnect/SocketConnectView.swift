//
//  SocketConnect.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/13.
//

import Foundation
import UIKit
import Combine
class SocketConnectView:UIViewController {
    let sendBtn = UIButton()
    let msgTextField = TextField()
    var cancelList = [AnyCancellable]()
    var isLoading = false
    let viewModel = SocketViewModel()
    
    override func viewWillTerminate() {
        super.viewWillTerminate()
        cancelList.removeAll()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.contents = Theme.backGroundImage
        setUp()
        layout()
        
        view.isUserInteractionEnabled = true
        let tapG = UITapGestureRecognizer(target: self, action: #selector(endit))
        view.addGestureRecognizer(tapG)
    }
    
    @objc func endit() {
        self.view.endEditing(false)
    }
}


extension SocketConnectView {
    func setUp() {
        setUpNav(title: "Sockect連線")
        
        sendBtn.setTitle("送出訊息", for: .normal)
        sendBtn.layer.cornerRadius = 15
        sendBtn.backgroundColor = Theme.navigationBarBG
        sendBtn.setTitleColor( .white, for: .normal)
        sendBtn.titleLabel?.font = .systemFont(ofSize: 16)
        sendBtn.publisher().sink(receiveValue: { [weak self] _ in
            guard let self = self ,
                  let msg = self.msgTextField.text
            else { return }
            self.loading(isLoading: &self.isLoading)
            self.viewModel.sendMsg(msg,completion: { (text:String) in
                self.removeLoading(isLoading: &self.isLoading)
                self.showAlert(alertText: "收到訊息", alertMessage: text)
            })
        }).store(in: &cancelList)
        
        msgTextField.layer.borderColor = UIColor.black.cgColor
        msgTextField.layer.borderWidth = 1
        msgTextField.placeholder = "請輸入欲傳送的訊息"
        msgTextField.layer.cornerRadius = 15
    }
    
    func layout() {
        let alertLabel = UILabel.createLabel(size: 16, color: .red,text:"測試對應到的port為 :9366\n 請開啟Server 監聽9366 port 後\n再傳送訊息")
        alertLabel.lineBreakMode = .byCharWrapping
        alertLabel.numberOfLines = 0
        
        let textTitleLabel = UILabel.createLabel(size: 20, color: .black,text:"訊息 :")
        
        view.addSubviews(textTitleLabel,msgTextField,alertLabel,sendBtn)
        
        let margins = view.layoutMarginsGuide
        NSLayoutConstraint.useAndActivateConstraints(constraints: [
            textTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor,constant: 70 * Theme.factor),
            textTitleLabel.widthAnchor.constraint(equalToConstant: 100 * Theme.factor),
            textTitleLabel.topAnchor.constraint(equalTo: margins.topAnchor,constant: 300 * Theme.factor),
            textTitleLabel.heightAnchor.constraint(equalToConstant: 50 * Theme.factor),
            
            msgTextField.leadingAnchor.constraint(equalTo: textTitleLabel.trailingAnchor,constant: 20 * Theme.factor),
            msgTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor,constant: -70 * Theme.factor),
            msgTextField.centerYAnchor.constraint(equalTo: textTitleLabel.centerYAnchor),
            msgTextField.heightAnchor.constraint(equalToConstant: 50 * Theme.factor),
        
            alertLabel.topAnchor.constraint(equalTo: textTitleLabel.bottomAnchor,constant: 50 * Theme.factor),
            alertLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            alertLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8 ),
            
            sendBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sendBtn.heightAnchor.constraint(equalToConstant: 50 * Theme.factor),
            sendBtn.bottomAnchor.constraint(equalTo: view.bottomAnchor,constant: -70 * Theme.factor),
            sendBtn.widthAnchor.constraint(equalToConstant: 200 * Theme.factor)
        ])
    }
}
