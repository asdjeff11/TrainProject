//
//  RestfulAPIViewCell.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2022/9/2.
//
import UIKit
class RestfulAPIViewCell:UICollectionViewCell {
    var imageView = MyImageView(imageMode:.fillAndClip)
    //var loadingView = UIImageView()
    var titleLabel = UILabel.createLabel(size: 16, color: .black)
    private var dateLabel = UILabel.createLabel(size: 12, color: UIColor(hex: 0x800000))
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.cgColor
        
        titleLabel.lineBreakMode = NSLineBreakMode.byTruncatingMiddle
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7
        
        //let margins = contentView.layoutMarginsGuide
        //let gif = UIImage.gifImageWithName("picLoading")
        //loadingView.image = gif
        
        contentView.addSubviews(imageView,titleLabel,dateLabel)
        NSLayoutConstraint.useAndActivateConstraints(constraints: [
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 100 * Theme.factor),
            /*
            loadingView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            loadingView.topAnchor.constraint(equalTo: contentView.topAnchor,constant: 35 * Theme.factor),
            loadingView.heightAnchor.constraint(equalToConstant: 30 * Theme.factor),
            loadingView.widthAnchor.constraint(equalToConstant: 100 * Theme.factor),
            */
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 5),
            titleLabel.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            titleLabel.widthAnchor.constraint(equalToConstant: 160 * Theme.factor),
            titleLabel.heightAnchor.constraint(equalToConstant: 30 * Theme.factor),
            
            //titleLabel.heightAnchor.constraint(equalToConstant: 80 * HEIGHT_CONSTANT),
            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            dateLabel.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            dateLabel.heightAnchor.constraint(equalToConstant: 30 * Theme.factor),
        ])
    }
    
    func setup(detail:RestfulModel) {
        titleLabel.text = detail.starsData.title
        dateLabel.text = detail.starsData.date
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
