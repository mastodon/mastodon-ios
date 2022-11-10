//
//  MastodonLoginView.swift
//  Mastodon
//
//  Created by Nathan Mattes on 10.11.22.
//

import UIKit
import MastodonAsset

class MastodonLoginView: UIView {

  // SearchBox, queries api.joinmastodon.org/servers with domain
  // List with (filtered) domains

  let titleLabel: UILabel
  let subtitleLabel: UILabel
  private let headerStackView: UIStackView
  let navigationActionView: NavigationActionView

  override init(frame: CGRect) {

    titleLabel = UILabel()
    titleLabel.font = MastodonLoginViewController.largeTitleFont
    titleLabel.textColor = MastodonLoginViewController.largeTitleTextColor
    titleLabel.text = "Welcome Back" //TODO: @zeitschlag localization
    titleLabel.numberOfLines = 0

    subtitleLabel = UILabel()
    subtitleLabel.font = MastodonLoginViewController.subTitleFont
    subtitleLabel.textColor = MastodonLoginViewController.subTitleTextColor
    subtitleLabel.text = "Log you in with the server where you created your account" //TODO: @zeitschlag localization
    subtitleLabel.numberOfLines = 0

    headerStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
    headerStackView.axis = .vertical
    headerStackView.spacing = 16
    headerStackView.translatesAutoresizingMaskIntoConstraints = false

    navigationActionView = NavigationActionView()
    navigationActionView.translatesAutoresizingMaskIntoConstraints = false

    super.init(frame: frame)

    addSubview(headerStackView)
    addSubview(navigationActionView)
    backgroundColor = .systemBackground

    setupConstraints()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupConstraints() {
    let constraints = [

      headerStackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
      headerStackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
      headerStackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),

      navigationActionView.leadingAnchor.constraint(equalTo: leadingAnchor),
      navigationActionView.trailingAnchor.constraint(equalTo: trailingAnchor),
      bottomAnchor.constraint(equalTo: navigationActionView.bottomAnchor),
    ]
    NSLayoutConstraint.activate(constraints)
  }

}
