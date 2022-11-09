//
//  MastodonLoginViewController.swift
//  Mastodon
//
//  Created by Nathan Mattes on 09.11.22.
//

import UIKit

class MastodonLoginViewController: UIViewController {

    // Title, Subtitle
    // SearchBox, queries api.joinmastodon.org/servers with domain
    // List with (filtered) domains
    // back-button, next-button (enabled if user selectes a server or url is valid
    // next-button does MastodonPickServerViewController.doSignIn()

    init() {
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .systemGreen
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

