//
//  ProfileSegmentedViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-29.
//

import os.log
import UIKit

final class ProfileSegmentedViewController: UIViewController {
    let pagingViewController = ProfilePagingViewController()
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
}

extension ProfileSegmentedViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear

        addChild(pagingViewController)
        pagingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pagingViewController.view)
        pagingViewController.didMove(toParent: self)
        NSLayoutConstraint.activate([
            pagingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            pagingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: pagingViewController.view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: pagingViewController.view.bottomAnchor),
        ])
    }
    
}
