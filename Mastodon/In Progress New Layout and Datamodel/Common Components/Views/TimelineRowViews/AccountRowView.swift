// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonSDK

struct AccountRowView: View {
    let account: MastodonAccount
    
    var body: some View {
        Text("ACCOUNT: \(account.displayInfo.displayName)")
    }
}

