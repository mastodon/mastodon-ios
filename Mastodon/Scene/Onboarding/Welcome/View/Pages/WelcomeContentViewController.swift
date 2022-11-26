//
//  WelcomeContentViewController.swift
//  Mastodon
//
//  Created by Nathan Mattes on 26.11.22.
//

import UIKit

class WelcomeContentViewController: UIViewController {

  let page: WelcomeContentPage
  var contentView: WelcomeContentPageView {
    view as! WelcomeContentPageView
  }

  init(page: WelcomeContentPage) {
    self.page = page
    super.init(nibName: nil, bundle: nil)
  }

  override func loadView() {
    let pageView = WelcomeContentPageView(page: page)
    self.view = pageView
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
