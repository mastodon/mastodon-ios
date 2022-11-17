//
//  AutoCompleteViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-14.
//

import os.log
import UIKit
import Combine
import MastodonCore

protocol AutoCompleteViewControllerDelegate: AnyObject {
    func autoCompleteViewController(_ viewController: AutoCompleteViewController, didSelectItem item: AutoCompleteItem)
}

final class AutoCompleteViewController: UIViewController {

    static let chevronViewHeight: CGFloat = 24
    
    var viewModel: AutoCompleteViewModel!
    var disposeBag = Set<AnyCancellable>()
    
    weak var delegate: AutoCompleteViewControllerDelegate?

    let chevronView = AutoCompleteTopChevronView()
    let containerBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeService.shared.currentTheme.value.systemBackgroundColor
        return view
    }()
    
    let tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.register(AutoCompleteTableViewCell.self, forCellReuseIdentifier: String(describing: AutoCompleteTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.contentInset.top = AutoCompleteViewController.chevronViewHeight
        tableView.verticalScrollIndicatorInsets.top = AutoCompleteViewController.chevronViewHeight
        tableView.showsVerticalScrollIndicator = false  // avoid duplicate to the compose collection view indicator
        tableView.preservesSuperviewLayoutMargins = false
        tableView.cellLayoutMarginsFollowReadableWidth = false
        return tableView
    }()
    
}

extension AutoCompleteViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear

        // we hack the view hierarchy. Do not preserve from superview
        view.preservesSuperviewLayoutMargins = false
        
        chevronView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chevronView)
        NSLayoutConstraint.activate([
            chevronView.topAnchor.constraint(equalTo: view.topAnchor),
            chevronView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chevronView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chevronView.heightAnchor.constraint(equalToConstant: AutoCompleteViewController.chevronViewHeight)
        ])
        
        containerBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerBackgroundView)
        NSLayoutConstraint.activate([
            containerBackgroundView.topAnchor.constraint(equalTo: chevronView.topAnchor),
            containerBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        view.bringSubviewToFront(chevronView)
        containerBackgroundView.preservesSuperviewLayoutMargins = true
        containerBackgroundView.isUserInteractionEnabled = true
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        containerBackgroundView.addSubview(tableView)
        tableView.pinToParent()
        
        tableView.delegate = self
        viewModel.setupDiffableDataSource(tableView: tableView)

        // bind to layout chevron
        viewModel.symbolBoundingRect
            .receive(on: DispatchQueue.main)
            .sink { [weak self] symbolBoundingRect in
                guard let self = self else { return }
                self.chevronView.chevronMinX = symbolBoundingRect.midX - 0.5 * AutoCompleteTopChevronView.chevronSize.width
                self.chevronView.setNeedsLayout()
                self.containerBackgroundView.layer.mask = self.chevronView.invertMask(in: self.view.bounds)
            }
            .store(in: &disposeBag)
    }
    
}

// MARK: - UITableViewDelegate
extension AutoCompleteViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: indexPath: %s", ((#file as NSString).lastPathComponent), #line, #function, indexPath.debugDescription)
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        delegate?.autoCompleteViewController(self, didSelectItem: item)
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
