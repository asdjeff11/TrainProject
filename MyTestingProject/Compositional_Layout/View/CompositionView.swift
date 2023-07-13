//
//  CompositionView.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/7/3.
//

import Foundation
import UIKit
import Combine
class CompostionView:UIViewController{
    var collectionView : UICollectionView!
    lazy var dataSource = makeDataSource()
    let viewModel = CompositionViewModel()
    var cancelList:Set<AnyCancellable> = []
    
    enum Section:Int , CaseIterable {
        case title1 = 0
        case title2
        case title3
        case title4
        
        func getTitle()->String {
            "Title \(self.rawValue + 1)"
        }
    }
    
    lazy var collectionViewLayout:UICollectionViewLayout = {
        let item1BottomSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.1), heightDimension: .absolute(10))
        let containerAnchor = NSCollectionLayoutAnchor(edges: [.bottom])
        let supplementaryItem = NSCollectionLayoutSupplementaryItem(layoutSize: item1BottomSize, elementKind: "new-banner", containerAnchor: containerAnchor)
        
        // badge
        let badgeSize = NSCollectionLayoutSize(widthDimension: .absolute(20), heightDimension: .absolute(20))
        let badgeContainerAnchor = NSCollectionLayoutAnchor(edges: [.top, .trailing] , absoluteOffset: CGPoint(x: 5, y: -5))
        let badge = NSCollectionLayoutSupplementaryItem(layoutSize: badgeSize,
                                                        elementKind: BadgeView.reuseIdentify,
                                                        containerAnchor: badgeContainerAnchor)
        
        
        let layoutSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension:.fractionalHeight(1))
        let item1 = NSCollectionLayoutItem(layoutSize: layoutSize,supplementaryItems: [supplementaryItem,badge])
        item1.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
        
        let layoutSize2 = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(0.5))
        let item2 = NSCollectionLayoutItem(layoutSize: layoutSize2)
        item2.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
        
        // 垂直
        let subGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.25), heightDimension: .fractionalHeight(1))
        let subGroup = NSCollectionLayoutGroup.vertical(layoutSize: subGroupSize,subitems:[item2])
        
        // 水平
        let horGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(100))
        let horGroup = NSCollectionLayoutGroup.horizontal(layoutSize: horGroupSize, subitems: [item1, subGroup, subGroup])
       
        // header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(30))
        let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize,elementKind: HeaderView.reuseIdentify,
                                                                     alignment: .top)
        
        // footer
        /*let bottomSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(30))
        let bottomItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: bottomSize, elementKind:UICollectionView.elementKindSectionFooter ,alignment: .bottom ,absoluteOffset: CGPoint(x: 0, y: 0))
        */
        
        let backgroundItem = NSCollectionLayoutDecorationItem.background(elementKind: "background")
        let backgroundInset: CGFloat = 8
        backgroundItem.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: backgroundInset, trailing: 0)
        
        let section = NSCollectionLayoutSection(group: horGroup)
        section.orthogonalScrollingBehavior = .groupPaging // 滾動設定
        section.boundarySupplementaryItems = [headerItem]
        section.decorationItems = [backgroundItem]
        let sectionInset: CGFloat = 16
        section.contentInsets = NSDirectionalEdgeInsets(top: sectionInset, leading: 0, bottom: sectionInset, trailing: 0)
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        layout.register(BackgroundSupplementaryView.self, forDecorationViewOfKind: "background")
        return layout
    }()
    
    lazy var customCollectionViewLayout:UICollectionViewLayout = {
        let compositionalLayout = UICollectionViewCompositionalLayout(sectionProvider: { (sectionIndex, environment) -> NSCollectionLayoutSection? in
            let itemsPerRow = sectionIndex + 3
            let fraction: CGFloat = 1 / CGFloat(itemsPerRow)
            let inset: CGFloat = 2.5
            
            // Item
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset)
            
            // Group
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(fraction), heightDimension: .fractionalWidth(fraction))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let background = NSCollectionLayoutDecorationItem.background(elementKind: "background")
            background.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0)
            
            // Section
            let section = NSCollectionLayoutSection(group: group)
            // Supplementary Item
            let headerItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(30))
            let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerItemSize, elementKind: HeaderView.reuseIdentify, alignment: .top)
            section.boundarySupplementaryItems = [headerItem]
            section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
            section.decorationItems = [background]
            let sectionInset: CGFloat = 16
            section.contentInsets = NSDirectionalEdgeInsets(top: sectionInset, leading: 0, bottom: sectionInset, trailing: 0)
            
            section.visibleItemsInvalidationHandler = { (items,offset,env) in
                items.forEach { item in
                    if ( item.representedElementKind != "background" ) {
                        let distanceFromCenter = abs((item.frame.midX - offset.x) - env.container.contentSize.width / 2.0)
                        let minScale:CGFloat = 0 , maxScale:CGFloat = 1.1
                        let scale = max(maxScale - (distanceFromCenter / env.container.contentSize.width) , minScale)
                        item.transform = CGAffineTransform(scaleX:scale,y:scale)
                        item.alpha = min(1,scale)
                    }
                }
            }
            
            
            return section
        })
        
        compositionalLayout.register(BackgroundSupplementaryView.self, forDecorationViewOfKind: "background")
        
        return compositionalLayout
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.contents = Theme.backGroundImage
        setUpNav(title: "Compostional Test")
        
        viewModel.delegate = self
        viewModel.setUpData()
        setUpCollectionView()
        setUpSnapShot()
    }
}

extension CompostionView { // dataSource 設定 ( cell 的資訊 , 各種 supplementary 設定(EX: section header , footer)
    func makeDataSource()->UICollectionViewDiffableDataSource<Section,itemModel> {
        // 設定 cell
        let cellRegistration = UICollectionView.CellRegistration<CompositionCell,itemModel> {  cell , indexPath , item in
            cell.setContent(str: item.num)
        }
        
        // 設定 header
        let headerRegistration = UICollectionView.SupplementaryRegistration<HeaderView>(elementKind: HeaderView.reuseIdentify, handler: { (headerView , _, indexPath ) in
            headerView.label.text = Section(rawValue: indexPath.section)?.getTitle()
        })
        
        // 設定右上角badge
        let badgeRegistration = UICollectionView.SupplementaryRegistration<BadgeView>(elementKind: BadgeView.reuseIdentify, handler:{ (badgeView , _, _ ) in
            return
        })
        // 設定 底下banner
        let newBannerRegistration = UICollectionView.SupplementaryRegistration<UICollectionReusableView>(elementKind:"new-banner", handler: { ( view , _,_) in
            view.backgroundColor = .systemBlue
            let label = UILabel.createLabel(size: 9, color: .blue,alignment: .center ,text: "NEW")
            label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
            view.addSubview(label)
            label.centerInSuperview()
        })
        
        let dataSource = UICollectionViewDiffableDataSource<Section,itemModel> (
            collectionView: collectionView,
            cellProvider: { collectionView, indexPath , item in
                collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            }
        )
        
        dataSource.supplementaryViewProvider = { (collectionView ,elementKind , indexPath) -> UICollectionReusableView? in
            switch ( elementKind ) {
            case HeaderView.reuseIdentify :
                return collectionView.dequeueConfiguredReusableSupplementary(using:headerRegistration,for:indexPath)
            case BadgeView.reuseIdentify :
                return collectionView.dequeueConfiguredReusableSupplementary(using:badgeRegistration,for:indexPath)
            case "new-banner" :
                return collectionView.dequeueConfiguredReusableSupplementary(using: newBannerRegistration, for: indexPath)
            default :
                return nil
            }
        }
        
        return dataSource
    }
}

extension CompostionView { // setting Data
    func setUpSnapShot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section,itemModel>()
        snapshot.appendSections(Section.allCases)
        
        for caseS in Section.allCases {
            snapshot.appendItems(viewModel.getItems(section: caseS.rawValue),toSection: caseS)
        }
        
        dataSource.apply(snapshot,animatingDifferences: false)
    }
}

extension CompostionView { // setUp CollectionView
    func setUpCollectionView() {
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
        //collectionView.isScrollEnabled = false
        collectionView.dataSource = dataSource
        collectionView.backgroundColor = .clear
        collectionView.allowsMultipleSelection = true
        
        let button = UIButton()
        button.layer.shadowColor = UIColor(hex: 0xFFCC00,alpha: 0.25).cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 5)
        button.layer.shadowOpacity = 1.0
        button.layer.shadowRadius = 10.0
        button.layer.masksToBounds = false
        button.setTitle("刪除", for: .normal)
        button.backgroundColor = UIColor(hex: 0xFFCC00)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 20
        
        button.publisher().sink(receiveValue:{ [weak self] _ in
            self?.viewModel.deleteOne()
        }).store(in: &cancelList)
        
        view.addSubviews(collectionView,button)
        //collectionView.widthToSuperview(multiplier:0.9)
        collectionView.width(200)
        let margins = view.layoutMarginsGuide
        collectionView.top(to: margins,offset:30 )
        collectionView.bottomToSuperview(offset: -50 )
        collectionView.centerXToSuperview()
        
        button.top(to:collectionView,collectionView.bottomAnchor,offset: 15)
        button.centerXToSuperview()
        button.size(CGSize(width: 250, height: 30))
    }
}

extension CompostionView:CompositionDelegate {
    func deleteCallBack(model:itemModel) {
        var snapshot = dataSource.snapshot()
        snapshot.deleteItems([model])
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}
/*
extension CompostionView:UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 32
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let space = collectionView.dequeueReusableCell(withReuseIdentifier: "empty", for:indexPath)
        space.backgroundColor = .clear
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? CompositionCell
        else { return space }
        
        cell.setContent(str: "row:\(indexPath.row)")
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch ( kind ) {
        case HeaderView.reuseIdentify :
            guard let head = collectionView.dequeueReusableSupplementaryView(ofKind: HeaderView.reuseIdentify,
                                                                   withReuseIdentifier: "head", for: indexPath) as? HeaderView
            else { return HeaderView() }
            
            head.label.text = "Title \(indexPath.section)"
            return head
        case UICollectionView.elementKindSectionFooter :
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter,
                                                                   withReuseIdentifier: "footer", for: indexPath)
            footer.backgroundColor = .darkGray
            
            let label = UILabel.createLabel(size: 25 * Theme.factor, color: .black)
            label.text = "bottom \(indexPath.section)"
            footer.addSubview(label)
            label.centerXToSuperview()
            label.centerYToSuperview()
            label.heightToSuperview()
            label.widthToSuperview(multiplier:0.9)
            return footer
        case BadgeView.reuseIdentify :
            let badge = collectionView.dequeueReusableSupplementaryView(ofKind: BadgeView.reuseIdentify,
                                                                   withReuseIdentifier: BadgeView.reuseIdentify, for: indexPath) as! BadgeView
            return badge
        case "new-banner":
            let bannerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "NewBannerSupplementaryView", for: indexPath)
            bannerView.backgroundColor = .systemBlue
            let label = UILabel.createLabel(size: 9, color: .blue,alignment: .center ,text: "NEW")
            label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
            bannerView.addSubview(label)
            label.centerInSuperview()
            
            return bannerView
        default :
            return UICollectionReusableView()
        }
    }
}*/
