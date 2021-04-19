//
//  ReportViewModel.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/19.
//

import Combine
import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import UIKit
import os.log

class ReportViewModel: NSObject, NeedsDependency {
    typealias FileReportQuery = Mastodon.API.Reports.FileReportQuery
    
    enum Step: Int {
        case one
        case two
    }
    
    // confirm set only once
    weak var context: AppContext! { willSet { precondition(context == nil) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(coordinator == nil) } }
    var userId: String
    var statusId: String?
    var selectedItems = [Item]()
    var comment: String?
    
    internal var reportQuery: FileReportQuery
    internal var disposeBag = Set<AnyCancellable>()
    internal let currentStep = CurrentValueSubject<Step, Never>(.one)
    internal let statusFetchedResultsController: StatusFetchedResultsController
    internal var diffableDataSource: UITableViewDiffableDataSource<ReportSection, Item>?
    internal let continueEnableSubject = CurrentValueSubject<Bool, Never>(false)
    internal let sendEnableSubject = CurrentValueSubject<Bool, Never>(false)
    internal let reportSuccess = PassthroughSubject<Void, Never>()
    
    struct Input {
        let didToggleSelected: AnyPublisher<Item, Never>
        let comment: AnyPublisher<String?, Never>
        let step1Continue: AnyPublisher<Void, Never>
        let step1Skip: AnyPublisher<Void, Never>
        let step2Continue: AnyPublisher<Void, Never>
        let step2Skip: AnyPublisher<Void, Never>
        let cancel: AnyPublisher<Void, Never>
        let tableView: UITableView
    }

    struct Output {
        let currentStep: AnyPublisher<Step, Never>
        let continueEnableSubject: AnyPublisher<Bool, Never>
        let sendEnableSubject: AnyPublisher<Bool, Never>
        let reportSuccess: AnyPublisher<Void, Never>
    }
    
    init(context: AppContext,
         coordinator: SceneCoordinator,
         domain: String,
         userId: String,
         statusId: String?
    ) {
        self.context = context
        self.coordinator = coordinator
        self.userId = userId
        self.statusId = statusId
        self.statusFetchedResultsController = StatusFetchedResultsController(
            managedObjectContext: context.managedObjectContext,
            domain: domain,
            additionalTweetPredicate: Status.notDeleted()
        )
        
        self.reportQuery = FileReportQuery(
            accountId: userId,
            statusIds: nil,
            comment: nil,
            forward: nil
        )
        super.init()
    }
    
    func transform(input: Input?) -> Output? {
        guard let input = input else { return nil }
        guard let activeMastodonAuthenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else {
            return nil
        }
        let domain = activeMastodonAuthenticationBox.domain
        
        setupDiffableDataSource(
            for: input.tableView,
            dependency: self,
            reportdStatusDelegate: self
        )
        
        // data binding
        bindData(input: input)
        
        // step1 and step2 binding
        bindForStep1(input: input)
        bindForStep2(
            input: input,
            domain: domain,
            activeMastodonAuthenticationBox: activeMastodonAuthenticationBox
        )
        
        requestRecentStatus(
            domain: domain,
            accountId: self.userId,
            authorizationBox: activeMastodonAuthenticationBox
        )
        
        fetchStatus()
        
        return Output(
            currentStep: currentStep.eraseToAnyPublisher(),
            continueEnableSubject: continueEnableSubject.eraseToAnyPublisher(),
            sendEnableSubject: sendEnableSubject.eraseToAnyPublisher(),
            reportSuccess: reportSuccess.eraseToAnyPublisher()
        )
    }
    
    // MARK: - Private methods
    func bindData(input: Input) {
        input.didToggleSelected.sink { [weak self] (item) in
            guard let self = self else { return }
            guard case let .status(objectID, attribute) = item else { return }
            guard var snapshot = self.diffableDataSource?.snapshot() else { return }
            let managedObjectContext = self.statusFetchedResultsController.fetchedResultsController.managedObjectContext
            guard let status = managedObjectContext.object(with: objectID) as? Status else {
                return
            }
            
            var items = [Item]()
            if let index = self.selectedItems.firstIndex(of: item) {
                self.selectedItems.remove(at: index)
                items.append(.status(objectID: objectID, attribute: attribute))
                
                if let index = self.reportQuery.statusIds?.firstIndex(of: status.id) {
                    self.reportQuery.statusIds?.remove(at: index)
                }
            } else {
                self.selectedItems.append(item)
                items.append(.status(objectID: objectID, attribute: attribute))
                self.reportQuery.statusIds?.append(status.id)
            }
            
            snapshot.reloadItems([item])
            self.diffableDataSource?.apply(snapshot, animatingDifferences: false)
            
            let continueEnable = self.selectedItems.count > 0
            self.continueEnableSubject.send(continueEnable)
        }
        .store(in: &disposeBag)
        
        input.comment.assign(
            to: \.comment,
            on: self
        )
        .store(in: &disposeBag)
        input.comment.sink { [weak self] (comment) in
            guard let self = self else { return }
            let sendEnable = (comment?.length ?? 0) > 0
            self.sendEnableSubject.send(sendEnable)
        }
        .store(in: &disposeBag)
    }
    
    func bindForStep1(input: Input) {
        let skip = input.step1Skip.map { [weak self] value -> Void in
            guard let self = self else { return value }
            self.selectedItems.removeAll()
            return value
        }
        
        Publishers.Merge(skip, input.step1Continue)
            .sink { [weak self] _ in
                self?.currentStep.value = .two
                self?.sendEnableSubject.send(false)
            }
            .store(in: &disposeBag)
    }
    
    func bindForStep2(input: Input, domain: String, activeMastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox) {
        let skip = input.step2Skip.map { [weak self] value -> Void in
            guard let self = self else { return value }
            self.comment = nil
            return value
        }
        
        Publishers.Merge(skip, input.step2Continue)
            .sink { [weak self] _ in
                guard let self = self else { return }
                let managedObjectContext = self.statusFetchedResultsController.fetchedResultsController.managedObjectContext
                
                self.reportQuery.comment = self.comment
                
                var selectedStatusIds = [String]()
                self.selectedItems.forEach { (item) in
                    guard case .status(let objectId, _) = item else {
                        return
                    }
                    guard let status = managedObjectContext.object(with: objectId) as? Status else {
                        return
                    }
                    selectedStatusIds.append(status.id)
                }
                self.reportQuery.statusIds = selectedStatusIds
                
                self.context.apiService.report(
                    domain: domain,
                    query: self.reportQuery,
                    mastodonAuthenticationBox: activeMastodonAuthenticationBox
                )
                .sink { [weak self](data) in
                    switch data {
                    case .failure(let error):
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: fail to file a report : %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                        
                        let alertController = UIAlertController(for: error, title: nil, preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alertController.addAction(okAction)
                        self?.coordinator.present(
                            scene: .alertController(alertController: alertController),
                            from: nil,
                            transition: .alertController(animated: true, completion: nil)
                        )
                    case .finished:
                        self?.reportSuccess.send()
                    }
                    
                } receiveValue: { (data) in
                }
                .store(in: &self.disposeBag)
            }
            .store(in: &disposeBag)
    }
}

extension ReportViewModel: ReportedStatusTableViewCellDelegate {
    func reportedStatus(cell: ReportedStatusTableViewCell, isSelected indexPath: IndexPath) -> Bool {
        guard let item = diffableDataSource?.itemIdentifier(for: indexPath) else {
            return false
        }
        
        return selectedItems.contains(item)
    }
}
