//
//  KLineView.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/15.
//
//  設定KLine圖
import Foundation
import Charts

class KLineView:CombinedChartView {
    private var maUtiltiy = MovingAverageUtility()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        //dragEnabled = false // 拖移
        setScaleEnabled(true) // 縮放
        maxVisibleCount = 1000 // 最大可見數量
        pinchZoomEnabled = true // x軸 與 y軸 是否可以同時縮放
        
        // 設定 legend
        legend.enabled = false
        /*legend.horizontalAlignment = .right
        legend.verticalAlignment = .top
        legend.orientation = .vertical
        legend.drawInside = false
        legend.xEntrySpace = 10
        legend.font = .systemFont(ofSize: 10)*/
        
        // 設定左軸
        leftAxis.labelFont = .systemFont(ofSize: 10)
        leftAxis.spaceTop = 0.3
        leftAxis.spaceBottom = 0.3
        
        rightAxis.enabled = false // 右軸不顯示
        
        // 設定下軸
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .systemFont(ofSize: 10)
        xAxis.labelCount = 10
    }
    
    func setData(stockKLines:[StockKLine],marketTradingInfos:[MarketTradingInfo]) {
        let ma5DataSet = getMALineData(stockSticks: stockKLines, range: 5, color: .blue)
        let ma10DataSet = getMALineData(stockSticks: stockKLines, range: 10, color: .red)
        let ma20DataSet = getMALineData(stockSticks: stockKLines, range: 20, color: .orange)
        let lineData = LineChartData(dataSets: [ma5DataSet,ma10DataSet,ma20DataSet])
        
        let candleData = getCandleData(stockSticks: stockKLines)
        
        let barData = getVolumnBarData(volumnDataList: marketTradingInfos)
        
        if let barDataSet = barData.dataSets.first as? BarChartDataSet { // 更新高度
           updateVolumeMaxMin(dataSet: barDataSet)
        }
        
        let combinedData = CombinedChartData()
        combinedData.lineData = lineData
        combinedData.candleData = candleData
        combinedData.barData = barData
        
        data = combinedData
        
        
     
        //xAxis.setLabelCount(stockKLines.count, force: false)
    }
    
    
    
    private func setXAxisLabel(indexDict:[Int:String]) { // 更新X軸底下文字
        self.xAxis.valueFormatter = CandleXAxisValueFormatter(indexLabelMap: indexDict)
        self.xAxis.granularity = 1
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class CandleXAxisValueFormatter: AxisValueFormatter {
        private let indexLabelMap: [Int: String]
        
        /// 因為 candle charts 是用 index 來當 x 軸，但是 index 需要 mapping 成 date string，才可以讓人類識別每個 candle stick 代表的意義
        /// - Parameter indexLabelMap: index vs. date string
        init(indexLabelMap: [Int: String]) {
            self.indexLabelMap = indexLabelMap
        }
        
        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            
            guard let string = indexLabelMap[Int(value)] else {
                return ""
            }
            return string
        }
    }
}

// candleChart
extension KLineView {
    private func getCandleData(stockSticks: [StockKLine]) -> CandleChartData {
        let candleDataEntry = convert(stockKLines: stockSticks)
        let candleDataSet = convert(dataEntry: candleDataEntry)
        let candleData = CandleChartData(dataSet: candleDataSet)
        updateMaxMin(dataSet: candleDataSet)
        return candleData
    }
    
    private func convert(stockKLines:[StockKLine])->[CandleChartDataEntry] {
        var dataEntry = [CandleChartDataEntry]()
        var indexDateLabels:[Int:String] = [:]
        for (i,stockKLine) in stockKLines.enumerated() {
          
            dataEntry.append(CandleChartDataEntry(x: Double(i), shadowH: stockKLine.highest, shadowL: stockKLine.lowest, open: stockKLine.open, close: stockKLine.close))
            indexDateLabels[i] = String(stockKLine.dateString.suffix(5))
            
        }
        
        setXAxisLabel(indexDict: indexDateLabels)
        return dataEntry
    }
    
    private func updateMaxMin(dataSet: CandleChartDataSet) { // 設定Y軸 最大最小值
        let max = dataSet.yMax
        let min = dataSet.yMin
        leftAxis.axisMaximum = max * 1.05
        leftAxis.axisMinimum = min * 0.95
    }
    
    private func convert(dataEntry: [CandleChartDataEntry])-> CandleChartDataSet {
        let dataSet = CandleChartDataSet(entries: dataEntry,label: "K棒")
        
        dataSet.axisDependency = .left
        dataSet.setColor(.red)
        dataSet.drawIconsEnabled = false
        dataSet.shadowColor = .darkGray
        dataSet.shadowWidth = 0.5
        // 下跌為綠色
        dataSet.decreasingColor = .systemGreen
        dataSet.decreasingFilled = true
        // 上漲為紅色
        dataSet.increasingColor = .systemRed
        dataSet.increasingFilled = true
        // 開盤 == 收盤
        dataSet.neutralColor = .black
        
        dataSet.drawValuesEnabled = false // 不要顯示數值
        return dataSet
    }
}

// MA部分 折線圖
extension KLineView {
    private func getMALineData(stockSticks: [StockKLine], range: Int, color: UIColor) -> LineChartDataSet {
        var lineDataEntry = [ChartDataEntry]()
        let maPoints = maUtiltiy.getMAPoints(from: stockSticks, range: range)
        
        for point in maPoints {
            let dataEntry = ChartDataEntry(x: point.x, y: point.y)
            lineDataEntry.append(dataEntry)
        }
        
        // maPoints 得到了
        let maDataSet = LineChartDataSet(entries: lineDataEntry, label: "\(range) MA")
        
        maDataSet.setColor(color)
        maDataSet.lineWidth = 1
        maDataSet.drawCirclesEnabled = false
        maDataSet.drawValuesEnabled = false
        maDataSet.axisDependency = .left
        maDataSet.highlightEnabled = true
        
        return maDataSet
    }
}

// 長方圖 成交量
extension KLineView {
    private func getVolumnBarData(volumnDataList:[MarketTradingInfo])->BarChartData {
        // set Entry
        var barDataEntryList = [BarChartDataEntry]()
        for (i,vol_Data) in volumnDataList.enumerated() {
            barDataEntryList.append(BarChartDataEntry(x: Double(i), y: vol_Data.tradeVolume))
        }
        
        let set = BarChartDataSet(entries: barDataEntryList)
        set.drawValuesEnabled = false
        set.axisDependency = .right // 左方的軸已經設定給加權指數了，所以量的圖要設定在右邊的軸
        set.colors = getBarColors(volumeList: volumnDataList)
        return BarChartData(dataSet: set)
    }
    
    private func updateVolumeMaxMin(dataSet: BarChartDataSet) {
        let max = dataSet.yMax
        rightAxis.axisMaximum = max * 10
        rightAxis.axisMinimum = 0
    }
    
    private func getBarColors(volumeList: [MarketTradingInfo]) -> [UIColor] {
        let colors = volumeList.map { info -> UIColor in
            if info.change < 0 {
                return UIColor.systemGreen
            }
            return UIColor.systemRed
        }
        return colors
    }
}
