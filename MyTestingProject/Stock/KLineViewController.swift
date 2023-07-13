//
//  KLineViewController.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/15.
//

import Foundation
import UIKit
import Combine
class KLineViewController:UIViewController {
    let btn = UIButton()
    let kLineView = KLineView()
    let pickerView = UIPickerView()
    let textField = TextField()
    
    let dates:[Date] = {
        var myList = [Date]()
        // 36個月
        var now = Date()
        let formatter = Theme.customFormatter(dateType: "yyyyMMdd")
        for i in 0..<36 {
            myList.append(now.getOffsetDay(type: .month, offset: -i))
        }
        return myList
    }()
    
    let viewModel = KLineViewModel()
    var isLoading = false
    //var cancelList = [AnyCancellable]()
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        layout()
        
        pickerView.selectRow(0, inComponent: 0, animated: true)
    }
    
    func setUp() {
        setUpNav(title: "股票圖(大盤)")
        view.layer.contents = Theme.backGroundImage
        
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.black.cgColor
        textField.layer.cornerRadius = 15
        textField.inputView = pickerView
        
        pickerView.delegate = self
        /*
        btn.setTitle("送出訊息", for: .normal)
        btn.layer.cornerRadius = 15
        btn.backgroundColor = Theme.navigationBarBG
        btn.setTitleColor( .white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16)
        
        btn.publisher().sink(receiveValue: { [weak self] _ in
            guard let self = self else { return }
            self.loading(isLoading: &self.isLoading)
            Task {
                await self.callViewModelToGetData(date:Date())
            }
            
        }).store(in: &cancelList)*/
    }
    
    func layout() {
        let margins = view.layoutMarginsGuide
        
        let textLabel = UILabel.createLabel(size: 16, color: .black,text:"請選擇日期")
        
        view.addSubviews(textLabel,textField,kLineView)
        
        textLabel.top(to: margins,offset: 50 * Theme.factor)
        textLabel.leadingToSuperview(offset: 70 * Theme.factor)
        textLabel.size(CGSize(width: 150 * Theme.factor, height: 50 * Theme.factor))
        
        textField.centerY(to: textLabel)
        textField.leadingToTrailing(of: textLabel,offset: 10 * Theme.factor)
        textField.height(to: textLabel)
        textField.trailingToSuperview(offset: 70 * Theme.factor)
        
        kLineView.topToBottom(of: textLabel,offset: 30 * Theme.factor)
        kLineView.centerX(to: view)
        kLineView.size(CGSize(width: 500 * Theme.factor, height: 500 * Theme.factor))
        /*
        btn.bottomToSuperview(offset: -50 * Theme.factor)
        btn.centerX(to: view)
        btn.size(CGSize(width: 200, height: 50))*/
        
    }
    
    func callViewModelToGetData(date:Date) async {
        var stockList:[StockKLine]? = nil
        var marketTrading:[MarketTradingInfo]? = nil
        defer {
            Task.detached { @MainActor in
                if let stockList = stockList , let marketTrading = marketTrading {
                    self.kLineView.setData(stockKLines: stockList,marketTradingInfos:marketTrading)
                }
                self.removeLoading(isLoading: &self.isLoading)
            }
        }
        do {
            (stockList,marketTrading) = try await viewModel.getMoreMonth(startDate: date, offset: 3)
        }
        catch {
            showAlert(alertText: "資料錯誤", alertMessage: error.localizedDescription)
        }
    }
}

extension KLineViewController:UIPickerViewDelegate, UIPickerViewDataSource {
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dates.count
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Theme.onlyDateFormatter.string(from: dates[row])
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.textField.text = Theme.onlyDateFormatter.string(from: dates[row])
        self.loading(isLoading: &self.isLoading)
        Task {
            await self.callViewModelToGetData(date:self.dates[row])
        }
        self.view.endEditing(true)
    }
}
