// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonSDK
import MastodonCore
import MastodonAsset
import MastodonLocalization

enum NotificationRequestsSection: Hashable {
    case main
}

enum NotificationRequestItem: Hashable {
    case item(Mastodon.Entity.NotificationRequest)
}

protocol NotificationRequestsTableViewControllerDelegate: AnyObject {
    func notificationRequestsUpdated(_ viewController: NotificationRequestsTableViewController)
}

class NotificationRequestsTableViewController: UIViewController {

    weak var delegate: NotificationRequestsTableViewControllerDelegate?

    let tableView: UITableView
    var viewModel: NotificationRequestsViewModel
    var dataSource: UITableViewDiffableDataSource<NotificationRequestsSection, NotificationRequestItem>?

    init(viewModel: NotificationRequestsViewModel) {

        self.viewModel = viewModel

        tableView = UITableView(frame: .zero)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .secondarySystemBackground
        tableView.register(NotificationRequestTableViewCell.self, forCellReuseIdentifier: NotificationRequestTableViewCell.reuseIdentifier)

        super.init(nibName: nil, bundle: nil)

        view.addSubview(tableView)
        tableView.pinToParent()

        let dataSource = UITableViewDiffableDataSource<NotificationRequestsSection, NotificationRequestItem>(tableView: tableView) { tableView, indexPath, itemIdentifier in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: NotificationRequestTableViewCell.reuseIdentifier, for: indexPath) as? NotificationRequestTableViewCell else {
                assertionFailure("unexpected cell dequeued")
                return nil
            }

            let request = viewModel.requests[indexPath.row]
            cell.configure(with: request)
            cell.delegate = self

            return cell
        }

        tableView.dataSource = dataSource
        tableView.delegate = self
        self.dataSource = dataSource

        title = L10n.Scene.Notification.FilteredNotification.title
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        var snapshot = NSDiffableDataSourceSnapshot<NotificationRequestsSection, NotificationRequestItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(viewModel.requests.compactMap { NotificationRequestItem.item($0) } )

        dataSource?.apply(snapshot)
    }
}

// MARK: - UITableViewDelegate
extension NotificationRequestsTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let request = viewModel.requests[indexPath.row]

        Task { [weak self] in
            guard let self else { return }

            let viewController = await DataSourceFacade.coordinateToNotificationRequest(request: request, provider: self)
            viewController?.delegate = self
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let dismissAction = UIContextualAction(style: .normal, title: "Dismiss") { [weak self] action, view, completion in
            guard let request = self?.viewModel.requests[indexPath.row], let cell = tableView.cellForRow(at: indexPath) as? NotificationRequestTableViewCell else { return completion(false) }

            self?.rejectNotificationRequest(cell, notificationRequest: request)
            completion(true)
        }

        dismissAction.image = NotificationRequestConstants.dismissIcon

        let swipeAction = UISwipeActionsConfiguration(actions: [dismissAction])
        swipeAction.performsFirstActionWithFullSwipe = true
        return swipeAction

    }
}

// MARK: - AuthContextProvider
extension NotificationRequestsTableViewController: AuthContextProvider {
    var authenticationBox: MastodonAuthenticationBox { viewModel.authenticationBox }
}

extension NotificationRequestsTableViewController: NotificationRequestTableViewCellDelegate {
    func acceptNotificationRequest(_ cell: NotificationRequestTableViewCell, notificationRequest: MastodonSDK.Mastodon.Entity.NotificationRequest) {

        cell.acceptNotificationRequestActivityIndicatorView.isHidden = false
        cell.acceptNotificationRequestActivityIndicatorView.startAnimating()
        cell.acceptNotificationRequestButton.tintColor = .clear
        cell.acceptNotificationRequestButton.setTitleColor(.clear, for: .normal)
        cell.rejectNotificationRequestButton.isUserInteractionEnabled = false
        cell.acceptNotificationRequestButton.isUserInteractionEnabled = false

        Task { [weak self] in
            guard let self else { return }
            do {
                try await acceptNotificationRequest(notificationRequest)
            } catch {
                cell.acceptNotificationRequestActivityIndicatorView.stopAnimating()
                cell.acceptNotificationRequestButton.tintColor = .white
                cell.acceptNotificationRequestButton.setTitleColor(.white, for: .normal)
                cell.rejectNotificationRequestButton.isUserInteractionEnabled = true
                cell.acceptNotificationRequestButton.isUserInteractionEnabled = true
            }
        }
    }

    private func acceptNotificationRequest(_ notificationRequest: MastodonSDK.Mastodon.Entity.NotificationRequest) async throws {
        _ = try await APIService.shared.acceptNotificationRequests(authenticationBox: authenticationBox,
                                                                    id: notificationRequest.id)

        let requests = try await APIService.shared.notificationRequests(authenticationBox: authenticationBox).value

        NotificationCenter.default.post(name: .notificationFilteringChanged, object: nil)

        await MainActor.run { [weak self] in
            guard let self else { return }

            if requests.count > 0 {
                self.viewModel.requests = requests
                var snapshot = NSDiffableDataSourceSnapshot<NotificationRequestsSection, NotificationRequestItem>()
                snapshot.appendSections([.main])
                snapshot.appendItems(self.viewModel.requests.compactMap { NotificationRequestItem.item($0) } )

                self.dataSource?.apply(snapshot)
            } else {
                _ = self.navigationController?.popViewController(animated: true)
            }
        }
    }

    func rejectNotificationRequest(_ cell: NotificationRequestTableViewCell, notificationRequest: MastodonSDK.Mastodon.Entity.NotificationRequest) {

        cell.rejectNotificationRequestActivityIndicatorView.isHidden = false
        cell.rejectNotificationRequestActivityIndicatorView.startAnimating()
        cell.rejectNotificationRequestButton.tintColor = .clear
        cell.rejectNotificationRequestButton.setTitleColor(.clear, for: .normal)
        cell.rejectNotificationRequestButton.isUserInteractionEnabled = false
        cell.acceptNotificationRequestButton.isUserInteractionEnabled = false

        Task { [weak self] in
            guard let self else { return }
            do {
                try await rejectNotificationRequest(notificationRequest)
            } catch {
                cell.rejectNotificationRequestActivityIndicatorView.stopAnimating()
                cell.rejectNotificationRequestButton.tintColor = .black
                cell.rejectNotificationRequestButton.setTitleColor(.black, for: .normal)
                cell.rejectNotificationRequestButton.isUserInteractionEnabled = true
                cell.acceptNotificationRequestButton.isUserInteractionEnabled = true
            }
        }
    }
    
    private func rejectNotificationRequest(_ notificationRequest: MastodonSDK.Mastodon.Entity.NotificationRequest) async throws {
        _ = try await APIService.shared.rejectNotificationRequests(authenticationBox: authenticationBox,
                                                                    id: notificationRequest.id)
        
        let requests = try await APIService.shared.notificationRequests(authenticationBox: authenticationBox).value
        
        NotificationCenter.default.post(name: .notificationFilteringChanged, object: nil)
        
        await MainActor.run { [weak self] in
            guard let self else { return }
            
            if requests.count > 0 {
                self.viewModel.requests = requests
                var snapshot = NSDiffableDataSourceSnapshot<NotificationRequestsSection, NotificationRequestItem>()
                snapshot.appendSections([.main])
                snapshot.appendItems(self.viewModel.requests.compactMap { NotificationRequestItem.item($0) } )
                
                self.dataSource?.apply(snapshot)
            } else {
                _ = self.navigationController?.popViewController(animated: true)
            }
        }
    }
}

extension NotificationRequestsTableViewController: AccountNotificationTimelineViewControllerDelegate {
    func acceptRequest(_ viewController: AccountNotificationTimelineViewController, request: MastodonSDK.Mastodon.Entity.NotificationRequest) {
        Task {
            try? await acceptNotificationRequest(request)
        }
    }
    
    func dismissRequest(_ viewController: AccountNotificationTimelineViewController, request: MastodonSDK.Mastodon.Entity.NotificationRequest) {
        Task {
            try? await rejectNotificationRequest(request)
        }
    }
}
