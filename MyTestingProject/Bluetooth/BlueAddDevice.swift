//
//  BlueAddDevice.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/10.
//

import Foundation
import UIKit
import Combine
import CoreBluetooth
class BlueAddDevice:UIViewController {
    var ble:BlueTooth!
    var peripherals:[CBPeripheral] = []
    var cancelList = [AnyCancellable]()
    private var contentView: UIView = {
        let contentView = UIView(frame: CGRect(x: 0, y: 0, width: 620 * Theme.factor , height: 840 * Theme.factor))
        contentView.center = CGPoint(x: Theme.fullSize.width * 0.5, y: Theme.fullSize.height * 0.5)
        contentView.backgroundColor = UIColor.white
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 8
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.black.cgColor
        return contentView
    }()
    
    var tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ble.$peripherals.sink(receiveValue: { [weak self] (peripherals:[CBPeripheral]) in
            guard let self = self else { return }
            self.peripherals = peripherals
            self.tableView.reloadData()
        }).store(in: &cancelList)
        
        tableView.backgroundColor = .white
        tableView.showsVerticalScrollIndicator = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        
        self.view.backgroundColor = UIColor(white: 0, alpha: 0.5)
        self.view.addSubview(contentView)
        layout()
        ble.startScan()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelList.removeAll()
        ble.stopScan()
    }
    
    func layout() {
        let titleLabel = UILabel.createLabel(size: 26, color: .black,text:"選擇裝置")
        
        let cancelBtn = UIButton()
        cancelBtn.backgroundColor = .clear
        cancelBtn.setImage(UIImage(named:"button_close"), for: .normal)
        
        cancelBtn.publisher().sink(receiveValue: { [weak self] _ in
            self?.dismiss(animated: true)
        })
        .store(in: &cancelList)
        
        let lineView = UIView()
        lineView.backgroundColor = .black
        contentView.addSubviews(titleLabel,cancelBtn,lineView,tableView)
        NSLayoutConstraint.useAndActivateConstraints(constraints: [
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor,constant: 30 * Theme.factor),
            titleLabel.heightAnchor.constraint(equalToConstant: 50 * Theme.factor),
        
            cancelBtn.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,constant: -30 * Theme.factor),
            cancelBtn.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            cancelBtn.widthAnchor.constraint(equalToConstant: 50 * Theme.factor),
            cancelBtn.heightAnchor.constraint(equalToConstant: 50 * Theme.factor),
            
            lineView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor,constant: 30 * Theme.factor),
            lineView.heightAnchor.constraint(equalToConstant: 1) ,
            lineView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            lineView.widthAnchor.constraint(equalTo: contentView.widthAnchor,multiplier: 0.8),
            
            tableView.topAnchor.constraint(equalTo: lineView.bottomAnchor,constant: 30 * Theme.factor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,constant: -30 * Theme.factor),
            tableView.leadingAnchor.constraint(equalTo: lineView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: lineView.trailingAnchor)
        ])
    }
}


extension BlueAddDevice:UITableViewDataSource,UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "Cell")
        cell.textLabel?.text = peripherals[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        ble.selectPeripheral(index: indexPath.row)
        self.dismiss(animated: true)
    }
}
