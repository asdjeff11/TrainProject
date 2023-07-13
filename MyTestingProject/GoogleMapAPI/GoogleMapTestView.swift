//
//  GoogleMapTestView.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/8.
//

import Foundation
import UIKit
import Combine
import GoogleMaps
class GoogleMapTestView:UIViewController {
    let favoriteButton = UIButton()
    let tableView = UITableView()
    let viewModel = GoogleMapTestViewModel()
    var cancelList = [AnyCancellable]()
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.updateData { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelList.removeAll()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.contents = Theme.backGroundImage
        setUp()
        layout()
        setUpUICompenent()
    }
    
    private func setUp() {
        setUpNav(title: "我的最愛地點")
        
        favoriteButton.layer.shadowColor = UIColor(hex: 0xFFCC00,alpha: 0.25).cgColor
        favoriteButton.layer.shadowOffset = CGSize(width: 0, height: 5)
        favoriteButton.layer.shadowOpacity = 1.0
        favoriteButton.layer.shadowRadius = 10.0
        favoriteButton.layer.masksToBounds = false
        favoriteButton.setTitle("新增地點", for: .normal)
        let icon = UIImage.scaleImage(image: UIImage(named: "heart")!, newSize: CGSize(width: 30, height: 30))
        favoriteButton.setImage(icon, for: .normal)
        favoriteButton.backgroundColor = .white //UIColor(hex: 0xFFCC00)
        favoriteButton.setTitleColor(UIColor(hex: 0xFFCC00), for: .normal)
        favoriteButton.titleLabel?.font = .systemFont(ofSize: 16)
        favoriteButton.layer.cornerRadius = 10
        
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.register(GoogleMapTestCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func layout() {
        let margins = view.layoutMarginsGuide
        view.addSubviews(favoriteButton,tableView)
        NSLayoutConstraint.useAndActivateConstraints(constraints: [
            favoriteButton.leadingAnchor.constraint(equalTo: view.leadingAnchor,constant: 30),
            favoriteButton.topAnchor.constraint(equalTo: margins.topAnchor,constant: 10),
            favoriteButton.heightAnchor.constraint(equalToConstant: 40),
            favoriteButton.widthAnchor.constraint(equalToConstant: 100),
            
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: favoriteButton.bottomAnchor,constant: 20),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setUpUICompenent() {
        favoriteButton.publisher()
            .receive(on:RunLoop.main)
            .sink(receiveValue: { _ in
                if ( AppDelegate.googleMapKeyIsVaild ) {
                    let vc = GoogleMapAddView()
                    self.navigationController?.pushViewController(vc, animated: true)
                }
                else {
                    self.showAlert(alertText: "提醒", alertMessage: "您的GoogleMap 金鑰有誤")
                }
            
        }).store(in: &cancelList)
    }
}

extension GoogleMapTestView:UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getLen() * 2
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if ( indexPath.row % 2 != 0 ) {
            return 30
        }
        else {
            return UITableView.automaticDimension //600 * Theme.factor
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
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? GoogleMapTestCell else { return UITableViewCell() }
            cell.selectionStyle = .none
            cell.setPic(image: nil) // 清除原先的
            if let place = viewModel.getItem(index: index) {
                cell.setData(place: place)
                if let image = viewModel.getItemImage(ID: place.ID) {
                    cell.setPic(image: image)
                }
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = indexPath.row / 2
        guard let item = viewModel.getItem(index: index) else { return }
        let vc = PlaceDetail()
        vc.place = item
        navigationController?.pushViewController(vc, animated: true)
    }
}
