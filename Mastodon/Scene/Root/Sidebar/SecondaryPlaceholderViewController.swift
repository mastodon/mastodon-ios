//
//  SecondaryPlaceholderViewController.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-29.
//

import UIKit
import Combine
import MastodonCore

final class SecondaryPlaceholderViewController: UIViewController {
    var disposeBag = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .secondarySystemBackground
    }
    
}
