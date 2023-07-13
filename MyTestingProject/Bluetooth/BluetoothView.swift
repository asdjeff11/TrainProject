//
//  BluetoothView.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/10.
//

import Foundation
import UIKit
import CoreBluetooth
import Combine
class BluetoothView:UIViewController {
    let viewModel = BluetoothViewModel()
    var cancelList = [AnyCancellable]()
    var isLoading = false
    var selectIndex = 0
    lazy var collectionView:UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 250 * Theme.factor,
                                 height: 300 * Theme.factor) // 上面50 給 title 使用
        
        layout.sectionInset = UIEdgeInsets(top: 10 * Theme.factor, left: 10 * Theme.factor,
                                           bottom: 10 * Theme.factor, right: 10 * Theme.factor)
        
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.bounces = false
        collectionView.register(BluetoothCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.backgroundColor = nil
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()
    
    override func home() {
        viewModel.bluetooth.closeBlueTooth()
        super.home()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.contents = Theme.backGroundImage
        setUpNav(title: "藍牙測試")
        layout()
        viewModel.updateData(completion: { [weak self] in
            self?.collectionView.reloadData()
        })
        
        viewModel.bluetooth.$connectPeripherals.sink (receiveValue: { [weak self] _ in
            self?.collectionView.reloadData()
        }).store(in: &cancelList)
    }
    
    override func viewWillTerminate() {
        super.viewWillTerminate()
        cancelList.removeAll()
    }
}

extension BluetoothView {
    private func layout() {
        let btn = MyButton(style: ButtonStyle(color: .yellow,text:"新增裝置",fontSize: 16))
        btn.publisher()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] _ in
                guard let self = self , self.isLoading == false else { return }
                let vc = BlueAddDevice()
                vc.ble = self.viewModel.bluetooth
                self.addViewToPresent(viewController: vc)
               
            })
            .store(in: &cancelList)
        view.addSubviews(collectionView,btn)
        
        let margins = view.layoutMarginsGuide
        NSLayoutConstraint.useAndActivateConstraints(constraints: [
            collectionView.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 10 * Theme.factor),
            collectionView.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: -10 * Theme.factor),
            collectionView.topAnchor.constraint(equalTo: margins.topAnchor,constant: 30 * Theme.factor),
            collectionView.bottomAnchor.constraint(equalTo: btn.topAnchor, constant: -30 * Theme.factor),
            
            btn.bottomAnchor.constraint(equalTo: margins.bottomAnchor,constant: -30 * Theme.factor),
            btn.centerXAnchor.constraint(equalTo: margins.centerXAnchor),
            btn.widthAnchor.constraint(equalToConstant: 200 * Theme.factor),
            btn.heightAnchor.constraint(equalToConstant: 70 * Theme.factor)
        ])
    }
}

extension BluetoothView:UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.bluetooth.connectPeripherals.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? BluetoothCell
        else { return UICollectionViewCell() }
        
        let peripheral = viewModel.bluetooth.connectPeripherals[indexPath.row]
        cell.setTitle(text: peripheral.name ?? "裝置")
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let peripheral = viewModel.bluetooth.connectPeripherals[indexPath.row]
        guard let services = peripheral.services else { return }
        print("service:\(services.count)")
        
        var charCount = 0
        for i in 0..<(services.count) {
            charCount += services[i].characteristics?.count ?? 0
        }
        print("char:\(charCount)")
        
        selectIndex = indexPath.row
        
        let vc = BluetoothChooseService()
        vc.services = services
        vc.selectCallBack = selectServiceCallBack
        addViewToPresent(viewController: vc)
    }
    
    func selectServiceCallBack(charID:CBUUID) {
        switch ( viewModel.bluetooth.selectChar(charID: charID) ) { // 檢查該 char 並指定傳送給他
        case .可以使用 :
            let vc = BluetoothTranslateData()
            vc.ble = viewModel.bluetooth
            navigationController?.pushViewController(vc, animated: true)
        case .此服務不提供傳接資訊 :
            showAlert(alertText: "提醒", alertMessage: "此裝置不提供傳接資訊")
        case .找不到服務 :
            showAlert(alertText: "資料錯誤", alertMessage: "找不到該Characteristic")
        }
    }
}
