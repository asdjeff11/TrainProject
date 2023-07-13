//
//  WebViewTestCommunity.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/9.
//

import Foundation
import UIKit
import WebKit
import Combine
class WebViewTestConmmunicate:UIViewController {
    final let urls:[(String,String)] = [("台灣銀行","https://www.bot.com.tw/Pages/default.aspx"),
                                        ("CNN","https://edition.cnn.com/"),
                                        ("中央氣象局","https://www.cwb.gov.tw/V8/C/"),
                                        ("ezTravel","https://www.eztravel.com.tw/")]
    var cancelList = [AnyCancellable]()
    lazy var mWebView:WKWebView = {
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = WKUserContentController()
        configuration.userContentController.add(self,name:"ToApp") // 新增由 html傳過來的值 接收函數 , 在js 中 呼叫 window.webkit.messageHandlers."名稱".postMessage()  即可將資訊傳到底下函數接收
        let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.navigationDelegate = self // 委任函數
        return webView
    }()
    var backBtn = UIButton()
    var sendBtn = UIButton()
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
        
        // load html檔案
        let HTML = try! String(contentsOfFile: Bundle.main.path(forResource: "demo", ofType: "html")!, encoding: String.Encoding.utf8)
        mWebView.loadHTMLString(HTML, baseURL: nil)
    }
    
    override func viewWillTerminate() {
        super.viewWillTerminate()
        cancelList.removeAll()
    }
    
    func sendMsgToJS(mes:String) {
        mWebView.evaluateJavaScript("sendMessage('\(mes)')") { (result, err) in
            // js 的 return 會放到 result 中
            if let error = err {
                print(error.localizedDescription)
            }
            else if let result = result {
                print(result)
            }
        }
    }
}

extension WebViewTestConmmunicate {
    func setUp() {
        setUpNav(title: "網頁")
        
        createBtn(button: backBtn, text: "上一頁")
        createBtn(button: sendBtn, text: "送出訊息")
        createBtn(button: fowardBtn, text: "下一頁")
        
        
        backBtn.publisher()
            .receive(on: RunLoop.main)
            .sink(receiveValue:{ [weak self] _ in
                self?.mWebView.goBack()
            })
            .store(in: &cancelList)
        
        sendBtn.publisher().receive(on: RunLoop.main)
            .sink(receiveValue: {[weak self] _ in
                self?.sendMsgToJS(mes: "hello js")
            })
            .store(in: &cancelList)
        
        fowardBtn.publisher()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] _ in
                self?.mWebView.goForward()
            })
            .store(in: &cancelList)
    }
    
    private func createBtn(button:UIButton , text:String) {
        button.setTitle(text, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = Theme.navigationBarBG
        button.layer.cornerRadius = 10
    }
    
    func layout() {
        let margins = view.layoutMarginsGuide
        view.addSubviews(backBtn ,fowardBtn, sendBtn, mWebView)
        NSLayoutConstraint.useAndActivateConstraints(constraints: [
            backBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor,constant: 30 * Theme.factor),
            backBtn.widthAnchor.constraint(equalToConstant: 150 * Theme.factor),
            backBtn.topAnchor.constraint(equalTo: margins.topAnchor,constant: 10 * Theme.factor),
            backBtn.heightAnchor.constraint(equalToConstant: 30),
        
            fowardBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor,constant: -30 * Theme.factor),
            fowardBtn.widthAnchor.constraint(equalTo: backBtn.widthAnchor),
            fowardBtn.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            fowardBtn.heightAnchor.constraint(equalTo: backBtn.heightAnchor),
            
            sendBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sendBtn.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            sendBtn.widthAnchor.constraint(equalTo: backBtn.widthAnchor),
            sendBtn.heightAnchor.constraint(equalTo: backBtn.heightAnchor),
            
            mWebView.topAnchor.constraint(equalTo: backBtn.bottomAnchor,constant: 10 * Theme.factor),
            mWebView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mWebView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        self.view.sendSubviewToBack(mWebView)
    }
}

extension WebViewTestConmmunicate:WKNavigationDelegate {
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
}

extension WebViewTestConmmunicate: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print(message.body)
    }
}

