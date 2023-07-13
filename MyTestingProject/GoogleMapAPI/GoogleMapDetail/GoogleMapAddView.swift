//
//  GoogleMapAddView.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/8.
//

import Foundation
import UIKit
import GoogleMaps
import Combine
class GoogleMapAddView:UIViewController {
    enum TypeError:Error {
        case toURLError
        case noPic
        case toJSonStringError
        case responseError
    }
    
    enum GetPlaceError:Error {
        case url轉換失敗
        case 抓取地點錯誤
        case 取得API回傳資訊錯誤
        case toJSonError
        case requestFailed(String)
    }
    
    enum GetImageError:Error {
        case url轉換失敗
        case 取得API回傳資訊錯誤
        case 抓取圖片錯誤
        case requestFailed(Error)
    }
    
    var recordPlace:Place?
    
    var finishChoiceButton = UIButton()
    var searchView = UIView()
    
    var backViewForHidden = UIView() // 拿來點擊隱藏 keyboard 使用
    
    // googleMap 部分 ---------------------------
    var mLocationManager: CLLocationManager! // 經緯度偵測器
    var mapView: GMSMapView! // google專用 View
    var marker: GMSMarker! // 地圖上的大頭針
    
    var isLocating = false
    var isLoading = false
    
    var cancelList = [AnyCancellable]()
    
    override func viewWillDisappear(_ animated: Bool) {
        mLocationManager.stopUpdatingLocation()
        mLocationManager.delegate = nil
        mLocationManager = nil
        mapView.delegate = nil
        mapView.clear()
        mapView.removeFromSuperview()
        mapView = nil
        
        cancelList.removeAll()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loading(isLoading: &isLoading)
        if #available (iOS 15, *) {
            switch ( mLocationManager.authorizationStatus) {
            case .notDetermined , .authorizedWhenInUse : // 使用者還沒決定 or 使用者要求每次開啟都要問一次
                mLocationManager.requestWhenInUseAuthorization() // 請求開啟定位
            case .authorizedAlways : // 使用者永遠允許
                mLocationManager.startUpdatingLocation() // 開始定位
            default : // 使用者拒絕開啟定位
                let alertAction = UIAlertAction(title: "確認", style: .default) { [weak self] _ in
                    self?.leftBtnAct() // 返回上一頁
                }
                showAlert(alertText: "提醒", alertMessage: "請打開定位服務", alertAction: alertAction)
            }
        }
        else {
            switch ( CLLocationManager.authorizationStatus() ) { // 開啟APP會詢問使用權限
            case .notDetermined , .authorizedWhenInUse : // 使用者還沒決定 or 使用者要求每次開啟都要問一次
                mLocationManager.requestWhenInUseAuthorization() // 請求開啟定位
            case .authorizedAlways : // 使用者永遠允許
                mLocationManager.startUpdatingLocation() // 開始定位
            default : // 使用者拒絕開啟定位
                let alertAction = UIAlertAction(title: "確認", style: .default) { [weak self] _ in
                    self?.leftBtnAct() // 返回上一頁
                }
                showAlert(alertText: "提醒", alertMessage: "請打開定位服務", alertAction: alertAction)
            }
        }
        
        layout()
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNav(title: "選擇地點",backButtonVisit: true)
        view.backgroundColor = .white
        setCompoment()
    }
    
    @objc private func endEdit() {
        self.view.endEditing(true)
        backViewForHidden.isHidden = true
    }
}

extension GoogleMapAddView {
    private func setCompoment() {
        searchView = buildSearchView()
        
        backViewForHidden.backgroundColor = .clear
        backViewForHidden.isHidden = true
        
        let tapG = UITapGestureRecognizer(target: self, action: #selector(endEdit))
        self.backViewForHidden.addGestureRecognizer(tapG)
        
        mapView = GMSMapView()
        mapView.delegate = self
        mapView.mapType = .normal // google map 顯示模式
        
        finishChoiceButton.titleLabel?.font = .systemFont(ofSize: 16)
        finishChoiceButton.layer.cornerRadius = 20
        finishChoiceButton.setTitle("完  成", for: .normal)
        finishChoiceButton.setTitleColor(.white, for: .normal)
        finishChoiceButton.backgroundColor = Theme.navigationBarBG
        finishChoiceButton.addTarget(self, action: #selector(finish), for: .touchUpInside)
        
        mLocationManager = CLLocationManager()
        mLocationManager.delegate = self // 委任底下定位函數
        mLocationManager.desiredAccuracy = kCLLocationAccuracyBest // // 取得自身定位位置的精確度(最佳)
        marker = GMSMarker()
    }
    
    private func buildSearchView()->UIView {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.borderColor = UIColor.black.cgColor
        view.layer.borderWidth = 1
        
        let textField = TextField()
        textField.font = .systemFont(ofSize: 16)
        textField.placeholder = "請輸入搜尋地點"
        textField.delegate = self
        
        let btn = UIButton()
        btn.titleLabel?.font = .systemFont(ofSize: 16)
        btn.layer.cornerRadius = 15
        btn.setTitle("搜尋", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = Theme.navigationBarBG
        btn.publisher()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] _ in
                guard let self = self , self.isLoading == false else { return }
               
                self.endEdit()
                let vc = SearchPlaceView()
                vc.returnNearPlace = self.returnNearPlace // callBack
                vc.placeKeyWord = textField.text
                self.addViewToPresent(viewController: vc)
            })
            .store(in: &cancelList)
        
        view.addSubviews(textField,btn)
        NSLayoutConstraint.useAndActivateConstraints(constraints: [
            
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textField.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            textField.heightAnchor.constraint(equalTo: view.heightAnchor,multiplier: 0.7),
            textField.trailingAnchor.constraint(equalTo: btn.leadingAnchor),
            
            btn.trailingAnchor.constraint(equalTo: view.trailingAnchor,constant: -40 * Theme.factor),
            btn.widthAnchor.constraint(equalToConstant: 150 * Theme.factor),
            btn.heightAnchor.constraint(equalTo: view.heightAnchor,multiplier: 0.6),
            btn.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        return view
    }

    fileprivate func layout(){
        let margin = view.layoutMarginsGuide
        view.addSubviews(finishChoiceButton,searchView,mapView,backViewForHidden)
        
        NSLayoutConstraint.useAndActivateConstraints(constraints: [
            backViewForHidden.topAnchor.constraint(equalTo: margin.topAnchor),
            backViewForHidden.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backViewForHidden.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backViewForHidden.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            mapView.topAnchor.constraint(equalTo: margin.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            searchView.topAnchor.constraint(equalTo: margin.topAnchor),
            searchView.widthAnchor.constraint(equalTo: view.widthAnchor),
            searchView.heightAnchor.constraint(equalToConstant: 80 * Theme.factor),
            
            finishChoiceButton.bottomAnchor.constraint(equalTo: margin.bottomAnchor,constant: -30 * Theme.factor),
            finishChoiceButton.centerXAnchor.constraint(equalTo: margin.centerXAnchor),
            finishChoiceButton.widthAnchor.constraint(equalToConstant: 200 * Theme.factor),
            finishChoiceButton.heightAnchor.constraint(equalToConstant: 70 * Theme.factor)
            
        ])
        
        view.sendSubviewToBack(searchView)
        view.sendSubviewToBack(finishChoiceButton)
        view.sendSubviewToBack(mapView)
        view.bringSubviewToFront(backViewForHidden)
    }
}

extension GoogleMapAddView {
    @objc func finish() { // 點擊完成後
        if ( isLoading ) { return }
        guard let place = recordPlace else {
            showAlert(alertText: "提醒", alertMessage: "請選擇地點")
            return
        }
        
        loading(isLoading: &isLoading)
        let task = beginBackgroundUpdateTask()
        
        Task {
            let result = await getImage2()
            var errorBody = ""
            switch ( result ) {
            case .failure(let type) :
                switch ( type ) {
                case .invalidData :
                    errorBody = "取得圖片資訊錯誤"
                case .invalidResponse :
                    errorBody = "Server回傳圖片資訊錯誤"
                case .invalidUrl :
                    errorBody = "解析圖片url失敗"
                case .requestFailed(let error) :
                    errorBody = "取得圖片失敗 :\(error.localizedDescription)"
                case .isCanceled :
                    errorBody = "取得圖片 被取消"
                }
            case .success(_) :
                let now = Theme.serverDateFormatter.string(from: Date())
                
                let fa_place = FavoritePlace(ID: place.pointID,
                                             name: place.name,
                                             address: place.address,
                                             date: now,
                                             picURL: place.photoReference!,
                                             latitude: place.location.latitude,
                                             longitude: place.location.longitude)
                if ( !db.executeQuery(query: fa_place.getUpdateQuery())) {
                    errorBody = "資料儲存至本機失敗"
                }
            }
            
            Task.detached(operation: { @MainActor [weak self] in
                guard let self = self else { return } 
                self.removeLoading(isLoading: &self.isLoading)
                self.endBackgroundUpdateTask(taskID: task)
                if ( errorBody != "" ) {
                    self.showAlert(alertText: "資料錯誤", alertMessage: errorBody)
                }
                else {
                    let alertAction = UIAlertAction(title: "確認", style: .default) { [weak self] _ in
                        self?.leftBtnAct()
                    }
                    self.showAlert(alertText: "建立成功", alertMessage: "",alertAction: alertAction)
                }
            })
        }
    }
    
    func returnNearPlace(place:Place) {
        self.recordPlace = place
        // 設定大頭針
        (marker.title,marker.snippet) = (place.name,place.address)
        // 移動GoogleMap畫面
        showLocation(location:place.location,zoom:mapView.camera.zoom)
    }
}

// 定位部分
extension GoogleMapAddView:CLLocationManagerDelegate {
    @available (iOS 14.0, *)
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch ( status ) {
        case .authorizedAlways, .authorizedWhenInUse :
            mLocationManager.startUpdatingLocation() // 索取定位自身位置
        case .denied , .restricted :
            // pop to parent view
            leftBtnAct()
            break
        case .notDetermined:
            break
        @unknown default:
            leftBtnAct()
            break
        }
    }
    
    /// 抓取使用者目前位置 「 startUpdatingLocation() or requestLocation() 委任觸發 」
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        mLocationManager.stopUpdatingLocation() // 由於定位功能十分耗電，我們既然已經取得了位置，就該趕快把它關掉
        if ( isLocating ) { return }
        isLocating = true
        if #available ( iOS 15,* ) {
            guard mLocationManager.authorizationStatus != .denied ||
                  mLocationManager.authorizationStatus != .restricted
            else {
                return
            }
        }
        
        
        //let currentLocation: CLLocation = locations.last! // 取得當下座標
        //回傳一個陣列的 CLLocation，而最後回傳的會是最接近於我們當前位置的 CLLocation, 因此我們要取的就是這個 CLLocation
        
        // let locationSet = currentLocation.coordinate // 模擬器預設地點： 紐約
        let locationSet = CLLocationCoordinate2D(latitude: 24.990098, longitude: 121.309933) // 模擬器測試用，實機要刪掉這行!!!
        
        Task { [weak self] in
            guard let result = await self?.returnMarkerData2(locationSet) else { return }
            self?.analysisData(result: result, coordinate: locationSet)
            if let self = self {
                self.removeLoading(isLoading: &self.isLoading)
            }
        }
       
        /*
        returnMarkerData(locationSet, completion:{ [weak self] (result: Result<(String,String,String), GetPlaceError>) in
            guard let self = self else { return }
            // 根據取得的資訊做分析 裡面設定 地點名稱 , 地址 , 經緯度 , 並移動地圖
            DispatchQueue.main.async {
                self.analysisData(result: result, coordinate: locationSet)
                self.removeLoading(isLoading: &self.isLoading)
            }
        })*/
    }
    
    /// 如果取位置遇到錯誤的處理
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
        let alertAction = UIAlertAction(title: "確認", style: .default) { [weak self] _ in
            self?.leftBtnAct() // 返回上一頁
        }
        showAlert(alertText: "定位錯誤", alertMessage: "請重新嘗試此功能",alertAction: alertAction)
    }
}

// GoogleMap function 呼叫
extension GoogleMapAddView:GMSMapViewDelegate {
    // 點擊大頭針上方訊息
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        let vc = SearchPlaceView()
        vc.returnNearPlace = returnNearPlace
        vc.centerPlace = self.mapView.camera.target
        addViewToPresent(viewController: vc)
    }
    
    // 點擊大頭針觸發
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        let vc = SearchPlaceView()
        vc.returnNearPlace = returnNearPlace
        vc.centerPlace = self.mapView.camera.target
        addViewToPresent(viewController: vc)
        return true
    }
    
    // 點擊地圖上任一地區
    func mapView(_ mapView:GMSMapView, didTapAt coordinate:CLLocationCoordinate2D) {
        Task { [weak self] in
            guard let result = await self?.returnMarkerData2(coordinate) else { return }
            self?.analysisData(result: result, coordinate: coordinate,zoom:mapView.camera.zoom)
        }
    }
}

extension GoogleMapAddView {
    @MainActor
    private func analysisData(result:Result<(String,String,String), CustomError>,
                              coordinate:CLLocationCoordinate2D,
                              zoom:Float = 18 ) {
        switch ( result ) {
        case .success((let title,let address,let pointID)) :
            self.marker.title = title
            self.marker.snippet = address
            self.recordPlace = Place(name: title, address: address, pointID: pointID, location: coordinate)
            self.showLocation(location: coordinate, zoom: zoom)
        case .failure(let errorType) :
            var body = ""
            switch ( errorType ) {
            case .invalidData :
                body = "取得Server資料錯誤"
            case .invalidResponse :
                body = "Server回傳失敗"
            case .invalidUrl :
                body = "URL轉換失敗"
            case .requestFailed(let errorMsg) :
                body = "錯誤資訊:\(errorMsg.localizedDescription)"
            case .isCanceled :
                body = "task 被取消"
            }
            self.showAlert(alertText: "提醒", alertMessage: body)
        }
    }
    
    
    // 調整 map位置
    private func showLocation(location: CLLocationCoordinate2D, zoom:Float) {
        mapView.camera = GMSCameraPosition.camera(withTarget: location, zoom: zoom) // 調整現在地圖的中心位置
        marker.position = location
        // 連結 mapView 與 marker
        marker.map = mapView
        mapView.selectedMarker = marker
    }
    
    // googleMap API 回傳經緯度相對應到的地址
    private func returnMarkerData2(_ location: CLLocationCoordinate2D) async -> Result<(String,String,String),CustomError> {
        let latitude = location.latitude
        let longitude = location.longitude
        var address = ""
        var name = ""
        var placeID = ""
        
        let urlStr = "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(latitude),\(longitude)&language=zh-TW&key=\(AppDelegate.googleMapAPIkey)"
        do {
            let data = try await urlGetData(url: urlStr)
            guard let totalData = try? JSONSerialization.jsonObject(with: data, options: []) , // data to JSONString
                  let result = ((totalData as? [String:Any])?["results"] as? [Any])?.first ,
                  var addr = (result as? [String:Any])?["formatted_address"] as? String ,
                  let ID = (result as? [String:Any])?["place_id"] as? String else { return .failure(.invalidData) } // 取出得到的結果
            
            if ( addr.positionOf(sub: " ") != -1 ) {
                addr = String(addr.dropFirst(addr.positionOf(sub: " ")))
            }
            
            if let result_name = ( result as? [String:Any])?["name"] as? String { // 有搜到名稱
                name = result_name
                address = addr
            }
            else {
                name = addr
                address = ""
            }
            placeID = ID
            return .success((name,address,placeID))
        }
        catch TypeError.toURLError {
            return .failure(.invalidUrl)
        }
        catch TypeError.responseError {
            return .failure(.invalidResponse)
        }
        catch {
            return .failure(.invalidResponse)
        }
    }
    
    private func getImage2() async -> Result<UIImage,CustomError> {
        guard let place = self.recordPlace , place.pointID != "" else {
            return .success(UIImage(named: "noPic") ?? UIImage())
        }
        do {
            var photo_ref = place.photoReference
            if ( photo_ref == nil ) {
                let placeDetail_url = "https://maps.googleapis.com/maps/api/place/details/json?place_id=\(place.pointID)&language=zh-TW&key=\(AppDelegate.googleMapAPIkey)"
                let placeDetail_data = try await urlGetData(url: placeDetail_url)
                
                guard let totalData = try? JSONSerialization.jsonObject(with: placeDetail_data, options: []) , // data to JSONString
                      let result = ((totalData as? [String:Any])?["result"] as? [String:Any])
                else { return .failure(.invalidData) } // 取出得到的結果
                
                guard let photos = result["photos"] as? [Any] , photos.count > 0 else { return .success(UIImage(named: "noPic") ?? UIImage()) } // 本身 google 就沒有它圖片
                photo_ref = (photos[0] as? [String:Any])?["photo_reference"] as? String // 取得第一張圖片url
                if ( photo_ref == nil ) { return .failure(.invalidData) } // 解析失敗回傳
            }
            
            // 第二個 傳接
            let photo_url = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=\(photo_ref!)&key=\(AppDelegate.googleMapAPIkey)" //建立url
            let photo_data = try await urlGetData(url: photo_url)
            
            guard let image = UIImage(data: photo_data) else { return .failure(.invalidData) }
            imgDict.putIntoDict(url: photo_ref!, img: image)
            return .success(image)
            
        }
        catch TypeError.toURLError {
            return .failure(.invalidUrl)
        }
        catch TypeError.responseError {
            return .failure(.invalidResponse)
        }
        catch {
            return .failure(.invalidResponse)
        }
    }
    
    private func urlGetData(url:String) async throws -> Data {
        guard let url = URL(string: url) else { throw TypeError.toURLError }
        
        guard let (data,response) = try? await URLSession.shared.data(from:url),
              let response = response as? HTTPURLResponse,
              (200...299).contains(response.statusCode) else { throw TypeError.responseError }
        
        return data
    }
    
    /*
    private func returnMarkerData(_ location: CLLocationCoordinate2D , completion:@escaping (Result<(String,String,String),GetPlaceError>)->Void ) {
        let latitude = location.latitude
        let longitude = location.longitude
        
        let urlStr = "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(latitude),\(longitude)&language=zh-TW&key=\(AppDelegate.googleMapAPIkey)"
        guard let url = URL(string: urlStr) else { completion(.failure(.url轉換失敗)) ; return  }
        
        
        URLSession.shared.dataTask(with: url , completionHandler:{ (data, response, error) in
            if let error = error {
                completion(.failure(.requestFailed(error)))
                return
            }
            
            guard let data = data else { completion(.failure(.抓取地點錯誤)) ; return }
            do {
                let totalData = try JSONSerialization.jsonObject(with: data, options: []) // data to JSONString
                guard let result = ((totalData as? [String:Any])?["results"] as? [Any])?.first else { completion(.failure(.取得API回傳資訊錯誤)) ; return } // 取出得到的結果
                guard var addr = (result as? [String:Any])?["formatted_address"] as? String else { completion(.failure(.取得API回傳資訊錯誤)); return } // 取得地址資訊
                if ( addr.positionOf(sub: " ") != -1 ) {
                    addr = String(addr.dropFirst(addr.positionOf(sub: " ")))
                }
                
                var address = ""
                var name = ""
                if let result_name = ( result as? [String:Any])?["name"] as? String { // 有搜到名稱
                    name = result_name
                    address = addr
                }
                else {
                    name = addr
                    address = ""
                }
                
                if let ID = ( result as? [String:Any])?["place_id"] as? String  {
                    completion(.success((name,address,ID)))
                    return
                }
                
                completion(.failure(.取得API回傳資訊錯誤))
            }
            catch {
                completion(.failure(.toJSonError))
            }
            
        }).resume()
    }
    */
    /*private func getImage(completion:@escaping (Result<UIImage,GetImageError>)->Void) {
        if ( self.recordPicReference == "" ) {
            completion(.success(UIImage(named: "noPic")!))
            return 
        }
        
        let urlPic_str = "https://maps.googleapis.com/maps/api/place/details/json?place_id=\(self.recordPicReference)&language=zh-TW&key=\(AppDelegate.googleMapAPIkey)"
        guard let urlPic = URL(string: urlPic_str) else { completion(.failure(.url轉換失敗)) ; return }
        
        URLSession.shared.dataTask(with: urlPic, completionHandler: { (data, response, error) in
            if let error = error { completion(.failure(.requestFailed(error))) ; return }
            guard let data = data else { completion(.failure(.取得API回傳資訊錯誤)) ; return }
            do {
                let totalData = try JSONSerialization.jsonObject(with: data, options: []) // data to JSONString
                guard let result = ((totalData as? [String:Any])?["result"] as? [String:Any]) else { completion(.failure(.取得API回傳資訊錯誤)) ; return }
                // 有機會沒圖片 如果不是大地標的話 就回傳 noPic
                guard let photos = result["photos"] as? [Any] , photos.count > 0 else { completion(.success(UIImage(named: "noPic")!)) ; return }
                guard let photoReference = (photos[0] as? [String:Any])?["photo_reference"] as? String else { completion(.failure(.取得API回傳資訊錯誤)); return }
                
                let urlStr = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=\(photoReference)&key=\(AppDelegate.googleMapAPIkey)"
                guard let url = URL(string: urlStr) else { completion(.failure(.url轉換失敗)) ; return  }
                
                URLSession.shared.dataTask(with: url) { (data, response, error) in
                    if let error = error {
                        completion(.failure(.requestFailed(error)))
                        return
                    }
                    
                    guard let data = data else { completion(.failure(.取得API回傳資訊錯誤)) ; return }
                    guard let image = UIImage(data: data) else { completion(.failure(.抓取圖片錯誤)) ; return }
                    
                    completion(.success(image))
                }.resume()
                return
            }
            catch {
                print(error)
            }
            // 取出得到的結果
            completion(.failure(.抓取圖片錯誤))
        }).resume()
    }*/
}

extension GoogleMapAddView:UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if ( isLoading ) { return false } // 還在loading 不給點選
        return true
    }
}

