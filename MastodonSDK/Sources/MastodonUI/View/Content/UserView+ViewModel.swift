//
//  UserView+ViewModel.swift
//  
//
//  Created by MainasuK on 2022-1-19.
//

import UIKit
import Combine
import MetaTextKit
import MastodonCore
import MastodonMeta
import MastodonAsset
import MastodonLocalization
import MastodonSDK

extension UserView {
    public final class ViewModel: ObservableObject {
        @Published public var account: Mastodon.Entity.Account?
        @Published public var relationship: Mastodon.Entity.Relationship?
    }
}

extension UserView.ViewModel {
    private static var metricFormatter = MastodonMetricFormatter()
}
