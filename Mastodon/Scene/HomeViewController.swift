//
//  HomeViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/1/27.
//

import UIKit

final class HomeViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
}

extension HomeViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Home"
        view.backgroundColor = .systemBackground

    }
}
