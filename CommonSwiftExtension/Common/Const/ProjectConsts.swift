//
//  ProjectConsts.swift
//  meijuplay
//
//  Created by Horizon on 8/12/2021.
//

import Foundation
import UIKit
import CryptoSwift

/// 屏幕宽度
let MWScreenWidth = UIScreen.main.bounds.size.width

/// 屏幕高度
let MWScreenHeight = UIScreen.main.bounds.size.height

/// 用户界面类型
let MWInterfaceIdiom = UIDevice.current.userInterfaceIdiom

/// 是否同意隐私协议
let kIsAgreePrivacyPolicy = "kIsAgreePrivacyPolicy"

class ProjectConsts {
    // MARK: - properties
    static let shared = ProjectConsts()
    
    
    // MARK: - action
    
    /// aes 加密
    func AESEncrypt(with str: String) -> String {
        //使用AES-128-CBC加密模式
        do {
            let aes = try AES(key: AESKeyStr.bytes, blockMode: CBC(iv: AESIVStr.bytes))
            // 开始加密
            let encrypted = try aes.encrypt(str.bytes)
            // 将加密结果转成 base64形式
            let encryptedBase64 = encrypted.toBase64()
            print("加密结果(base64): \(encryptedBase64)")
            return encryptedBase64
        }
        catch {
            print("error")
            return ""
        }
    }
    
    /// aes 解密
    func AESDecrypt(with str: String) -> String {
        //使用AES-128-CBC加密模式
        do {
            let aes = try AES(key: AESKeyStr.bytes, blockMode: CBC(iv: AESIVStr.bytes))
            // 开始解密
            let decrypted = try str.decryptBase64ToString(cipher: aes)
            print("解密结果：\(decrypted)")
            return decrypted
        }
        catch {
            print("error")
            return ""
        }
    }
    
    // MARK: - other
    

}
