//
//  ComposeContentViewController.swift
//  
//
//  Created by MainasuK on 22/9/30.
//

import os.log
import UIKit
import SwiftUI

public final class ComposeContentViewController: UIViewController {
    
    let logger = Logger(subsystem: "ComposeContentViewController", category: "ViewController")
    
    public var viewModel: ComposeContentViewModel!
    
    let tableView: ComposeTableView = {
        let tableView = ComposeTableView()
        tableView.alwaysBounceVertical = true
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        return tableView
    }()

    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }

}

extension ComposeContentViewController {
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        tableView.delegate = self
        viewModel.setupDataSource(tableView: tableView)
        
    }
}

// MARK: - UITableViewDelegate
extension ComposeContentViewController: UITableViewDelegate { }

