//
//  PlaceDetail.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/9.
//

import Foundation
import Combine
import UIKit
class PlaceDetail:UIViewController {
    final let bigImgSize = CGSize(width: 500 * Theme.factor, height: 500 * Theme.factor)
    var place:FavoritePlace?
    let bigImageView = MyImageView(imageMode:.fillAndWhiteBG)
    let nameLabel = UILabel.createLabel(size: 20, color: .black)
    let createDateLabel = UILabel.createLabel(size: 20, color: .black)
    let addressLabel = UILabel.createLabel(size: 20, color: .black)
    let coordinateLabel = UILabel.createLabel(size: 20, color: .black)
    
    var cancelList = [AnyCancellable]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.contents = Theme.backGroundImage
        setUp()
        layout()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelList.removeAll()
    }
    
    func setUp() {
        setUpNav(title: "地點資訊")
        addBigViewAction(imgView: self.bigImageView)
        
        place.publisher.sink(receiveValue:{ [weak self] myPlace in
            guard let self = self else { return }
            self.nameLabel.text = myPlace.name
            self.createDateLabel.text = String(myPlace.date.prefix(10))
            self.addressLabel.text = myPlace.address
            self.coordinateLabel.text = "(經度:\(String(format: "%.2f", myPlace.latitude)),緯度:\(String(format: "%.2f", myPlace.longitude)))"
            
            if let img = imgDict.getImg(url: myPlace.picURL) {
                self.bigImageView.image = img
            }
        }).store(in: &cancelList)
    }
    
    func layout() {
        let stackView = UIStackView(arrangedSubviews: [createDateLabel,nameLabel,addressLabel,coordinateLabel])
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.spacing = 30 * Theme.factor
        
        let margins = view.layoutMarginsGuide
        view.addSubviews(bigImageView,stackView)
        NSLayoutConstraint.useAndActivateConstraints(constraints: [
            bigImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor) ,
            bigImageView.widthAnchor.constraint(equalToConstant: bigImgSize.width),
            bigImageView.heightAnchor.constraint(equalToConstant: bigImgSize.height),
            bigImageView.topAnchor.constraint(equalTo: margins.topAnchor,constant: 70),
        
            stackView.topAnchor.constraint(equalTo: bigImageView.bottomAnchor,constant:10) ,
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor) ,
            stackView.widthAnchor.constraint(equalTo:view.widthAnchor,multiplier: 0.7),
            //stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor,constant: -30)
        ])
    }
}


extension PlaceDetail {
    func addBigViewAction(imgView:UIImageView) {
        let tapG = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        imgView.isUserInteractionEnabled = true
        imgView.addGestureRecognizer(tapG)
    }
    
    @objc func imageTapped() {
        if let url = place?.picURL ,
           let img = imgDict.getImg(url: url) {
            let vc = ImagePreviewVC(image: img)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

