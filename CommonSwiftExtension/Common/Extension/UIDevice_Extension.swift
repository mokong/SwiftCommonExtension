//
//  UIDevice_Extension.swift
//  MWWaterMarkCamera
//
//  Created by Horizon on 17/1/2022.
//

import Foundation
import UIKit
import AVFoundation

extension UIDevice {
    class func cameraAuthorization(_ granted: ((Bool) -> Void)?) {
        grantedAuthorization(from: AVMediaType.video, complection: granted)
    }
    
    class func noAuthHandle(with type: AVMediaType, on vc: UIViewController) {
        let msg: String = "尚未获取相机访问权限，是否前去获取？"
        let alert = UIAlertController(title: "提示", message: msg, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "取消", style: UIAlertAction.Style.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "确定", style: UIAlertAction.Style.default, handler: { action in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        }))
        vc.present(alert, animated: true, completion: nil)
    }
    
    class func grantedAuthorization(from type: AVMediaType, complection: ((Bool) -> Void)?) {
        let authStatus = AVCaptureDevice.authorizationStatus(for: type)
        switch authStatus {
        case .denied:
            // 用户禁止
            complection?(false)
        case .notDetermined:
            // 尚未授权
            AVCaptureDevice.requestAccess(for: type) { granted in
                complection?(granted)
            }
        case .authorized:
            complection?(true)
        default:
            complection?(false)
        }
    }
}
