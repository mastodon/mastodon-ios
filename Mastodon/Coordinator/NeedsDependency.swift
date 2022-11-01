//
//  NeedsDependency.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-1-27.
//

import UIKit
import MastodonCore

protocol NeedsDependency: AnyObject {
    var context: AppContext! { get set }
    var coordinator: SceneCoordinator! { get set }
}

extension UISceneSession {
    private struct AssociatedKeys {
        static var sceneCoordinator = "SceneCoordinator"
    }
    
    weak var sceneCoordinator: SceneCoordinator? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.sceneCoordinator) as? SceneCoordinator
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.sceneCoordinator, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}
