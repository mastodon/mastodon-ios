//
//  ShareViewController.swift
//  MastodonShareAction
//
//  Created by MainasuK Cirno on 2021-7-16.
//

import os.log
import UIKit
import Combine
import MastodonUI
import SwiftUI

class ShareViewController: UIViewController {

    let logger = Logger(subsystem: "ShareViewController", category: "UI")

    var disposeBag = Set<AnyCancellable>()
    let viewModel = ShareViewModel()

    let publishButton: UIButton = {
        let button = RoundedEdgesButton(type: .custom)
        button.setTitle(L10n.Scene.Compose.composeAction, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        button.setBackgroundImage(.placeholder(color: Asset.Colors.brandBlue.color), for: .normal)
        button.setBackgroundImage(.placeholder(color: Asset.Colors.brandBlue.color.withAlphaComponent(0.5)), for: .highlighted)
        button.setBackgroundImage(.placeholder(color: Asset.Colors.Button.disabled.color), for: .disabled)
        button.setTitleColor(.white, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 16, bottom: 5, right: 16)     // set 28pt height
        button.adjustsImageWhenHighlighted = false
        return button
    }()

    private(set) lazy var cancelBarButtonItem = UIBarButtonItem(title: L10n.Common.Controls.Actions.cancel, style: .plain, target: self, action: #selector(ShareViewController.cancelBarButtonItemPressed(_:)))
    private(set) lazy var publishBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(customView: publishButton)
        barButtonItem.target = self
        barButtonItem.action = #selector(ShareViewController.publishBarButtonItemPressed(_:))
        return barButtonItem
    }()

    let activityIndicatorBarButtonItem: UIBarButtonItem = {
        let indicatorView = UIActivityIndicatorView(style: .medium)
        let barButtonItem = UIBarButtonItem(customView: indicatorView)
        indicatorView.startAnimating()
        return barButtonItem
    }()


    let viewSafeAreaDidChange = PassthroughSubject<Void, Never>()
    let composeToolbarView = ComposeToolbarView()
    var composeToolbarViewBottomLayoutConstraint: NSLayoutConstraint!
    let composeToolbarBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = Asset.Scene.Compose.toolbarBackground.color
        return view
    }()
}

extension ShareViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Asset.Colors.Background.systemBackground.color

        navigationItem.leftBarButtonItem = cancelBarButtonItem
        viewModel.isBusy
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isBusy in
                guard let self = self else { return }
                self.navigationItem.rightBarButtonItem = isBusy ? self.activityIndicatorBarButtonItem : self.publishBarButtonItem
            }
            .store(in: &disposeBag)

        let hostingViewController = UIHostingController(
            rootView: ComposeView().environmentObject(viewModel.composeViewModel)
        )
        addChild(hostingViewController)
        view.addSubview(hostingViewController.view)
        hostingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingViewController.view)
        NSLayoutConstraint.activate([
            hostingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hostingViewController.didMove(toParent: self)

        composeToolbarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(composeToolbarView)
        composeToolbarViewBottomLayoutConstraint = view.bottomAnchor.constraint(equalTo: composeToolbarView.bottomAnchor)
        NSLayoutConstraint.activate([
            composeToolbarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            composeToolbarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            composeToolbarViewBottomLayoutConstraint,
            composeToolbarView.heightAnchor.constraint(equalToConstant: ComposeToolbarView.toolbarHeight),
        ])
        composeToolbarView.preservesSuperviewLayoutMargins = true
        composeToolbarView.delegate = self

        composeToolbarBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(composeToolbarBackgroundView, belowSubview: composeToolbarView)
        NSLayoutConstraint.activate([
            composeToolbarBackgroundView.topAnchor.constraint(equalTo: composeToolbarView.topAnchor),
            composeToolbarBackgroundView.leadingAnchor.constraint(equalTo: composeToolbarView.leadingAnchor),
            composeToolbarBackgroundView.trailingAnchor.constraint(equalTo: composeToolbarView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: composeToolbarBackgroundView.bottomAnchor),
        ])

        // FIXME: using iOS 15 toolbar for .keyboard placement
        let keyboardEventPublishers = Publishers.CombineLatest3(
            KeyboardResponderService.shared.isShow,
            KeyboardResponderService.shared.state,
            KeyboardResponderService.shared.endFrame
        )

        Publishers.CombineLatest(
            keyboardEventPublishers,
            viewSafeAreaDidChange
        )
        .sink(receiveValue: { [weak self] keyboardEvents, _ in
            guard let self = self else { return }

            let (isShow, state, endFrame) = keyboardEvents
            guard isShow, state == .dock else {
                UIView.animate(withDuration: 0.3) {
                    self.composeToolbarViewBottomLayoutConstraint.constant = self.view.safeAreaInsets.bottom
                    self.view.layoutIfNeeded()
                }
                return
            }
            // isShow AND dock state

            UIView.animate(withDuration: 0.3) {
                self.composeToolbarViewBottomLayoutConstraint.constant = endFrame.height
                self.view.layoutIfNeeded()
            }
        })
        .store(in: &disposeBag)

        // bind visibility toolbar UI
        Publishers.CombineLatest(
            viewModel.selectedStatusVisibility,
            viewModel.traitCollectionDidChangePublisher
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] type, _ in
            guard let self = self else { return }
            let image = type.image(interfaceStyle: self.traitCollection.userInterfaceStyle)
            self.composeToolbarView.visibilityButton.setImage(image, for: .normal)
            self.composeToolbarView.activeVisibilityType.value = type
        }
        .store(in: &disposeBag)

        // bind counter
        viewModel.characterCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] characterCount in
                guard let self = self else { return }
                let count = ShareViewModel.composeContentLimit - characterCount
                self.composeToolbarView.characterCountLabel.text = "\(count)"
                switch count {
                case _ where count < 0:
                    self.composeToolbarView.characterCountLabel.font = .monospacedDigitSystemFont(ofSize: 24, weight: .bold)
                    self.composeToolbarView.characterCountLabel.textColor = Asset.Colors.danger.color
                    self.composeToolbarView.characterCountLabel.accessibilityLabel = L10n.Scene.Compose.Accessibility.inputLimitExceedsCount(abs(count))
                default:
                    self.composeToolbarView.characterCountLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .regular)
                    self.composeToolbarView.characterCountLabel.textColor = Asset.Colors.Label.secondary.color
                    self.composeToolbarView.characterCountLabel.accessibilityLabel = L10n.Scene.Compose.Accessibility.inputLimitRemainsCount(count)
                }
            }
            .store(in: &disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.viewDidAppear.value = true
        viewModel.inputItems.value = extensionContext?.inputItems.compactMap { $0 as? NSExtensionItem } ?? []
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        viewSafeAreaDidChange.send()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        viewModel.traitCollectionDidChangePublisher.send()
    }

}

extension ShareViewController {
    @objc private func cancelBarButtonItemPressed(_ sender: UIBarButtonItem) {
        logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        extensionContext?.cancelRequest(withError: ShareViewModel.ShareError.userCancelShare)
    }

    @objc private func publishBarButtonItemPressed(_ sender: UIBarButtonItem) {
        logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
    }
}

// MARK - ComposeToolbarViewDelegate
extension ShareViewController: ComposeToolbarViewDelegate {

    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, contentWarningButtonDidPressed sender: UIButton) {
        logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")

        withAnimation {
            viewModel.composeViewModel.isContentWarningComposing.toggle()
        }
    }

    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, visibilityButtonDidPressed sender: UIButton, visibilitySelectionType type: ComposeToolbarView.VisibilitySelectionType) {
        logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")

        viewModel.selectedStatusVisibility.value = type
    }


}
