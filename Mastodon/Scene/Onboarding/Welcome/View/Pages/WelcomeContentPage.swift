//
//  WelcomeContentPage.swift
//  Mastodon
//
//  Created by Nathan Mattes on 26.11.22.
//

import UIKit
import MastodonLocalization

enum WelcomeContentPage: CaseIterable {
  case whatIsMastodon
  case mastodonIsLikeThat
  case howDoIPickAServer

  var backgroundColor: UIColor {
    switch self {
      case .whatIsMastodon:
        return .green
      case .mastodonIsLikeThat:
        return .red
      case .howDoIPickAServer:
        return .blue
    }
  }

  var title: String {
    switch self {
      case .whatIsMastodon:
        return L10n.Scene.Welcome.Education.WhatIsMastodon.title
      case .mastodonIsLikeThat:
        return L10n.Scene.Welcome.Education.MastodonIsLikeThat.title
      case .howDoIPickAServer:
        return L10n.Scene.Welcome.Education.HowDoIPickAServer.title
    }
  }

  var content: String {
    switch self {
      case .whatIsMastodon:
        return L10n.Scene.Welcome.Education.WhatIsMastodon.description
      case .mastodonIsLikeThat:
        return L10n.Scene.Welcome.Education.MastodonIsLikeThat.description
      case .howDoIPickAServer:
        return L10n.Scene.Welcome.Education.HowDoIPickAServer.description
    }

  }
}
