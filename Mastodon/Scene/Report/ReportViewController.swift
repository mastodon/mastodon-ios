//
//  ReportViewController.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/20.
//

import AVKit
import Combine
import CoreData
import CoreDataStack
import os.log
import UIKit
import TwitterTextEditor
import MastodonSDK

class ReportViewController: UIViewController, NeedsDependency {
    static let kAnimationDuration: TimeInterval = 0.33
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var viewModel: ReportViewModel! { willSet { precondition(!isViewLoaded) } }
    var disposeBag = Set<AnyCancellable>()
    let didToggleSelected = PassthroughSubject<Item, Never>()
    let comment = CurrentValueSubject<String?, Never>(nil)
    let step1Continue = PassthroughSubject<Void, Never>()
    let step1Skip = PassthroughSubject<Void, Never>()
    let step2Continue = PassthroughSubject<Void, Never>()
    let step2Skip = PassthroughSubject<Void, Never>()
    let cancel = PassthroughSubject<Void, Never>()
    
    // MAKK: - UI
    lazy var header: ReportHeaderView = {
        let view = ReportHeaderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var footer: ReportFooterView = {
        let view = ReportFooterView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.backgroundColor = Asset.Colors.Background.systemElevatedBackground.color
        return view
    }()
    
    lazy var stackview: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.alignment = .fill
        view.distribution = .fill
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.register(ReportedStatusTableViewCell.self, forCellReuseIdentifier: String(describing: ReportedStatusTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.allowsMultipleSelection = true
        return tableView
    }()
    
    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.font = .preferredFont(forTextStyle: .body)
        textView.isScrollEnabled = false
        textView.placeholder = L10n.Scene.Report.textPlaceholder
        textView.backgroundColor = .clear
        textView.delegate = self
        return textView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
        viewModel.setupDiffableDataSource(
            for: tableView,
            dependency: self
        )
        
        bindViewModel()
        bindActions()
    }
    
    // MAKR: - Private methods
    private func setupView() {
        view.backgroundColor = Asset.Colors.Background.secondarySystemBackground.color
        setupNavigation()

        stackview.addArrangedSubview(header)
        stackview.addArrangedSubview(contentView)
        stackview.addArrangedSubview(footer)
        
        contentView.addSubview(tableView)
        
        view.addSubview(stackview)
        NSLayoutConstraint.activate([
            stackview.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stackview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackview.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stackview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: contentView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        
        header.step = .one
    }
    
    private func bindActions() {
        footer.nextStepButton.addTarget(self, action: #selector(continueButtonDidClick), for: .touchUpInside)
        footer.skipButton.addTarget(self, action: #selector(skipButtonDidClick), for: .touchUpInside)
    }
    
    private func bindViewModel() {
        let input = ReportViewModel.Input(
            didToggleSelected: didToggleSelected.eraseToAnyPublisher(),
            comment: comment.eraseToAnyPublisher(),
            step1Continue: step1Continue.eraseToAnyPublisher(),
            step1Skip: step1Skip.eraseToAnyPublisher(),
            step2Continue: step2Continue.eraseToAnyPublisher(),
            step2Skip: step2Skip.eraseToAnyPublisher(),
            cancel: cancel.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)
        output?.currentStep
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] (step) in
                guard step == .two else { return }
                guard let self = self else { return }
                
                self.header.step = .two
                self.footer.step = .two
                self.switchToStep2Content()
            })
            .store(in: &disposeBag)
        
        output?.continueEnableSubject
            .receive(on: DispatchQueue.main)
            .filter { [weak self] _ in
                guard let step = self?.viewModel.currentStep.value, step == .one else { return false }
                return true
            }
            .assign(to: \.nextStepButton.isEnabled, on: footer)
            .store(in: &disposeBag)
        
        output?.sendEnableSubject
            .receive(on: DispatchQueue.main)
            .filter { [weak self] _ in
                guard let step = self?.viewModel.currentStep.value, step == .two else { return false }
                return true
            }
            .assign(to: \.nextStepButton.isEnabled, on: footer)
            .store(in: &disposeBag)
        
        output?.reportResult
            .print()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in
            }, receiveValue: { [weak self] data in
                let (success, error) = data
                if success {
                    self?.dismiss(animated: true, completion: nil)
                } else if let error = error {
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: fail to file a report : %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)

                    let alertController = UIAlertController(for: error, title: nil, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(okAction)
                    self?.coordinator.present(
                        scene: .alertController(alertController: alertController),
                        from: nil,
                        transition: .alertController(animated: true, completion: nil)
                    )
                }
            })
            .store(in: &disposeBag)
    }
    
    private func setupNavigation() {
        navigationItem.rightBarButtonItem
            = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.cancel,
                              target: self,
                              action: #selector(doneButtonDidClick))
        navigationItem.rightBarButtonItem?.tintColor = Asset.Colors.Label.highlight.color
        
        // fetch old mastodon user
        let beReportedUser: MastodonUser? = {
            guard let domain = context.authenticationService.activeMastodonAuthenticationBox.value?.domain else {
                return nil
            }
            let request = MastodonUser.sortedFetchRequest
            request.predicate = MastodonUser.predicate(domain: domain, id: viewModel.userId)
            request.fetchLimit = 1
            request.returnsObjectsAsFaults = false
            do {
                return try viewModel.statusFetchedResultsController.fetchedResultsController.managedObjectContext.fetch(request).first
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }()
        
        navigationItem.title = L10n.Scene.Report.title(
            beReportedUser?.displayNameWithFallback ?? ""
        )
    }
    
    private func switchToStep2Content() {
        self.contentView.addSubview(self.textView)
        self.textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.textView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.textView.leadingAnchor.constraint(
                equalTo: self.contentView.readableContentGuide.leadingAnchor,
                constant: ReportView.horizontalMargin
            ),
            self.textView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            self.textView.trailingAnchor.constraint(
                equalTo: self.contentView.safeAreaLayoutGuide.trailingAnchor,
                constant: -1 * ReportView.horizontalMargin
            ),
        ])
        self.textView.layoutIfNeeded()
        
        UIView.transition(
            with: contentView,
            duration: ReportViewController.kAnimationDuration,
            options: UIView.AnimationOptions.transitionCrossDissolve) {
            [weak self] in
            guard let self = self else { return }
            
            self.contentView.addSubview(self.textView)
            self.tableView.isHidden = true
        } completion: { (_) in
        }
    }
    
    // Mark: - Actions
    @objc func doneButtonDidClick() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func continueButtonDidClick() {
        if viewModel.currentStep.value == .one {
            step1Continue.send()
        } else {
            step2Continue.send()
        }
    }
    
    @objc func skipButtonDidClick() {
        if viewModel.currentStep.value == .one {
            step1Skip.send()
        } else {
            step2Skip.send()
        }
    }
}

extension ReportViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = viewModel.diffableDataSource?.itemIdentifier(for: indexPath) else {
            return
        }
        didToggleSelected.send(item)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let item = viewModel.diffableDataSource?.itemIdentifier(for: indexPath) else {
            return
        }
        didToggleSelected.send(item)
    }
}

extension ReportViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        self.comment.send(textView.text)
    }
}
