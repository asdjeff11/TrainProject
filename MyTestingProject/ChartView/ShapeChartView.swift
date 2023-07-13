//
//  ShapeChartView.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/14.
//

import Foundation
import Charts

// 折線圖
class MyLineChartView:LineChartView , ChartViewDelegate {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.doubleTapToZoomEnabled = false // 關閉雙擊縮放
        //self.zoom(scaleX: 2, scaleY: 0, x: 0, y: 0)
        //self.setScaleEnabled(false)
        //self.dragEnabled = true
        self.xAxis.wordWrapEnabled = true
        self.xAxis.labelPosition = .bottom
        
        //self.xAxis.avoidFirstLastClippingEnabled = true
        
        self.rightAxis.drawLabelsEnabled = false
        self.rightAxis.drawAxisLineEnabled = false
        self.delegate = self
    }
    
    func setData(datas:[ChartModel]) {
        var entries = [ChartDataEntry]()
        
        
        for i in 0..<datas.count {
            entries.append(ChartDataEntry(x:Double(i),y:datas[i].value,data:datas[i] as AnyObject))
        }
        
        let set = LineChartDataSet(entries: entries, label: "")

        //set.drawCirclesEnabled = false
        //set.mode = .cubicBezier
        set.lineWidth = 2
        set.drawHorizontalHighlightIndicatorEnabled = false
        set.highlightColor = .red
        //set.fill = ColorFill(cgColor: UIColor.white.cgColor)
        //set.fillAlpha = 0.8
        //set.drawFilledEnabled = true
        
        let chartData = LineChartData(dataSet: set)
        //chartData.setDrawValues(false)
        self.data = chartData
        self.xAxis.valueFormatter = IndexAxisValueFormatter(values: datas.map({ $0.name }))
        //self.xAxis.labelCount = datas.count
        xAxis.setLabelCount(datas.count, force: false)
        self.xAxis.granularityEnabled = true
        //self.xAxis.granularity = 1
        self.animate(xAxisDuration: 2.0, yAxisDuration: 2.0,easingOption: .easeInExpo)

    }
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        print(entry)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// 長方圖
class MyBarChartView:BarChartView , ChartViewDelegate {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.legend.form = .none
        self.leftAxis.axisMinimum = 0
        self.leftAxis.drawGridLinesEnabled = false
        self.xAxis.wordWrapEnabled = true
        self.xAxis.labelPosition = .bottom
        self.rightAxis.drawLabelsEnabled = false
        self.rightAxis.drawAxisLineEnabled = false
        self.delegate = self
    }
    
    func setData(datas:[ChartModel]) {
        var entries = [BarChartDataEntry]()
        
        
        for i in 0..<datas.count {
            entries.append(BarChartDataEntry(x:Double(i),y:datas[i].value,data:datas[i] as AnyObject))
        }
        
        let set = BarChartDataSet(entries: entries, label: "")
        set.colors = ChartColorTemplates.vordiplom()
        + ChartColorTemplates.joyful()
        + ChartColorTemplates.colorful()
        + ChartColorTemplates.liberty()
        + ChartColorTemplates.pastel()
        
        let chartData = BarChartData(dataSet: set)
        self.data = chartData
        
        self.xAxis.valueFormatter = IndexAxisValueFormatter(values: datas.map({ $0.name }))
        self.xAxis.labelCount = datas.count
        self.xAxis.granularityEnabled = true
        self.xAxis.granularity = 1
        self.animate(xAxisDuration: 2.0, yAxisDuration: 2.0,easingOption: .easeInExpo)

    }
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        print(entry)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


// 圓餅圖
class MyPieChartView:PieChartView , ChartViewDelegate {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        legend.form = .line // 底下說明圖示
        self.delegate = self
    }
    
    func setData(datas:[ChartModel]) {
        var entries = [PieChartDataEntry]()
        
        let myNewData = updateDatas(oldDatas: datas)
        for i in 0..<myNewData.count {
            entries.append(PieChartDataEntry(value: myNewData[i].value, label: myNewData[i].name, icon: nil))
        }
        
        let set = PieChartDataSet(entries: entries, label: "")
        // 設定區塊顏色
        set.colors = ChartColorTemplates.vordiplom()
        + ChartColorTemplates.joyful()
        + ChartColorTemplates.colorful()
        + ChartColorTemplates.liberty()
        + ChartColorTemplates.pastel()
        /*for _ in 0..<(datas.count) {
            set.colors.append(
                UIColor(
                    red: .random(in: 0...1),
                    green: .random(in: 0...1),
                    blue: .random(in: 0...1),
                    alpha: 1.0
                )
            )
        }*/
        
        set.valueFont = .systemFont(ofSize: 10)
        // 點選後突出位置
        set.selectionShift = 10
        // 圓餅分隔
        set.sliceSpace = 3
        // 不顯示數值
        // set.drawValuesEnabled = false
        
        let chartData = PieChartData(dataSet: set)
        let numFormatter = NumberFormatter()
        numFormatter.numberStyle = .percent // 依照比例
        numFormatter.maximumFractionDigits = 1 // 小數點
        numFormatter.multiplier = 1.0
        let formatter = DefaultValueFormatter(formatter: numFormatter)
        
        self.data = chartData
        self.data?.setValueFormatter(formatter) // 不能再charData 設定 , 只能在data上設定..
        self.usePercentValuesEnabled = true
        self.animate(xAxisDuration: 2.0, yAxisDuration: 2.0,easingOption: .easeInExpo)

    }
    
    private func updateDatas(oldDatas:[ChartModel])->[ChartModel] { // 排序 由小到大 , 至多 6個 entry , 多餘的放入其他 (避免資料太多導致擠在一起)
        var others = ChartModel(name: "其他", value: 0)
        var newDatas = oldDatas.sorted(by: {$0.value < $1.value})
        while ( newDatas.count > 5 ) {
            others.value += newDatas[0].value
            newDatas.removeFirst()
        }
        
        newDatas.append(others)
        return newDatas
    }
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        print(entry)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
