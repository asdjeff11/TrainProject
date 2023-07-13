//
//  BluetoothTranslateData.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/16.
//

import Foundation
import CoreBluetooth
import Combine
import UIKit
class BluetoothTranslateData:UIViewController {
    var ble:BlueTooth!
    
    let textField = TextField()
    let sendBtn = UIButton()
    let textView = UITextView() // 由android傳遞過來的資訊
    
    var isLoading = false
    var cancelList = [AnyCancellable]() 
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        layout()
        ble.handler = { [weak self] (msg:String) in
            self?.receiveMsg(msg: msg)
        }
        
        ble.connectErrorHandler = { [weak self] in
            DispatchQueue.main.async {
                let alertAction = UIAlertAction(title: "確認", style:.default) { _ in
                    self?.leftBtnAct()
                }
                self?.showAlert(alertText: "提醒", alertMessage: "連接裝置已斷開",alertAction: alertAction)
            }
        }
        
        let tapG = UITapGestureRecognizer(target: self, action: #selector(closeKeyboard))
        view.addGestureRecognizer(tapG)
    }
    
    override func viewWillTerminate() {
        ble.handler = nil
        ble.connectErrorHandler = nil
        cancelList.removeAll()
    }
    
    @objc func closeKeyboard() {
        self.view.endEditing(true)
    }
}

extension BluetoothTranslateData {
    func setUp() {
        setUpNav(title: "藍芽資訊傳接",backButtonVisit: true)
        view.layer.contents = Theme.backGroundImage
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.black.cgColor
        textField.layer.cornerRadius = 15
        
        sendBtn.titleLabel?.font = .systemFont(ofSize: 16)
        sendBtn.layer.cornerRadius = 15
        sendBtn.setTitle("傳送資訊", for: .normal)
        sendBtn.setTitleColor(.white, for: .normal)
        sendBtn.backgroundColor = Theme.navigationBarBG
        sendBtn.publisher()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] _ in
                guard let self = self,
                      self.isLoading == false,
                      let msg = self.textField.text,
                      let data = msg.data(using: .utf8)  else { return }
                do {
                    try self.ble.sendData(data, writeType: .withResponse)
                }
                catch {
                    self.showAlert(alertText: "資料錯誤", alertMessage: error.localizedDescription)
                }
            })
            .store(in: &cancelList)
        
        textView.backgroundColor = UIColor(hex: 0x000000 , alpha: 0.2)
        textView.layer.cornerRadius = 15
        textView.layer.borderColor = UIColor.white.cgColor
        textView.layer.borderWidth = 1
        textView.isEditable = false
    }
    
    func layout() {
        let titleLabel = UILabel.createLabel(size: 16, color: .black,text:"輸入訊息:")
        let receiveLabel = UILabel.createLabel(size: 16, color: .black,text:"接收到的訊息:")
        view.addSubviews(titleLabel,textField,receiveLabel,textView,sendBtn)
        
        let margins = view.layoutMarginsGuide
        titleLabel.top(to: margins,offset: 30 * Theme.factor)
        titleLabel.leadingToSuperview(offset: 70 * Theme.factor)
        titleLabel.size(CGSize(width: 150 * Theme.factor, height: 50 * Theme.factor))
        
        textField.centerY(to: titleLabel)
        textField.trailingToSuperview(offset: 30 * Theme.factor)
        textField.leadingToTrailing(of: titleLabel)
        textField.height(to: titleLabel)
        
        receiveLabel.topToBottom(of: titleLabel,offset: 30 * Theme.factor)
        receiveLabel.leading(to: titleLabel)
        receiveLabel.sizeToFit()
        
        textView.leading(to: receiveLabel)
        textView.topToBottom(of: receiveLabel,offset: 20 * Theme.factor)
        textView.trailing(to: textField)
        textView.height(600 * Theme.factor)
        
        sendBtn.bottom(to: view,offset: -70 * Theme.factor)
        sendBtn.centerXToSuperview()
        sendBtn.size(CGSize(width: 200 * Theme.factor, height: 70 * Theme.factor))
    }
    
    func receiveMsg(msg:String) {
        Task.detached(operation: { @MainActor [weak self] in
            self?.textView.text = msg
        })
    }
}
