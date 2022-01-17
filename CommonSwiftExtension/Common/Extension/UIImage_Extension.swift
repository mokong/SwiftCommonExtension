//
//  UIImage_Extension.swift
//  MWWaterMarkCamera
//
//  Created by Horizon on 17/1/2022.
//

import Foundation
import UIKit
import AVFoundation

extension UIImage {
    // 根据设备方向和摄像头方向，返回图片的方向
    class func getUIImageOrientation(from devicePosition: AVCaptureDevice.Position) -> UIImage.Orientation {
        let orientation = UIDevice.current.orientation
        switch orientation {
        case .portrait, .faceUp:
            return UIImage.Orientation.right
        case .portraitUpsideDown, .faceDown:
            return UIImage.Orientation.left
        case .landscapeLeft:
            if devicePosition == .back {
                return UIImage.Orientation.up
            }
            else {
                return UIImage.Orientation.down
            }
        case .landscapeRight:
            if devicePosition == .back {
                return UIImage.Orientation.down
            }
            else {
                return UIImage.Orientation.up
            }
        default:
            return UIImage.Orientation.up
        }
    }
}
