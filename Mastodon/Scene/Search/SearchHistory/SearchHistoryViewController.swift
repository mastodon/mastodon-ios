//
//  SearchHistoryViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-13.
//

import UIKit

final class SearchHistoryViewController: UIViewController, NeedsDependency {
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
}

extension SearchHistoryViewController {

}
