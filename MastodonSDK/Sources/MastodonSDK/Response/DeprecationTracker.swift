// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import Foundation
import UIKit

@MainActor
@Observable public final class DeprecationTracker {

    public static let shared = DeprecationTracker()

    private var alreadyReported = Set(["/api/v1/instance"])

    private init() {}
    
    public private(set) var mostRecentDeprecation: (Date, String)?

    func didReceiveDeprecation(_ deprecation: Date, endpoint: String) {
        guard UserDefaults.isDebugOrTestflightOrSimulator else { return }

        let isNew = alreadyReported.insert(endpoint).inserted
        guard isNew else { return }

        mostRecentDeprecation = (deprecation, endpoint)
        
        presentDeprecationAlert(deprecation, endpoint: endpoint)
    }
    
    @MainActor
    private func presentDeprecationAlert(_ deprecationDate: Date, endpoint: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        let alertController = UIAlertController(
            title: "Deprecated API in use",
            message: "Endpoint: \(endpoint)\nDeprecated as of: \(dateFormatter.string(from: deprecationDate))",
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
        
        topViewController()?.present(alertController, animated: true)
    }
    
}

@MainActor
private func topViewController() -> UIViewController? {
    
    let scene = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first(where: { $0.activationState == .foregroundActive })
    
    let root = scene?
        .windows
        .first(where: \.isKeyWindow)?
        .rootViewController
    
    var vc = root
    while let presented = vc?.presentedViewController {
        vc = presented
    }
    return vc
}
