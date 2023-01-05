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
    var url: NSURL?
    
    init(sceneCoordinator: SceneCoordinator) {
        self.sceneCoordinator = sceneCoordinator
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
        
        Task {
            _ = await sceneCoordinator?.present(scene: .safari(url: url as URL), from: nil, transition: .safariPresent(animated: true, completion: nil))
            activityDidFinish(true)
        }
    }
    
}
