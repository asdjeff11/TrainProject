//
//  WebViewTest.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/9.
//

import Foundation
import UIKit
import WebKit
import Combine
class WebViewTest:UIViewController {
    final let urls:[(String,String)] = [("台灣銀行","https://www.bot.com.tw/Pages/default.aspx"),
                                        ("CNN","https://edition.cnn.com/"),
                                        ("中央氣象局","https://www.cwb.gov.tw/V8/C/"),
                                        ("ezTravel","https://www.eztravel.com.tw/")]
    var cancelList = [AnyCancellable]()
    var mWebView = WKWebView()
    var backBtn = UIButton()
    var fowardBtn = UIButton()
    var textField = TextField()
    var pickerView = UIPickerView()
    var recordRow = 0
    var isLoading = false
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.contents = Theme.backGroundImage
        setUp()
        layout()
        
        if let url = URL(string: urls[recordRow].1) {
            let urlRequest = URLRequest(url: url)
            
            loading(isLoading: &isLoading)
            mWebView.load(urlRequest)
        }
    }
    
    override func viewWillTerminate() {
        super.viewWillTerminate()
        cancelList.removeAll()
    }
}

extension WebViewTest {
    func setUp() {
        setUpNav(title: "網頁")
        
        mWebView.navigationDelegate = self // 委任函數
        
        backBtn.isEnabled = false
        backBtn.setTitle("上一頁", for: .normal)
        backBtn.setTitleColor(.white, for: .normal)
        backBtn.backgroundColor = Theme.navigationBarBG
        backBtn.layer.cornerRadius = 10
        
        backBtn.publisher()
            .receive(on: RunLoop.main)
            .sink(receiveValue:{ [weak self] _ in
                self?.mWebView.goBack()
            })
            .store(in: &cancelList)
        
        fowardBtn.isEnabled = false
        fowardBtn.setTitle("下一頁", for: .normal)
        fowardBtn.setTitleColor(.white, for: .normal)
        fowardBtn.backgroundColor = Theme.navigationBarBG
        fowardBtn.layer.cornerRadius = 10
        fowardBtn.publisher()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] _ in
                self?.mWebView.goForward()
            })
            .store(in: &cancelList)
        
        pickerView.delegate = self
        textField.layer.borderColor = UIColor.black.cgColor
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 10
        textField.inputView = pickerView
        textField.placeholder = "請輸入搜尋地點"
    }
    
    func layout() {
        let margins = view.layoutMarginsGuide
        view.addSubviews(backBtn ,fowardBtn , textField, mWebView)
        NSLayoutConstraint.useAndActivateConstraints(constraints: [
            backBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor,constant: 30 * Theme.factor),
            backBtn.widthAnchor.constraint(equalToConstant: 150 * Theme.factor),
            backBtn.topAnchor.constraint(equalTo: margins.topAnchor,constant: 10 * Theme.factor),
            backBtn.heightAnchor.constraint(equalToConstant: 30),
        
            fowardBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor,constant: -30 * Theme.factor),
            fowardBtn.widthAnchor.constraint(equalTo: backBtn.widthAnchor),
            fowardBtn.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            fowardBtn.heightAnchor.constraint(equalTo: backBtn.heightAnchor),
            
            textField.leadingAnchor.constraint(equalTo: backBtn.trailingAnchor,constant: 20 * Theme.factor),
            textField.trailingAnchor.constraint(equalTo: fowardBtn.leadingAnchor,constant: -20 * Theme.factor),
            textField.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            textField.heightAnchor.constraint(equalTo:backBtn.heightAnchor),
            
            mWebView.topAnchor.constraint(equalTo: backBtn.bottomAnchor,constant: 10 * Theme.factor),
            mWebView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mWebView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        
        ])
    }
}

extension WebViewTest:UIPickerViewDelegate, UIPickerViewDataSource {
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return urls.count
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return urls[row].0
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if ( row == recordRow ) { return }
        
        self.textField.text = urls[row].0
        if let url = URL(string: urls[row].1) {
            let urlRequest = URLRequest(url: url)
            mWebView.load(urlRequest)
        }
        recordRow = row
        self.view.endEditing(true)
    }
}

extension WebViewTest:WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print(error.localizedDescription)
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("start load")
        loading(isLoading: &isLoading)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("load finish")
        removeLoading(isLoading: &isLoading)
        fowardBtn.isEnabled = webView.canGoForward
        backBtn.isEnabled = webView.canGoBack
    }
    
    /*func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping(WKNavigationActionPolicy)->Void) {
        // 針對 html5 target = "_blank" 開啟新分頁方式處理
        if ( navigationAction.targetFrame == nil ) {
            decisionHandler(.cancel) // 取消預設行為
            webView.load(navigationAction.request) // 載入收到的新urlRequest
            return
        }
        
        decisionHandler(.allow) //預設行為
    }*/
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // 針對 js window.open 開啟新分頁方式處理
        if ( navigationAction.targetFrame == nil || navigationAction.targetFrame?.isMainFrame == nil ) {
            webView.load(navigationAction.request) // 原先的載入
        }
        return nil // 不開新的webView
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        if navigationAction.shouldPerformDownload {
            decisionHandler(.download, preferences)
        }
        else if ( navigationAction.targetFrame == nil || navigationAction.targetFrame?.isMainFrame == nil) {
            decisionHandler(.cancel, preferences)
            webView.load(navigationAction.request)
        }
        else {
            decisionHandler(.allow, preferences)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if navigationResponse.canShowMIMEType {
            decisionHandler(.allow)
        } else {
            decisionHandler(.download)
        }
    }
}
