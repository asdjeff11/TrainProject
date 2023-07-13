//
//  ChartViewController.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/13.
//

import Foundation
import UIKit
import Charts
import Combine
import TinyConstraints
class ChartViewController:UIViewController {
    enum ShapeState:Int {
        case 長方圖 = 0
        case 圓餅圖
        case 折線圖
        static var count: Int { return ShapeState.折線圖.rawValue + 1}
        
        var description: String {
            switch self {
                case .長方圖  : return "長方圖"
                case .圓餅圖  : return "圓餅圖"
                case .折線圖  : return "折線圖"
            }
        }
    }
    
    
    var selectRow = 0 // pickerView.selectRow
    let textField = TextField()
    let pickerView = UIPickerView()
    let chartView = UIView() // 中間要顯示的圖形樣式
    var tableView = UITableView() // 將資料清單顯示在下方
    var cancelList = [AnyCancellable]()
    @Published var myShapeState:ShapeState = .長方圖
    
    var models = [ChartModel]()
    
    override func viewWillTerminate() {
        super.viewWillTerminate()
        cancelList.removeAll()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        layout()
        testData()
        
        $myShapeState
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] _ in
                guard let self = self else { return }
                for view in self.chartView.subviews {
                    view.removeFromSuperview()
                }
                
                switch ( self.myShapeState ) {
                case .長方圖 :
                    let barCharView = MyBarChartView()
                    self.chartView.addSubview(barCharView)
                    barCharView.edgesToSuperview()
                    barCharView.setData(datas: self.models)
                    print("長方圖")
                case .圓餅圖 :
                    let pieCharView = MyPieChartView()
                    self.chartView.addSubview(pieCharView)
                    pieCharView.edgesToSuperview()
                    pieCharView.setData(datas: self.models)
                    
                    print("圓餅圖")
                case .折線圖 :
                    let lineChartView = MyLineChartView()
                    
                    self.chartView.addSubview(lineChartView)
                    lineChartView.edgesToSuperview()
                    
                    lineChartView.setData(datas: self.models)
                    print("折線圖")
                }
            }).store(in: &cancelList)
        
        let tapG = UITapGestureRecognizer(target: self, action: #selector(endEdit))
        self.view.addGestureRecognizer(tapG)
    }
    
    
    func setUp() {
        view.layer.contents = Theme.backGroundImage
        
        setUpNav(title: "資料圖形")
        
        textField.layer.cornerRadius = 15
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.black.cgColor
        textField.placeholder = "請選擇顯示圖形"
        textField.inputView = pickerView
        textField.text = myShapeState.description
        textField.delegate = self
    
        //chartView.backgroundColor = .clear
        
        pickerView.selectRow(0, inComponent: 0, animated: true)
        pickerView.delegate = self
        
        tableView.layer.cornerRadius = 20
        tableView.backgroundColor = #colorLiteral(red: 0.9483451997, green: 0.9559999704, blue: 0.766901563, alpha: 1)  
        tableView.separatorStyle = .none
        tableView.register(ChartCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func layout() {
        let textFieldLabel:UILabel = UILabel.createLabel(size: 20, color: .black, text: "請選擇圖示:")
        
        let margins = view.layoutMarginsGuide
        view.addSubviews(textFieldLabel,textField, chartView,tableView)
        
        textFieldLabel.top(to: margins,offset: 50 * Theme.factor)
        textFieldLabel.size(CGSize(width: 200 * Theme.factor, height: 50 * Theme.factor))
        textFieldLabel.leftToSuperview(offset: 50 * Theme.factor)
        
        textField.centerY(to: textFieldLabel)
        textField.height(to: textFieldLabel)
        textField.leadingToTrailing(of: textFieldLabel)
        textField.trailingToSuperview(offset: 50 * Theme.factor)
        
        chartView.topToBottom(of: textFieldLabel, offset: 50 * Theme.factor)
        chartView.centerXToSuperview()
        chartView.size(CGSize(width: 600 * Theme.factor, height: 500 * Theme.factor))
        
        
        tableView.top(to: chartView, chartView.bottomAnchor, offset: 50 * Theme.factor)
        tableView.centerXToSuperview(multiplier: 1)
        tableView.width(to: view , multiplier: 0.8)
        tableView.bottomToSuperview(offset: -50 * Theme.factor)
        
    }
    
    @objc func endEdit() {  //hide keyboard
        self.view.endEditing(true)
    }  //hide keyboard
}

extension ChartViewController:UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let shape = ShapeState(rawValue: selectRow)
        else { return }
        myShapeState = shape
    }
}

extension ChartViewController:UIPickerViewDelegate, UIPickerViewDataSource {
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return ShapeState.count
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return ShapeState(rawValue: row)?.description
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectRow = row
        self.textField.text = ShapeState(rawValue: row)?.description
        self.view.endEditing(true)
    }
}

extension ChartViewController:UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count * 2
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if ( indexPath.row % 2 == 0 ) {
            return 30 * Theme.factor
        }
        else {
            return 150 * Theme.factor
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if ( indexPath.row % 2 == 0 ) {
            let spaceCell = UITableViewCell(style: .default, reuseIdentifier: "blank")
            spaceCell.layer.borderWidth = 0
            spaceCell.backgroundColor = UIColor.clear
            spaceCell.isUserInteractionEnabled = false
            return spaceCell
        }
        else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? ChartCell else { return UITableViewCell() }
            
            let index = indexPath.row / 2
            cell.setData(model: models[index])
            return cell 
        }
    }
}

extension ChartViewController {
    func testData() {
        models.removeAll()
        models.append( ChartModel(name: "早餐", value: 3000))
        models.append( ChartModel(name: "午餐", value: 4500))
        models.append( ChartModel(name: "晚餐", value: 6000))
        models.append( ChartModel(name: "通勤", value: 2400))
        models.append( ChartModel(name: "電話費", value: 750))
        models.append( ChartModel(name: "電費", value: 342))
        models.append( ChartModel(name: "水費", value: 270))
        models.append( ChartModel(name: "瓦斯費", value: 1500))
        models.append( ChartModel(name: "遊戲點數", value: 3000))
        models.append( ChartModel(name: "衣服", value: 1890))
        models.append( ChartModel(name: "旅遊", value: 4800))
        
    }
}
