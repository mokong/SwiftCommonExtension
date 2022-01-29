//
//  MWLocationManager.swift
//  MWWaterMarkCamera
//
//  Created by Horizon on 17/1/2022.
//

import Foundation
import CoreLocation

let kLocationFailedStr = "获取位置失败，请重试"
let kLocationingStr = "正在获取位置..."

class MWLocationManager: NSObject {
    
    typealias LocationCallback = (_ curLocation: CLLocation?, _ curAddress: String?, _ err: String?) -> ()
    
    // MARK: - properties
    static let shared: MWLocationManager = MWLocationManager()
    private override init() {
        super.init()
        locationManager.delegate = self
    }
    
    fileprivate var locationManager: CLLocationManager = {
       let tempLM = CLLocationManager()
        tempLM.desiredAccuracy = kCLLocationAccuracyBest
        tempLM.distanceFilter = 100
        tempLM.requestWhenInUseAuthorization()
        return tempLM
    }()
    
    fileprivate lazy var geocoder: CLGeocoder = CLGeocoder()
    
    // 当前坐标
    private(set) var curLocation: CLLocation?
    // 当前选中位置的坐标
    private(set) var curAddressCoordinate: CLLocationCoordinate2D?
    // 当前位置地址
    private(set) var curAddress: String?
    // 定位回调
    private(set) var locationFinished: LocationCallback?
    
    // MARK: - init

    
    // MARK: - utils
    open func startLocation(_ callback: @escaping LocationCallback) {
        self.locationFinished = callback
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
            print("开始定位")
        }
    }
    
    // MARK: - action
    
    
    // MARK: - other
    // 解析经纬度
    func reverseAddressInfo(_ tlocation: CLLocation?) {
        guard let location = tlocation else {
            return
        }
        curLocation = location

        geocoder.reverseGeocodeLocation(location) { [weak self] placemark, error in
            if error == nil {
                if let firstPlaceMark = placemark?.first {
                    var address = ""
                    
                    // 省
                    if let administrativeArea = firstPlaceMark.administrativeArea {
                        address.append(administrativeArea)
                    }
                    
                    // 自治区
                    if let subAdministrativeArea = firstPlaceMark.subAdministrativeArea,
                       !address.contains(subAdministrativeArea) {
                        address.append(subAdministrativeArea)
                    }
                    
                    // 市
                    if let locality = firstPlaceMark.locality,
                       !address.contains(locality) {
                        address.append(locality)
                    }
                    
                    // 区
                    if let subLocality = firstPlaceMark.subLocality,
                       !address.contains(subLocality) {
                        address.append(subLocality)
                    }
                    
                    // 地名
                    if let name = firstPlaceMark.name {
                        address.append(name)
                    }
                    
                    self?.curAddress = address
                    self?.locationFinished?(location, address, nil)
                }
            }
            else {
                self?.locationFinished?(nil, nil, "定位失败：\(String(describing: error))")
            }
        }
        
    }
    
}

extension MWLocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // 停止定位
        if locations.count > 0 {
            manager.stopUpdatingLocation()
            
            // 获取最新的坐标
            reverseAddressInfo(locations.last)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationFinished?(nil, nil, "定位失败：\(error)")
    }
}
