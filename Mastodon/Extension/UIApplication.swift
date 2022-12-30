//
//  UIApplication.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-2-26.
//

import UIKit

extension UIApplication {

    class func appVersion() -> String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }

    class func appBuild() -> String {
        return Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
    }

    class func versionBuild() -> String {
        let version = appVersion(), build = appBuild()

        return version == build ? "v\(version)" : "v\(version) (\(build))"
    }
    
    func getKeyWindow() -> UIWindow? {
        return UIApplication
            .shared
            .connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .first { $0.isKeyWindow }
    }

}
