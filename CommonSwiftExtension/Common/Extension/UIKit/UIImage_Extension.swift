//
//  UIImage_Extension.swift
//  MWWaterMarkCamera
//
//  Created by MorganWang on 17/1/2022.
//

import Foundation
import UIKit
import AVFoundation
import Photos

extension UIImage {
    
    func resizeImage(to targetSize: CGSize) -> UIImage? {
        var actualH: CGFloat = CGFloat(self.size.height)
        var actualW: CGFloat = CGFloat(self.size.width)
        var imgRatio: CGFloat = actualW / actualH
        let maxRatio: CGFloat = targetSize.width / targetSize.height
        if actualH > targetSize.height || actualW > targetSize.width {
            if imgRatio < maxRatio {
                // adjust width according to maxH
                imgRatio = targetSize.height / actualH
                actualW = imgRatio * actualW
                actualH = targetSize.height
            }
            else if imgRatio > maxRatio {
                // adjust height according to maxW
                imgRatio = targetSize.width / actualW
                actualH = imgRatio * actualH
                actualW = targetSize.width
            }
            else {
                actualW = targetSize.width
                actualH = targetSize.height
            }
        }
        
        UIGraphicsBeginImageContext(CGSize(width: actualW, height: actualH))
        draw(in: CGRect(x: 0.0, y: 0.0, width: actualW, height: actualH))
        let img = UIGraphicsGetImageFromCurrentImageContext()
        let resultImg = img?.compressToTargetMbSize(1)
        UIGraphicsEndImageContext()
        return resultImg
    }
    
    func compressToTargetMbSize(_ expectedSizeInMb: Int) -> UIImage? {
        let sizeInBytes = expectedSizeInMb * 1024 * 1024
        var needCompress: Bool = true
        var imgData: Data?
        var compressValue: CGFloat = 1.0
        while (needCompress && compressValue > 0.0) {
            if let data = self.jpegData(compressionQuality: compressValue) {
                if data.count < sizeInBytes {
                    needCompress = false
                    imgData = data
                } else {
                    compressValue -= 0.1
                }
            }
        }
        
        if let data = imgData {
            if data.count < sizeInBytes {
                return UIImage(data: data)
            }
        }
        return nil
    }
    
    static func getSavedImage(named: String) -> UIImage? {
        if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            return UIImage(contentsOfFile: URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(named).path)
        }
        return nil
    }
    
    static func saveImageToFile(_ timage: UIImage?, name: String) -> Bool {
        guard let image = timage else {
            return false
        }

        guard let data = image.pngData() else {
            return false
        }
        guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
            return false
        }
        do {
            print(directory)
            let saveName = name + ".png"
            try data.write(to: directory.appendingPathComponent(saveName)!)
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }

    
    func tailoring(in area: CGRect) -> UIImage? {
        let editSize = area.size
        let ratio = 1.0
        let width = ratio * editSize.width
        let height = ratio * editSize.height
        let x = -(area.origin.x * ratio)
        let y = -(area.origin.y * ratio)
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0)
        self.draw(at: CGPoint(x: x, y: y))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    class func videoSaveToSystemPhotoLibrary(url: URL, completion: ((Bool) -> Void)?) {
        UIDevice.grantedPhotoAuthorization { granted in
            if granted {
                PHPhotoLibrary.shared().performChanges {
                    let _ = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                } completionHandler: { success, error in
                    completion?(success)
                }
            }
            else {
                UIDevice.noAuthHandle(with: "尚未获取访问权限，是否前去获取？", on: UIApplication.shared.keyWindow!.rootViewController!)
            }
        }
    }
    
    class func saveToSystemPhotoLibrary(with image: UIImage, completion: ((Bool) -> Void)?) {
        UIDevice.grantedPhotoAuthorization { granted in
            if granted {
                PHPhotoLibrary.shared().performChanges {
                    let _ = PHAssetChangeRequest.creationRequestForAsset(from: image)
                } completionHandler: { success, error in
                    completion?(success)
                }
            }
            else {
                UIDevice.noAuthHandle(with: "尚未获取相机访问权限，是否前去获取？", on: UIApplication.shared.keyWindow!.rootViewController!)
            }
        }
    }
    
    class func saveToPhotoLibrary(with image: UIImage, completion: ((Bool) -> Void)?) {
        UIImage.saveToSystemPhotoLibrary(with: image, completion: completion)
    }
    
    class func fixOrientation(_ aImage: UIImage) -> UIImage {
        let imageOrientation = aImage.imageOrientation
        if imageOrientation == .up {
            // No-op if the orientation is already correct
            return aImage
        }
        
        // We need to calculate the proper transformation to make the image upright.
        // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
        var transform = CGAffineTransform.identity
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: aImage.size.width, y: aImage.size.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: aImage.size.width, y: 0)
            transform = transform.rotated(by: .pi/2.0)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: aImage.size.height)
            transform = transform.rotated(by: -.pi/2.0)
        default:
            break
        }
        
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: aImage.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: aImage.size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        guard let ctx = CGContext(data: nil,
                            width: Int(aImage.size.width),
                            height: Int(aImage.size.height),
                            bitsPerComponent: aImage.cgImage!.bitsPerComponent,
                            bytesPerRow: 0,
                            space: aImage.cgImage!.colorSpace!,
                                  bitmapInfo: aImage.cgImage!.bitmapInfo.rawValue) else {
            return aImage
        }
        ctx.concatenate(transform)
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx.draw(aImage.cgImage!, in: CGRect(x: 0.0, y: 0.0, width: aImage.size.height, height: aImage.size.width))
        default:
            ctx.draw(aImage.cgImage!, in: CGRect(x: 0.0, y: 0.0, width: aImage.size.width, height: aImage.size.height))
            break
        }
        
        // And now we just create a new UIImage from the drawing context
        let cgImage = ctx.makeImage()
        let image = UIImage(cgImage: cgImage!)
        return image
    }
    
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
    
    func draw(waterMarkImage: UIImage, margin: CGPoint, alpha: CGFloat = 1.0) -> UIImage? {
        let imageSize = self.size
                
        var waterMarkImageW = waterMarkImage.size.width
        var waterMarkImageH = waterMarkImage.size.height
        let waterMarkImageRatio = waterMarkImageW / waterMarkImageH
        var marginY = margin.y
        var marginX = margin.x
        
        let tempScaleW = imageSize.width / MWScreenWidth
        let tempScaleY = imageSize.height / (MWScreenHeight)
        
        waterMarkImageW = waterMarkImageW * tempScaleW
        waterMarkImageH = waterMarkImageW / waterMarkImageRatio
        marginY = marginY * tempScaleY
        marginX = marginX * tempScaleW
        
        var maskFrame = CGRect(x: 0.0, y: 0.0, width: waterMarkImageW, height: waterMarkImageH)
        maskFrame.origin = CGPoint(x: marginX, y: marginY)
        
        // 开始绘制给图片添加图片
        return draw(waterMarkImage: waterMarkImage, maskFrame: maskFrame, alpha: 1.0)
    }
    
    func draw(waterMarkImage: UIImage, maskFrame: CGRect, alpha: CGFloat = 1.0) -> UIImage? {
        let imageSize = self.size
        // 开始绘制给图片添加图片
        UIGraphicsBeginImageContext(imageSize)
        draw(in: CGRect(x: 0.0, y: 0.0, width: imageSize.width, height: imageSize.height))
        waterMarkImage.draw(in: maskFrame, blendMode: .normal, alpha: alpha)
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resultImage
    }
    
    /// 图片加水印
    ///
    /// - Parameters:
    ///   - text: 水印完整文字
    ///   - textColor: 文字颜色
    ///   - textFont: 文字大小
    ///   - suffixText: 尾缀文字(如果是nil可以不传)
    ///   - suffixFont: 尾缀文字大小(如果是nil可以不传)
    ///   - suffixColor: 尾缀文字颜色(如果是nil可以不传)
    /// - Returns: 水印图片
    func drawTextInImage(text: String, textColor: UIColor, textFont: UIFont,suffixText: String?, suffixFont: UIFont?, suffixColor: UIColor?) -> UIImage {
        // 开启和原图一样大小的上下文（保证图片不模糊的方法）
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        
        // 图形重绘
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        
        var suffixAttr: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor:textColor, NSAttributedString.Key.font:textFont]
        let attrS = NSMutableAttributedString(string: text, attributes: suffixAttr)
        
        // 添加后缀的属性字符串
        if let suffixStr = suffixText {
            let range = NSRange(location: text.count - suffixStr.count, length: suffixStr.count)
            if suffixFont != nil {
                suffixAttr[NSAttributedString.Key.font] = suffixFont
            }
            
            if suffixColor != nil {
                suffixAttr[NSAttributedString.Key.foregroundColor] = suffixColor
            }
            attrS.addAttributes(suffixAttr, range: range)
        }
        
        // 文字属性
        let size =  attrS.size()
        let x = (self.size.width - size.width) / 2
        let y = (self.size.height - size.height) / 2
        
        // 绘制文字
        attrS.draw(in: CGRect(x: x, y: y, width: size.width, height: size.height))
        // 从当前上下文获取图片
        let image = UIGraphicsGetImageFromCurrentImageContext()
        //关闭上下文
        UIGraphicsEndImageContext()
        
        return image!
    }
}
