//
//  ProfileViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-23.
//

import UIKit

final class ProfileViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
}

extension ProfileViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
}
