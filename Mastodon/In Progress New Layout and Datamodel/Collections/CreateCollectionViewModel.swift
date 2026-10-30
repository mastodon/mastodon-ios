// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonCore
import MastodonLocalization

enum CreateCollectionStep: Int, CaseIterable {
    case addAccounts = 1
    case details
}

extension View {
    func createCollectionPageTitle(forStep step: CreateCollectionStep) -> some View {
        self
            .navigationTitle(L10nLookup.Scene.CreateCollection.title, withSubtitle: L10nLookup.Scene.CreateCollection.stepNumber(step.rawValue, ofTotal: CreateCollectionStep.allCases.count))
            .toolbarTitleDisplayMode(.inline)
    }
}

@MainActor
@Observable class CreateCollectionViewModel {
    let authBox: MastodonAuthenticationBox
    
    init(authBox: MastodonAuthenticationBox) {
        self.authBox = authBox
    }
}
