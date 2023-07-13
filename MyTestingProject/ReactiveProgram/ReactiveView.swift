//
//  ReactiveView.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/6.
//

import Foundation
import UIKit
import Combine
class ReactiveView:UIViewController {
    let inputField = UITextField()
    let viewModel = ReactiveViewModel()
    var setList = [AnyCancellable]()
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setList.removeAll()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.contents = Theme.backGroundImage
        setUp()
        layout()
    }
    
    
    
    private func setUp() {
        setUpNav(title: "測試Reactive Program")
        let textFieldPlaceHolderAttr = [NSAttributedString.Key.foregroundColor: UIColor(hex: 0xFCFCFC)] as [NSAttributedString.Key : Any]
        inputField.textColor = UIColor(named:"font_textFieldColor")
        inputField.text = "https://raw.githubusercontent.com/cmmobile/NasaDataSet/main/apod.json"
        inputField.layer.borderColor = UIColor.white.cgColor
        inputField.layer.borderWidth = 0.5
        inputField.attributedPlaceholder = NSAttributedString(string: "請輸入URL", attributes: textFieldPlaceHolderAttr)
        inputField.delegate = self
    }
    
    private func layout() {
        let button = UIButton()
        button.setTitle("確認送出", for: .normal)
        button.backgroundColor = Theme.navigationBarBG
        button.addTarget(self, action: #selector(pressBtnAction), for: .touchUpInside)
        
        //let margins = view.layoutMarginsGuide
        view.addSubviews(inputField,button)
        NSLayoutConstraint.useAndActivateConstraints(constraints: [
            inputField.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            inputField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            inputField.heightAnchor.constraint(equalToConstant: 30),
            inputField.widthAnchor.constraint(equalToConstant: 300),
            
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.topAnchor.constraint(equalTo: inputField.bottomAnchor,constant: 5),
            button.heightAnchor.constraint(equalToConstant: 30) ,
            button.widthAnchor.constraint(equalToConstant: 100)
        ])
        
    }
    
    @objc private func pressBtnAction(_ sender:UIButton) {
        guard let input = inputField.text, let url = URL(string: input) else { showAlert(alertText: "資料錯誤", alertMessage: "填寫url錯誤") ; return }
        viewModel.userPressButton(url: url)
    }
}

extension ReactiveView:UITextFieldDelegate {
    /*override func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if inputField.text == "" {
            
        }
    }
    
    override func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        <#code#>
    }*/
}
