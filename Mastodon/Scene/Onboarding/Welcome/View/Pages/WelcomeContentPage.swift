//
//  WelcomeContentPage.swift
//  Mastodon
//
//  Created by Nathan Mattes on 26.11.22.
//

import UIKit

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
        return "What is Mastodon?"
      case .mastodonIsLikeThat:
        return "Mastodon is like that"
      case .howDoIPickAServer:
        return "How to I pick a server?"
    }
  }

  var content: String {
    switch self {
      case .whatIsMastodon:
        return "Long text\n\nhat is Mastodon?"
      case .mastodonIsLikeThat:
        return "Long text\n\nwhat Mastodon is like"
      case .howDoIPickAServer:
        return "Long text\n\nHow to I pick a server?"
    }

  }
}
