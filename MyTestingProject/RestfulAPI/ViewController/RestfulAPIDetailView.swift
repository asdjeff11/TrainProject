//
//  RestfulAPIDetailView.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/12.
//
import UIKit
class RestfulAPIDetailView:UIViewController {
    final let imageSize = CGSize(width: 400 * Theme.factor, height: 400 * Theme.factor)
    var titleLabel = UILabel.createLabel(size: 20, color: .black)
    var descriptionLabel = UILabel.createLabel(size: 12, color: .white)
    var dateLabel = UILabel.createLabel(size: 16, color: .yellow)
    var imageView = UIImageView()
    
    var detail:RestfulModel?
    
    override func viewDidLoad() {
        setUp()
        layout()
        fetchImage()
    }
    
}

extension RestfulAPIDetailView {
    func fetchImage() {
        guard let detail = detail else { return }
        guard let url = URL(string:detail.starsData.hdurl) else { showAlert(alertText: "資料錯誤", alertMessage: "url 解析失敗") ; return   }
       
           
        URLSession.shared.dataTask(with: url, completionHandler: { data, response , error in
            do {
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw CustomError.invalidResponse }
                guard let data = data , let image = UIImage(data:data ) else { throw CustomError.invalidData }
                
                DispatchQueue.main.async { // 更新大圖
                    self.imageView.image = UIImage.scaleImage(image: image, newSize: self.imageSize)
                    self.imageView.alpha = 0
                    UIView.animate(withDuration: 0.8, delay: 0, animations: {
                        self.imageView.alpha = 1
                    })
                }
            }
            catch (CustomError.invalidResponse ) {
                self.showAlert(alertText: "資料錯誤", alertMessage: "url response 錯誤")
            }
            catch (CustomError.invalidData) {
                self.showAlert(alertText: "資料錯誤", alertMessage: "物件解析錯誤")
            }
            catch (CustomError.requestFailed(let e) ) {
                self.showAlert(alertText: "資料錯誤", alertMessage: "url request 失敗(\(e))")
            }
            catch {
                self.showAlert(alertText: "資料錯誤", alertMessage: "未知錯誤")
            }
        }).resume()
    }
}

extension RestfulAPIDetailView {
    func setUp() {
        view.layer.contents = UIImage(named:"background")?.cgImage
        setUpNav(title: "細目",backButtonVisit: true)
        titleLabel.font = UIFont(name: "titleFont", size: 20)
        titleLabel.text = detail?.starsData.title ?? "Title"
        titleLabel.textAlignment = .center
        titleLabel.lineBreakMode = NSLineBreakMode.byTruncatingMiddle
        titleLabel.adjustsFontSizeToFitWidth = true
        descriptionLabel.text = detail?.starsData.description ?? "description"
        descriptionLabel.lineBreakMode = .byCharWrapping
        descriptionLabel.numberOfLines = 0
        dateLabel.text = detail?.starsData.date ?? "19XX-01-01"
        if let image = detail?.photo.image { // 有小圖 先放小圖 背景改大圖
            imageView.image = UIImage.scaleImage(image: image, newSize: imageSize)
        }
        addBigViewAction(imgView: self.imageView)
    }
    
    
    
    func layout() {
        let margins = view.layoutMarginsGuide
        
        let scrollView = UIScrollView()
        scrollView.addSubview(descriptionLabel)
        scrollView.showsVerticalScrollIndicator = false
        
        view.addSubviews(titleLabel,imageView,dateLabel,scrollView)
        NSLayoutConstraint.useAndActivateConstraints(constraints: [
            titleLabel.topAnchor.constraint(equalTo: margins.topAnchor,constant: 50 * Theme.factor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.widthAnchor.constraint(equalToConstant: 600 * Theme.factor),
            titleLabel.heightAnchor.constraint(equalToConstant: 40 * Theme.factor),
            
            imageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor,constant: 30 * Theme.factor),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 400 * Theme.factor),
            imageView.heightAnchor.constraint(equalToConstant: 400 * Theme.factor),
            
            dateLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor,constant: 30 * Theme.factor),
            dateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor,constant: 60 * Theme.factor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor,constant: -60 * Theme.factor),
            scrollView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor,constant: 30 * Theme.factor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor,constant: -30 * Theme.factor)
        ])
        
        NSLayoutConstraint.useAndActivateConstraints(constraints: [
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor,constant: 60 * Theme.factor),
            descriptionLabel.topAnchor.constraint(equalTo: scrollView.topAnchor),
            descriptionLabel.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor,constant: -60 * Theme.factor),
        
        ])
    }
}

extension RestfulAPIDetailView {
    func addBigViewAction(imgView:UIImageView) {
        let tapG = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        imgView.isUserInteractionEnabled = true
        imgView.addGestureRecognizer(tapG)
    }
    
    @objc func imageTapped() {
        let vc = ImagePreviewVC(image_urls: [detail!.starsData.url] )
        navigationController?.pushViewController(vc, animated: true)
    }
}
