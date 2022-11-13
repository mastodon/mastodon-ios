//
//  MastodonLoginView.swift
//  Mastodon
//
//  Created by Nathan Mattes on 10.11.22.
//

import UIKit
import MastodonAsset

class MastodonLoginView: UIView {

  // List with (filtered) domains

  let titleLabel: UILabel
  let subtitleLabel: UILabel
  private let headerStackView: UIStackView
  let searchTextField: UITextField
  let tableView: UITableView
  private var tableViewWrapper: UIView
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

    searchTextField = UITextField()
    searchTextField.translatesAutoresizingMaskIntoConstraints = false
    searchTextField.backgroundColor = Asset.Scene.Onboarding.textFieldBackground.color
    searchTextField.placeholder = "Search for your server" //TODO: @zeitschlag Localization
    searchTextField.leftView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
    searchTextField.leftViewMode = .always
    searchTextField.layer.cornerRadius = 10

    tableView = ContentSizedTableView()
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.backgroundColor = Asset.Scene.Onboarding.textFieldBackground.color

    tableViewWrapper = UIView()
    tableViewWrapper.translatesAutoresizingMaskIntoConstraints = false
    tableViewWrapper.backgroundColor = .clear
    tableViewWrapper.layer.cornerRadius = 10
    tableViewWrapper.layer.masksToBounds = true
    tableViewWrapper.addSubview(tableView)

    navigationActionView = NavigationActionView()
    navigationActionView.translatesAutoresizingMaskIntoConstraints = false

    super.init(frame: frame)

    addSubview(headerStackView)
    addSubview(searchTextField)
    addSubview(tableViewWrapper)
    addSubview(navigationActionView)
    backgroundColor = Asset.Scene.Onboarding.background.color

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

      searchTextField.topAnchor.constraint(equalTo: headerStackView.bottomAnchor, constant: 32),
      searchTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      searchTextField.heightAnchor.constraint(equalToConstant: 55),
      trailingAnchor.constraint(equalTo: searchTextField.trailingAnchor, constant: 16),

      tableViewWrapper.topAnchor.constraint(equalTo: searchTextField.bottomAnchor),
      tableViewWrapper.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      trailingAnchor.constraint(equalTo: tableViewWrapper.trailingAnchor, constant: 16),
      tableViewWrapper.bottomAnchor.constraint(lessThanOrEqualTo: navigationActionView.topAnchor),

      tableView.topAnchor.constraint(equalTo: tableViewWrapper.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: tableViewWrapper.leadingAnchor),
      tableViewWrapper.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
      tableViewWrapper.bottomAnchor.constraint(greaterThanOrEqualTo: tableView.bottomAnchor),

      navigationActionView.leadingAnchor.constraint(equalTo: leadingAnchor),
      navigationActionView.trailingAnchor.constraint(equalTo: trailingAnchor),
      bottomAnchor.constraint(equalTo: navigationActionView.bottomAnchor),
    ]
    NSLayoutConstraint.activate(constraints)
  }

  func updateCorners(numberOfResults: Int = 0) {

    tableView.isHidden = (numberOfResults == 0)
    tableViewWrapper.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner] // tableViewMask

    let maskedCorners: CACornerMask

    if numberOfResults == 0 {
      maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
    } else {
      maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }

    searchTextField.layer.maskedCorners = maskedCorners
  }
}
