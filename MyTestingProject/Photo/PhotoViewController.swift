//
//  PhotoViewController.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/15.
//

import Foundation
import Combine
import UIKit
class PhotoViewController:UIViewController {
    let takePicBtn = UIButton()
    let savePicBtn = UIButton()
    let bigImageView = UIImageView()
    var listImage:[UIImage] = [] 
    
    var cancelList = [AnyCancellable]()
    var selectImage:UIImage? {
        didSet {
            bigImageView.image = selectImage
            savePicBtn.isEnabled = (bigImageView.image != nil)
        }
    }
    var isLoading = false
    var taskID:UIBackgroundTaskIdentifier?
    lazy var collectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.itemSize = CGSize(width: 120 * Theme.factor, height: 120 * Theme.factor)
        flowLayout.minimumInteritemSpacing = 20 * Theme.factor
        flowLayout.minimumLineSpacing = 20 * Theme.factor
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)

        let collection = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)

        collection.register(PhotoCell.self, forCellWithReuseIdentifier: "cell")
        collection.backgroundColor = UIColor(hex: 0xf6f1c5)
        collection.layer.cornerRadius = 5
        
        collection.bounces = false
        collection.showsHorizontalScrollIndicator = false
        collection.delegate = self
        collection.dataSource = self
        return collection
    } ()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        layout()
    }
    
    override func viewWillTerminate() {
        super.viewWillTerminate()
        self.cancelList.removeAll()
    }
    
    func setUp() {
        view.layer.contents = Theme.backGroundImage
        setUpNav(title: "拍照")
        
        setBtn(takePicBtn, title: "拍照")
        setBtn(savePicBtn, title: "儲存")
        
        takePicBtn.publisher(for: .touchUpInside)
            .receive(on: RunLoop.main)
            .sink(receiveValue:{ [weak self] _ in
                let vc = TakePictureView()
                vc.photoDoneCallBack = self?.photoCallBack
                self?.navigationController?.pushViewController(vc, animated: true)
            }).store(in: &cancelList)
        
        savePicBtn.isEnabled = false
        savePicBtn.publisher().sink(receiveValue:{ _ in
            guard let selectImage = self.selectImage else { return }
            self.loading(isLoading: &self.isLoading)
            self.taskID = self.beginBackgroundUpdateTask()
            UIImageWriteToSavedPhotosAlbum(selectImage, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
        }).store(in: &cancelList)
        
        
        bigImageView.layer.borderColor = UIColor.black.cgColor
        bigImageView.layer.borderWidth = 1
    }
    
    func photoCallBack(img:UIImage) {
        self.listImage.append(img)
        if ( selectImage == nil ) { selectImage = img }
        self.collectionView.reloadData()
    }
    
    func setBtn(_ btn:UIButton , title:String) {
        btn.setTitle(title, for: .normal)
        btn.layer.cornerRadius = 15
        btn.backgroundColor = Theme.navigationBarBG
        btn.setTitleColor( .white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16)
    }
    
    func layout() {
        let stackView = UIStackView(arrangedSubviews: [takePicBtn,savePicBtn])
        stackView.axis = .horizontal
        stackView.spacing = 70 * Theme.factor
        stackView.distribution = .fillEqually
        
        view.addSubviews(bigImageView,collectionView,stackView)
        
        let margins = view.layoutMarginsGuide
        bigImageView.centerXToSuperview()
        bigImageView.top(to: margins,offset: 80 * Theme.factor)
        bigImageView.size(CGSize(width: 500 * Theme.factor, height: 500 * Theme.factor))
        
        collectionView.topToBottom(of: bigImageView,offset: 20 * Theme.factor)
        collectionView.centerXToSuperview()
        collectionView.size(CGSize(width: 500 * Theme.factor, height: 150 * Theme.factor))
        
        stackView.centerXToSuperview()
        stackView.bottomToSuperview(offset: -80 * Theme.factor)
        stackView.size(CGSize(width: 500 * Theme.factor, height: 80 * Theme.factor))
    }
}

extension PhotoViewController: UIImagePickerControllerDelegate{
    //MARK: - Add image to Library
    @MainActor
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            showAlert(alertText: "Save error", alertMessage: error.localizedDescription)
        }
        else {
            showAlert(alertText: "Saved!", alertMessage: "Your image has been saved to your photos.")
        }
        endBackgroundUpdateTask(taskID: taskID)
        removeLoading(isLoading: &isLoading)
    }
}

extension PhotoViewController:UICollectionViewDelegate,UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return listImage.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? PhotoCell else { return UICollectionViewCell() }
        cell.setImage(img: listImage[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectImage = listImage[indexPath.row]
    }
}

extension PhotoViewController {
    func addBigViewAction(imgView:UIImageView) {
        let tapG = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        imgView.isUserInteractionEnabled = true
        imgView.addGestureRecognizer(tapG)
    }
    
    @objc func imageTapped() {
        guard let image = bigImageView.image else { return }
        let vc = ImagePreviewVC(image: image )
        navigationController?.pushViewController(vc, animated: true)
    }
}
