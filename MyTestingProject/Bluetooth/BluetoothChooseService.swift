//
//  BluetoothChooseService.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/13.
//

import Foundation
import UIKit
import CoreBluetooth
import Combine
import Charts
class BluetoothChooseService:UIViewController {
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
    
    var services:[CBService] = [] {
        didSet {
            sectionList = services.enumerated().map({ (index,service) in
                let view = SectionView()
                view.buttonTag = index
                view.delegate = self
                view.setTitle(title: service.uuid.uuidString)
                return view
            })
            self.tableView.reloadData()
        }
    }
    
    var sectionList = [SectionView]()
    
    var selectCallBack:((CBUUID)->Void)?
    var selectIndex:IndexPath?
    
    var cancelList = [AnyCancellable]()
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelList.removeAll()
        _ = sectionList.map { $0.cancelList.cancel() } 
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(white: 0, alpha: 0.5)
        setUp()
        layout()
    }
    
    func setUp() {
        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    func layout() {
        let titleLabel = UILabel.createLabel(size: 26, color: .black,text:"請選擇服務")
        let btn = UIButton()
        btn.titleLabel?.font = .systemFont(ofSize: 16)
        btn.layer.cornerRadius = 15
        btn.setTitle("確認選擇", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = Theme.navigationBarBG
        btn.publisher()
        .receive(on: RunLoop.main)
        .sink(receiveValue: { [weak self] _ in
            guard let self = self, let indexPath = self.selectIndex else { return }
            self.dismiss(animated: true,completion:{
                self.selectCallBack?(self.services[indexPath.section].characteristics![indexPath.row].uuid)
            })
        })
        .store(in: &cancelList)
        
        let cancelBtn = UIButton()
        cancelBtn.backgroundColor = .clear
        cancelBtn.setImage(UIImage(named:"button_close"), for: .normal)
        cancelBtn.publisher().sink(receiveValue: { [weak self] _ in
            self?.dismiss(animated: true)
        })
        .store(in: &cancelList)
        
        let lineView = UIView()
        lineView.backgroundColor = .black
        
        contentView.addSubviews(titleLabel,cancelBtn,lineView,tableView,btn)
        view.addSubview(contentView)
        
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
            tableView.bottomAnchor.constraint(equalTo: btn.bottomAnchor,constant: -30 * Theme.factor),
            tableView.leadingAnchor.constraint(equalTo: lineView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: lineView.trailingAnchor),
        
            btn.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            btn.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,constant: -30 * Theme.factor),
            btn.heightAnchor.constraint(equalToConstant: 50 * Theme.factor),
            btn.widthAnchor.constraint(equalToConstant: 200 * Theme.factor)
        ])
        
    }
}

extension BluetoothChooseService:UITableViewDelegate,UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return services.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if ( sectionList[section].isExpand ) {
            return services[section].characteristics?.count ?? 0
        }
        else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (  sectionList[indexPath.section].isExpand ) {
            return 50 * Theme.factor
        }
        else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.backgroundColor = UIColor(hex: 0xf6f1c5)
        cell.textLabel?.text = "id:\(services[indexPath.section].characteristics?[indexPath.row].uuid.uuidString ?? "")"
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return ( section < sectionList.count ) ? sectionList[section] : nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectIndex = indexPath
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if ( editingStyle == .delete ) {
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50 * Theme.factor
    }
}

extension BluetoothChooseService:SectionViewDelegate {
    func sectionView(_ section: SectionView, _ didPressTag: Int, _ isExpand: Bool) {
        self.tableView.reloadSections(IndexSet(integer: didPressTag), with: .automatic)
        
    }
}
