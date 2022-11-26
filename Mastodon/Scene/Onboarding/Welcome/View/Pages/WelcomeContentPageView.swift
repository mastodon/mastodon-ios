//
//  WelcomeContentPageView.swift
//  Mastodon
//
//  Created by Nathan Mattes on 26.11.22.
//

import UIKit

class WelcomeContentPageView: UIView {

  //TODO: Put in ScrollView?
  private let contentStackView: UIStackView
  private let titleView: UILabel
  private let label: UILabel

  init(page: WelcomeContentPage) {

    //TODO: @zeitschlag Decide based on page which titleView, first page has mastodon-logo in it
    //TODO: @zeitschlag Add styling
    titleView = UILabel()
    titleView.text = page.title

    //TODO: @zeitschlag Add styling
    label = UILabel()
    label.text = page.content
    label.numberOfLines = 0

    contentStackView = UIStackView(arrangedSubviews: [titleView, label, UIView()])
    contentStackView.translatesAutoresizingMaskIntoConstraints = false
    contentStackView.axis = .vertical
    contentStackView.alignment = .leading

    super.init(frame: .zero)

    addSubview(contentStackView)

    setupConstraints()
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  private func setupConstraints() {
    let constraints = [
      contentStackView.topAnchor.constraint(equalTo: topAnchor),
      contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: 16),
      bottomAnchor.constraint(equalTo: contentStackView.bottomAnchor)
    ]

    NSLayoutConstraint.activate(constraints)
  }
}
