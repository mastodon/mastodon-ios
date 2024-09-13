// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import Foundation
import SwiftUI
import UIKit
import MastodonSDK

class DonationViewController: UIHostingController<DonationView> {
    init(campaign: Mastodon.Entity.DonationCampaign) {
        super.init(rootView: DonationView(campaign: campaign))
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct DonationView: View {
    let campaign: Mastodon.Entity.DonationCampaign
    
    var body: some View {
        VStack {
            Text(campaign.donationMessage)
        }
    }
}
