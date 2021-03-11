//
//  ComposeViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

import os.log
import UIKit
import Combine
import TwitterTextEditor

final class ComposeViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ComposeViewModel!
    
    let tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.register(ComposeRepliedToTootContentTableViewCell.self, forCellReuseIdentifier: String(describing: ComposeRepliedToTootContentTableViewCell.self))
        tableView.register(ComposeTootContentTableViewCell.self, forCellReuseIdentifier: String(describing: ComposeTootContentTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        return tableView
    }()
    
}

extension ComposeViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = Asset.Colors.Background.systemBackground.color
        viewModel.title
            .receive(on: DispatchQueue.main)
            .sink { [weak self] title in
                guard let self = self else { return }
                self.title = title
            }
            .store(in: &disposeBag)
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: L10n.Common.Controls.Actions.cancel, style: .plain, target: self, action: #selector(ComposeViewController.cancelBarButtonItemPressed(_:)))
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        tableView.delegate = self
        viewModel.setupDiffableDataSource(for: tableView)
        

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Fix AutoLayout conflict issue
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.markTextViewEditorBecomeFirstResponser()
        }
    }
    
}

extension ComposeViewController {
    private func markTextViewEditorBecomeFirstResponser() {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let items = diffableDataSource.snapshot().itemIdentifiers
        for item in items {
            switch item {
            case .toot:
                guard let indexPath = diffableDataSource.indexPath(for: item),
                      let cell = tableView.cellForRow(at: indexPath) as? ComposeTootContentTableViewCell else {
                    continue
                }
                cell.textEditorView.isEditing = true
                return
            default:
                continue
            }
        }
    }
}

extension ComposeViewController {

    @objc private func cancelBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - TextEditorViewTextAttributesDelegate
extension ComposeViewController: TextEditorViewTextAttributesDelegate {
    
    func textEditorView(_ textEditorView: TextEditorView, updateAttributedString attributedString: NSAttributedString, completion: @escaping (NSAttributedString?) -> Void) {
        // TODO:
    }
    
}

// MARK: - UITableViewDelegate
extension ComposeViewController: UITableViewDelegate {
    
}

// MARK: - ComposeViewController
extension ComposeViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return viewModel.shouldDismiss.value
    }
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
