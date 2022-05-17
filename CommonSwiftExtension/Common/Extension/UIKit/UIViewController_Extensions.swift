//
//  UIViewController_Extensions.swift
//  meijuplay
//
//  Created by Horizon on 22/12/2021.
//

import Foundation
import UIKit

extension UIViewController {
    var topBarHeight: CGFloat {
        var top = self.navigationController?.navigationBar.frame.height ?? 0.0
        top += UIDevice.statusBarH()
        return top
    }
    
    
    static func navBarColor() -> UIColor {
        return UIColor.MWCustomColor.navigationBar1
    }

}
