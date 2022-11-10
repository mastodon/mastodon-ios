//
//  MastodonLoginView.swift
//  Mastodon
//
//  Created by Nathan Mattes on 10.11.22.
//

import UIKit
import MastodonAsset

class MastodonLoginView: UIView {

  // Title, Subtitle
  // SearchBox, queries api.joinmastodon.org/servers with domain
  // List with (filtered) domains

  let navigationActionView: NavigationActionView

  override init(frame: CGRect) {
    navigationActionView = NavigationActionView()
    navigationActionView.translatesAutoresizingMaskIntoConstraints = false

    super.init(frame: frame)

    addSubview(navigationActionView)
    backgroundColor = .systemBackground

    setupConstraints()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupConstraints() {
    let constraints = [
      navigationActionView.leadingAnchor.constraint(equalTo: leadingAnchor),
      navigationActionView.trailingAnchor.constraint(equalTo: trailingAnchor),
      bottomAnchor.constraint(equalTo: navigationActionView.bottomAnchor),
    ]
    NSLayoutConstraint.activate(constraints)
  }

}
