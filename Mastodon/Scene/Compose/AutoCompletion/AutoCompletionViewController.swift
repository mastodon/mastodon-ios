//
//  AutoCompletionViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-14.
//

import UIKit

final class AutoCompletionViewController: UIViewController {

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    
}

extension AutoCompletionViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .red.withAlphaComponent(0.5)
    }
    
}
