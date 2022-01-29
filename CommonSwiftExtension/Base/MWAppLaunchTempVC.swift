//
//  MWAppLaunchTempVC.swift
//  MWWaterMarkCamera
//
//  Created by Horizon on 26/1/2022.
//

import UIKit

class MWAppLaunchTempVC: MWBaseViewController {

    private(set) var privacyModule: PrivacyAlertViewModule?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        setupPrivacyModule()
    }
    
    fileprivate func setupPrivacyModule() {
        privacyModule = PrivacyAlertViewModule(self)
        privacyModule?.show(title: "隐私政策",
                            desc: "在使用水印相机前，请务必仔细阅读并同意《用户服务协议和隐私政策》。您可以选择不使用水印相机，但如果您使用水印相机，您的使用行为即表示您知悉、理解并同意接受本协议的全部内容",
                            highlightStr: "《用户服务协议和隐私政策》",
                            leftBtnStr: "不同意",
                            rightBtnStr: "知晓并同意")
        privacyModule?.actionCallback = { [weak self] index in
            if index == 1 {
                UserDefaults.standard.setValue("1", forKey: kIsAgreePrivacyPolicy)
                self?.privacyModule?.hide()
                let vc = MWWaterMarkCameraVC()
                let nc = MWNavigationController(rootViewController: vc)
                UIApplication.shared.keyWindow?.rootViewController = nc
            }
            else {
                exit(0)
            }
        }
    }

}
