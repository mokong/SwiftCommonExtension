//
//  MWLocalizedStringUtil.swift
//  MWBase
//
//  Created by MorganWang on 10/2/2022.
//

import Foundation
import LanguageManager_iOS

struct MWLocalizedStringUtil {
    var key: String
    
    init(_ key: String) {
        self.key = key
    }
    
    func reslove() -> String {
        guard let bundle = Bundle.main.path(forResource: LanguageManager.shared.currentLanguage.rawValue, ofType: "lproj") else {
            return NSLocalizedString(key, comment: "")
        }
        
        let langBundle = Bundle(path: bundle)
        return NSLocalizedString(key, tableName: nil, bundle: langBundle!, value: key, comment: "")
    }
}

extension MWLocalizedStringUtil: ExpressibleByStringLiteral {
    init(stringLiteral value: StringLiteralType) {
        key = value
    }
}
