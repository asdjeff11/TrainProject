//
//  CombineView.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/7.
//

import Foundation
import UIKit
import Combine
class CombineView:UIViewController {
    private lazy var mySegmented: CustomSegmentedControl = {
        let segment = CustomSegmentedControl(frame: CGRect(x: 0, y: 0, width: Theme.fullSize.width, height: Theme.fullSize.height/15))
        segment.translatesAutoresizingMaskIntoConstraints = false
        segment.commaSeperatedButtonTitles = "註冊申請,註冊紀錄"
        segment.backgroundColor = .white
        let blueColor = UIColor(hex: 0xFFCC00)
        segment.selectorTextColor = blueColor
        segment.selectorColor = blueColor
        return segment
    }() // "社區公告,活動通知,會議記錄" 選擇器
    
    let nameTextField = LabelTextField(labelName: "姓    名：", textSize: 20, textColor: .black)
    let emailTextField = LabelTextField(labelName: "信   箱：", textSize: 20, textColor: .black)
    let passwordTextField = LabelTextField(labelName: "密    碼：", textSize: 20, textColor: .black)
    let confirmedPasswordTextField = LabelTextField(labelName: "確認密碼：", textSize: 20, textColor: .black)
    var privatyCheckBox = UIButton()
    let confirmButton = UIButton()
    
    let tableView = UITableView() // 註冊紀錄畫面
    let applyView = UIView() // 註冊畫面
    
    lazy var refreshControl:UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.tintColor = .black
        refresh.attributedTitle = NSAttributedString(string: "Loading",attributes: [NSAttributedString.Key.foregroundColor : UIColor.black])
        refresh.addTarget(self, action: #selector(refreshData), for: UIControl.Event.valueChanged)
        return refresh
    }()
    
    var cancelList:Set<AnyCancellable> = []
    let viewModel = CombineViewModel()
    var isLoading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.contents = Theme.backGroundImage
        setUp()
        layout()
        loading(isLoading: &isLoading)
        viewModel.updateData(completion:{ [weak self] in
            guard let self = self else { return }
            self.tableView.reloadData()
            self.removeLoading(isLoading: &self.isLoading)
            self.setUIComponent()
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelList.removeAll()
    }
    
    private func setUp() {
        setUpNav(title: "註冊帳號")
        let textFieldColor = UIColor(named:"font_textFieldColor") , hintColor = UIColor(hex: 0xA9A9A9)
        nameTextField.setTextField(color: textFieldColor, hint: "請輸入姓名", hintColor: hintColor)
        emailTextField.setTextField(color: textFieldColor, hint: "請輸入信箱", hintColor: hintColor)
        passwordTextField.setTextField(color: textFieldColor, hint: "請輸入密碼", hintColor: hintColor)
        confirmedPasswordTextField.setTextField(color: textFieldColor, hint: "請再次輸入密碼", hintColor: hintColor)
        
        //privatyCheckBox.titleLabel?.font = .systemFont(ofSize: 20)
        let checkBoxD = UIImage.resize_no_cut(image: UIImage(named: "checkBox(default)")!, newSize: CGSize(width: 20, height: 20))
        let checkBoxS = UIImage.resize_no_cut(image: UIImage(named: "checkBox(select)")!, newSize: CGSize(width: 20, height: 20))
       
        if #available(iOS 15, *) {
            var configuration = UIButton.Configuration.plain()
            var title = AttributedString("同意以上規則請打勾")
            title.foregroundColor = .black
            title.font = .systemFont(ofSize: 14)
            configuration.attributedTitle = title
            configuration.baseBackgroundColor = .clear
            configuration.imagePadding = 10
            configuration.image = checkBoxD
            /*let action = UIAction { _ in
                self.privatyCheckBox.isSelected.toggle()
                self.privatyCheckBox.setNeedsUpdateConfiguration()
            }*/
            privatyCheckBox = UIButton(configuration: configuration)
            
            privatyCheckBox.configurationUpdateHandler = { [unowned self] button in
                var config = button.configuration
                config?.image = self.privatyCheckBox.isSelected ? checkBoxS : checkBoxD
                button.configuration = config
            }
        }
        else {
            privatyCheckBox.setTitle("請同意以上規則", for: .normal)
            privatyCheckBox.setTitleColor(.black, for: .normal)
            
            privatyCheckBox.setImage(checkBoxD, for: .normal)
            privatyCheckBox.setImage(checkBoxS, for: .selected)
            
            privatyCheckBox.imageEdgeInsets = UIEdgeInsets(top: 0, left: 1, bottom: 0, right: 1)
            privatyCheckBox.titleEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: -10)
        }
        
        confirmButton.layer.shadowColor = UIColor(hex: 0xFFCC00,alpha: 0.25).cgColor
        confirmButton.layer.shadowOffset = CGSize(width: 0, height: 5)
        confirmButton.layer.shadowOpacity = 1.0
        confirmButton.layer.shadowRadius = 10.0
        confirmButton.layer.masksToBounds = false
        confirmButton.setTitle("確認送出", for: .normal)
        confirmButton.backgroundColor = UIColor(hex: 0xFFCC00)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.layer.cornerRadius = 20
        
        tableView.refreshControl = refreshControl
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.allowsSelection = false
        tableView.register(CombineCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isHidden = true
    }
    
    private func setUIComponent() {
        nameTextField.textField.publisherForTextChange().sink(receiveValue: { [weak self] in
            // map 完之後 把資料傳給訂閱者 (就是這邊)
            guard let self = self else { return }
            self.viewModel.name = $0 ?? ""
        }).store(in: &cancelList)
        
        emailTextField.textField.publisherForTextChange().sink(receiveValue: { [weak self] in
            guard let self = self else { return }
            self.viewModel.email = $0 ?? ""
        }).store(in: &cancelList)
        
        passwordTextField.textField.publisherForTextChange().sink(receiveValue: { [weak self] in
            guard let self = self else { return }
            self.viewModel.pwd = $0 ?? ""
        }).store(in: &cancelList)
        
        confirmedPasswordTextField.textField.publisherForTextChange().sink(receiveValue: { [weak self] in
            guard let self = self else { return }
            self.viewModel.confirmPwd = $0 ?? ""
        }).store(in: &cancelList)
        
        privatyCheckBox.publisher().sink(receiveValue:{ [weak self] in
            guard let self = self else { return }
            //self.privatyCheckBox.isSelected.toggle()
            self.privatyCheckBox.setNeedsUpdateConfiguration()
            self.viewModel.accept = $0
        }).store(in: &cancelList)
        
        viewModel.validToRegisterPublisher
            .receive(on:RunLoop.main)
            .assign(to: \.isEnabled, on: confirmButton)
            .store(in: &cancelList)
        
        confirmButton.publisher().sink(receiveValue:{ [weak self] _ in
            guard let self = self else { return }
            self.loading(isLoading: &self.isLoading)
            self.viewModel.setDataToDb(completion:{ [weak self] (result) in
                guard let self = self else { return }
                self.removeLoading(isLoading: &self.isLoading)
                if ( !result ) {
                    self.showAlert(alertText: "儲存錯誤", alertMessage: "建立UserData資料錯誤")
                }
                else {
                    self.showAlert(alertText: "儲存成功", alertMessage: "已建立UserData資訊")
                }
            })
        }).store(in: &cancelList)
        
        mySegmented.publisher().sink(receiveValue:{ [weak self] (result) in
            guard let self = self else { return }
            if ( result == 0 ) {
                self.tableView.isHidden = true
                self.applyView.isHidden = false
            }
            else {
                self.tableView.isHidden = false
                self.applyView.isHidden = true
                self.tableView.reloadData()
            }
        }).store(in: &cancelList)
    }
    
    private func layout() {
        let regulationLabel = UILabel.createLabel(size: 20, color: .black,text:getRegulation())
        regulationLabel.lineBreakMode = .byCharWrapping
        regulationLabel.numberOfLines = 0
        let scrollView = UIScrollView()
        scrollView.addSubviews(regulationLabel)
        
        let stackView = UIStackView(arrangedSubviews: [nameTextField,emailTextField,passwordTextField,confirmedPasswordTextField])
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.spacing = 30
        
        applyView.addSubviews(stackView,scrollView,privatyCheckBox,confirmButton)
        
        view.addSubviews(mySegmented,applyView,tableView)
        
        let margins = view.layoutMarginsGuide
        
        NSLayoutConstraint.useAndActivateConstraints(constraints: [
            mySegmented.topAnchor.constraint(equalTo: margins.topAnchor),
            mySegmented.heightAnchor.constraint(equalToConstant: mySegmented.frame.height),
            mySegmented.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mySegmented.widthAnchor.constraint(equalTo: view.widthAnchor),
            
            applyView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            applyView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            applyView.topAnchor.constraint(equalTo: mySegmented.bottomAnchor),
            applyView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: mySegmented.bottomAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        
        NSLayoutConstraint.useAndActivateConstraints(constraints: [
    
            stackView.leadingAnchor.constraint(equalTo: applyView.leadingAnchor,constant: 30),
            stackView.trailingAnchor.constraint(equalTo: applyView.trailingAnchor,constant: -30),
            stackView.topAnchor.constraint(equalTo: mySegmented.bottomAnchor, constant: 30),
            stackView.heightAnchor.constraint(equalToConstant: 210),
            
            regulationLabel.topAnchor.constraint(equalTo: scrollView.topAnchor),
            regulationLabel.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            regulationLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            regulationLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            
            scrollView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: stackView.bottomAnchor,constant: 30),
            scrollView.heightAnchor.constraint(equalToConstant: 150),
            
            privatyCheckBox.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            privatyCheckBox.topAnchor.constraint(equalTo: scrollView.bottomAnchor,constant: 20),
            
            confirmButton.centerXAnchor.constraint(equalTo: applyView.centerXAnchor),
            confirmButton.topAnchor.constraint(equalTo: privatyCheckBox.bottomAnchor,constant: 30),
            confirmButton.widthAnchor.constraint(equalToConstant: 200),
            confirmButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        
    }
    
    private func getRegulation()->String {
        var result = ""
        do {
            if let regulationURL = Bundle.main.url(forResource: "regulation", withExtension: "txt") {  // 呼叫city.txt 檔案
                result = try String(contentsOf: regulationURL)
            }
        }
        catch {
            print(error)
        }
        
        return result
    }
}

extension CombineView:UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getLen() * 2
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if ( indexPath.row % 2 != 0 ) {
            return 30
        }
        else {
            return UITableView.automaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row % 2 != 0 { // space
            let spaceCell = UITableViewCell(style: .default, reuseIdentifier: "blank")
            spaceCell.backgroundColor = UIColor.clear
            spaceCell.isUserInteractionEnabled = false
            return spaceCell
        }
        else { // data
            let index = indexPath.row / 2
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? CombineCell else { return UITableViewCell() }
            if let userData = viewModel.getUserData(index: index) {
                cell.setData(userData: userData)
            }
            return cell
        }
    }
    
    @objc func refreshData() {
        viewModel.updateData(completion:{ [weak self] in
            guard let self = self else { return }
            self.refreshControl.endRefreshing()
            self.tableView.reloadData()
        })
    }
}
