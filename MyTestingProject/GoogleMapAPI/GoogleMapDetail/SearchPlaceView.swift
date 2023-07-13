//
//  SearchPlaceView.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/8.
//

import Foundation
import UIKit
import GoogleMaps
class SearchPlaceView:UIViewController {
    var placeKeyWord: String? // 用關鍵字搜尋地點， 灌值-> 兩者擇一
    var centerPlace:CLLocationCoordinate2D? // 地圖上點選位置 搜尋
    
    var nearPlaceData:[Place] = [] // 儲存抓到的資料 (placeName,snippet,placeID,location) 名稱 , 地址 , 位置
    var returnNearPlace:((Place)->())? // 回傳 tableView 選到的值
    
    private var contentView: UIView = { // 主視窗
        let contentView = UIView(frame: CGRect(x: 0, y: 0, width: 600 * Theme.factor , height: 800 * Theme.factor))
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true
        contentView.center = CGPoint(x: Theme.fullSize.width * 0.5, y: Theme.fullSize.height * 0.5)
        contentView.backgroundColor = UIColor.white
        return contentView
    }() // 主視窗
    var tableView: UITableView!
    var titleView: UIView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
            self.tableView.animateTable()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        self.view.addSubview(contentView)
        
        setCompoment()
        layout()
        if centerPlace != nil { fetchNearPlace() } // 以中心點找標地物
        else if placeKeyWord != nil { searchPlaceKeyword() } // 以關鍵找標地物
    }
}

extension SearchPlaceView: UITableViewDelegate, UITableViewDataSource { // table function
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nearPlaceData.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = .clear
        
        // textLabel --------------------------------------------------
        cell.textLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.translatesAutoresizingMaskIntoConstraints = false
        cell.textLabel?.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 30 * Theme.factor).isActive = true
        cell.textLabel?.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -30 * Theme.factor).isActive = true
        cell.textLabel?.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 30 * Theme.factor).isActive = true
        cell.textLabel?.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -30 * Theme.factor).isActive = true
        
        let data = nearPlaceData[indexPath.row]
        cell.textLabel?.text = data.name + "\n\n" + data.address // placeName
        cell.textLabel?.font = .systemFont(ofSize: 16)
        cell.textLabel?.textColor = .black
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = nearPlaceData[indexPath.row]
        returnNearPlace?(data) // String (placeName), String (snippet), CLLocationCoordinate2D (location)
        close()
    }
    
} // table function

extension SearchPlaceView { // setCompoment , layout
    
    fileprivate func layout(){
        
        contentView.addSubviews(titleView,tableView)
        NSLayoutConstraint.useAndActivateConstraints(constraints: [
        
            titleView.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleView.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            titleView.heightAnchor.constraint(equalToConstant: 90 * Theme.factor),

            tableView.topAnchor.constraint(equalTo: titleView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    fileprivate func setCompoment(){ // 設置主要呈現的元件
        
        titleView = buildTitle()
        
        tableView = UITableView()
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 10 * Theme.factor, bottom: 0, right: 10 * Theme.factor)
        tableView.separatorColor = Theme.navigationBarBG
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .white
        tableView.showsVerticalScrollIndicator = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
    } // 設置主要呈現的元件
    
    fileprivate func buildTitle()->UIView {

        let titleLabel = UILabel.createLabel(size: 26, color: .white ,text: placeKeyWord == nil ? "附近地點" : "搜尋地點")
        
        let closeButton = UIButton()
        closeButton.addTarget(self, action: #selector(self.close), for: .touchUpInside)
        closeButton.setImage(UIImage(named: "ibutton7_3.png")?.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.tintColor = .white
        
        let view = UIView()
        view.backgroundColor = Theme.navigationBarBG
        view.addSubviews(titleLabel,closeButton)
        NSLayoutConstraint.useAndActivateConstraints(constraints: [
        
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            closeButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30 * Theme.factor),
            closeButton.widthAnchor.constraint(equalToConstant: 60 * Theme.factor),
            closeButton.heightAnchor.constraint(equalToConstant: 60 * Theme.factor)
        ])
        return view
    }
    
} // setCompoment , layout

extension SearchPlaceView { // other function
    
    @objc func close() { // close keyboard
        self.dismiss(animated: true)
    }
    
    private func fetchNearPlace(){
        guard let centerPlace = centerPlace else { return }
        
        let latitude = centerPlace.latitude
        let longitude = centerPlace.longitude
                
        let urlStr = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(latitude),\(longitude)&radius=50&type=point_of_interest&language=zh-TW&key=\(AppDelegate.googleMapAPIkey)"
        
        guard let url = URL(string: urlStr) else { return }
        
        let group = DispatchGroup()
        group.enter()
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            defer {
                group.leave()
            }
            guard let data = data else { return }
            do {
                let totalData = try JSONSerialization.jsonObject(with: data, options: []) // 把 data 轉成 json字串
                guard let results = ((totalData as? [String: Any])?["results"] as? [Any]) else { return } // 把 json 字串轉成 dictionary
                
                for result in results {
                    guard let dict = result as? [String:Any] else { continue }
                    guard let latlon = ((dict["geometry"] as? [String:Any])?["location"] as? [String:Double]) else { continue }
                    guard let name = (dict["name"]) as? String else { continue }
                    guard let address = (dict["vicinity"]) as? String else { continue }
                    guard let pointID = (dict["place_id"]) as? String else { continue }
                    var photo_ref:String?
                    // result["photos"] -> Arr[Any] ;  Arr[0] -> d[String:Any] (width:,height:,html:,photo_ref:) ; d["photo_reference"] -> Any(Photo_Reference)
                    if let ref = ((dict["photos"] as? [Any])?[0] as? [String:Any])?["photo_reference"] as? String {
                        photo_ref = ref
                    }
                    
                    let location = CLLocationCoordinate2D(latitude: CLLocationDegrees(latlon["lat"]!),
                                                          longitude: CLLocationDegrees(latlon["lng"]!))
                    
                    self.nearPlaceData.append(Place(name: name, address: address, pointID: pointID,photoReference: photo_ref, location: location))
                }
            } catch {
                print(error)
            }
        }.resume()
        
        group.wait()
    }
    
    private func searchPlaceKeyword(){
                
        let urlStr = "https://maps.googleapis.com/maps/api/place/textsearch/json?query=\(placeKeyWord!)&type=point_of_interest&language=zh-TW&key=\(AppDelegate.googleMapAPIkey)"
        let urlChWordStr = urlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) // 如果網址包含中文要用這個
        
        guard let url = URL(string: urlChWordStr!) else { return }
        
        
        let group = DispatchGroup()
        group.enter()
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            defer {
                group.leave()
            }
            guard let data = data else { return }
            do {
                let totalData = try JSONSerialization.jsonObject(with: data, options: []) // 把 data 轉成 json字串
                guard let results = ((totalData as? [String: Any])?["results"] as? [Any]) else { return } // 把 json 字串轉成 dictionary
                
                for result in results {
                    guard let dict = result as? [String:Any] else { continue }
                    guard let latlon = ((dict["geometry"] as? [String:Any])?["location"] as? [String:Double]) else { continue }
                    guard let name = (dict["name"]) as? String else { continue }
                    guard let address = (dict["formatted_address"]) as? String else { continue }
                    guard let pointID = (dict["place_id"]) as? String else { continue }
                    var photo_ref:String?
                    // result["photos"] -> Arr[Any] ;  Arr[0] -> d[String:Any] (width:,height:,html:,photo_ref:) ; d["photo_reference"] -> Any(Photo_Reference)
                    if let ref = ((dict["photos"] as? [Any])?[0] as? [String:Any])?["photo_reference"] as? String {
                        photo_ref = ref
                    }
                    
                    let location = CLLocationCoordinate2D(latitude: CLLocationDegrees(latlon["lat"]!),
                                                          longitude: CLLocationDegrees(latlon["lng"]!))
                    self.nearPlaceData.append(Place(name: name, address: address, pointID: pointID,photoReference: photo_ref, location: location))
                }
            } catch {
                print(error)
            }
        }.resume()
        
        group.wait()
    }
    
} // other function

