//
//  UIDevice_Extension.swift
//  MWWaterMarkCamera
//
//  Created by Horizon on 17/1/2022.
//

import Foundation
import UIKit
import AVFoundation
import Photos

extension UIDevice {
    /// 底部 safeArea 高度
    static func bottomSafeAreaHeight() -> CGFloat {
        if UIDevice.isFullScreen() {
            return 34.0
        }
        else {
            return 0.0
        }
    }
    
    /// 不准确的导航栏高度
    static func navigationBarH() -> CGFloat {
        if isFullScreen() {
            return 88.0
        }
        else {
            return 64.0
        }
    }
    
    /// 是否是全面屏
    static func isFullScreen() -> Bool {
        if #available(iOS 11.0, *) {
            if let window = UIApplication.shared.delegate?.window,
                let height = window?.safeAreaInsets.bottom,
                height > 0 {
                return true
            }
            else {
                return false
            }
        } else {
            // Fallback on earlier versions
            return false
        }
    }
    
    /// 状态栏高度
    static func statusBarH() -> CGFloat {
        var height: CGFloat = 0.0
        if #available(iOS 13.0, *) {
            height = UIApplication.shared.windows.first?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            height = UIApplication.shared.statusBarFrame.height
        }
        return height
    }
    
    class func grantedPhotoAuthorization(completion: ((Bool) -> Void)?) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .denied:
            completion?(false)
        case .restricted:
            completion?(false)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    completion?(true)
                }
                else {
                    completion?(false)
                }
            }
        case .authorized:
            completion?(true)
        default:
            completion?(false)
        }
    }
    
    class func cameraAuthorization(_ granted: ((Bool) -> Void)?) {
        grantedCameraAuthorization(from: AVMediaType.video, completion: granted)
    }
    
    class func noAuthHandle(with msg: String, on vc: UIViewController) {
        let alert = UIAlertController(title: "提示", message: msg, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "取消", style: UIAlertAction.Style.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "确定", style: UIAlertAction.Style.default, handler: { action in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        }))
        vc.present(alert, animated: true, completion: nil)
    }
    
    class func grantedCameraAuthorization(from type: AVMediaType, completion: ((Bool) -> Void)?) {
        let authStatus = AVCaptureDevice.authorizationStatus(for: type)
        switch authStatus {
        case .denied:
            // 用户禁止
            completion?(false)
        case .notDetermined:
            // 尚未授权
            AVCaptureDevice.requestAccess(for: type) { granted in
                completion?(granted)
            }
        case .authorized:
            completion?(true)
        default:
            completion?(false)
        }
    }
}
