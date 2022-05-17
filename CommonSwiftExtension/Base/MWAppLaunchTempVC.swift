//
//  MWAppLaunchTempVC.swift
//  MWWaterMarkCamera
//
//  Created by Horizon on 26/1/2022.
//

import UIKit

class MWAppLaunchTempVC: MWBaseViewController {

    
    // MARK: - properties
    private(set) var privacyModule: PrivacyAlertViewModule?
    private(set) var rootVC: UIViewController
    
    
    // MARK: - view life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        setupPrivacyModule()
    }

    // MARK: - init
    init(_ vc: UIViewController) {
        self.rootVC = vc
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setupPrivacyModule() {
        privacyModule = PrivacyAlertViewModule(self)
        privacyModule?.show(title: "隐私政策",
                            desc: "在使用水印相机前，请务必仔细阅读并同意《用户服务协议和隐私政策》。您可以选择不使用水印相机，但如果您使用水印相机，您的使用行为即表示您知悉、理解并同意接受本协议的全部内容",
                            highlightStr: "《用户服务协议和隐私政策》",
                            leftBtnStr: "不同意",
                            rightBtnStr: "知晓并同意")
        privacyModule?.actionCallback = { [weak self] index in
            if self == nil {
                return
            }
            if index == 1 {
                UserDefaults.standard.setValue("1", forKey: kIsAgreePrivacyPolicy)
                self?.privacyModule?.hide()
                let nc = MWNavigationController(rootViewController: self!.rootVC)
                UIApplication.shared.keyWindow?.rootViewController = nc
            }
            else {
                exit(0)
            }
        }
    }
    
    // MARK: - utils
    
    
    // MARK: - action
    
    
    // MARK: - other
    


}
