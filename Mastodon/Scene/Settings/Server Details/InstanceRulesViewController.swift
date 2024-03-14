// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonSDK
import SwiftUI

protocol InstanceRulesViewControllerDelegate: AnyObject {

}

struct InstanceRulesView: View {
    
    var rulesView = MastodonServerRulesView()
    
    var body: some View {
        rulesView
            .padding([.top], 16)
    }
}

class InstanceRulesViewController: UIHostingController<InstanceRulesView> {

    init() {
        super.init(rootView: InstanceRulesView())
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(with instance: Mastodon.Entity.V2.Instance) {
        self.rootView.rulesView.viewModel = .init(
            disclaimer: nil,
            rules: instance.rules?.map({ $0.text }) ?? [],
            onAgree: nil,
            onDisagree: nil
        )
    }
}
