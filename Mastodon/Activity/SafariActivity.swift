//
//  SafariActivity.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-8.
//

import UIKit
import SafariServices
import MastodonAsset
import MastodonLocalization

final class SafariActivity: UIActivity {
    
    weak var sceneCoordinator: SceneCoordinator?
    var presentScene: ((SceneCoordinator.Scene, SceneCoordinator.Transition) async ->())?
    var url: NSURL?
    
    init(sceneCoordinator: SceneCoordinator? = nil, presentScene: ((SceneCoordinator.Scene, SceneCoordinator.Transition)->())? = nil) {
        guard (sceneCoordinator != nil) || (presentScene != nil) else { assertionFailure("no method to show a scene"); return }
        self.sceneCoordinator = sceneCoordinator
        self.presentScene = presentScene
    }
    
    override var activityType: UIActivity.ActivityType? {
        return UIActivity.ActivityType("org.joinmastodon.app.safari-activity")
    }
    
    override var activityTitle: String? {
        return UserDefaults.shared.preferredUsingDefaultBrowser ? L10n.Common.Controls.Actions.openInBrowser : L10n.Common.Controls.Actions.openInSafari
    }
    
    override var activityImage: UIImage? {
        return UIImage(systemName: "safari")
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        for item in activityItems {
            guard let _ = item as? NSURL, sceneCoordinator != nil else { continue }
            return true
        }
        
        return false
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        for item in activityItems {
            guard let url = item as? NSURL else { continue }
            self.url = url
        }
    }
    
    override var activityViewController: UIViewController? {
        return nil
    }
    
    override func perform() {
        guard let url = url else {
            activityDidFinish(false)
            return
        }
    }
    
}
