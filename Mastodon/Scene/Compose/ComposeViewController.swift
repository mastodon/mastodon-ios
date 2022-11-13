//
//  ComposeViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

import os.log
import UIKit
import Combine
import PhotosUI
import Meta
import MetaTextKit
import MastodonMeta
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization
import MastodonSDK

final class ComposeViewController: UIViewController, NeedsDependency {
    
    static let minAutoCompleteVisibleHeight: CGFloat = 100
        
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ComposeViewModel!

    let logger = Logger(subsystem: "ComposeViewController", category: "logic")
    
    lazy var composeContentViewModel: ComposeContentViewModel = {
        return ComposeContentViewModel(
            context: context,
            authContext: viewModel.authContext,
            kind: viewModel.kind
        )
    }()
    private(set) lazy var composeContentViewController: ComposeContentViewController = {
        let composeContentViewController = ComposeContentViewController()
        composeContentViewController.viewModel = composeContentViewModel
        return composeContentViewController
    }()
    
    private(set) lazy var cancelBarButtonItem = UIBarButtonItem(title: L10n.Common.Controls.Actions.cancel, style: .plain, target: self, action: #selector(ComposeViewController.cancelBarButtonItemPressed(_:)))
    let characterCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.text = "500"
        label.textColor = Asset.Colors.Label.secondary.color
        label.accessibilityLabel = L10n.A11y.Plural.Count.inputLimitRemains(500)
        return label
    }()
    private(set) lazy var characterCountBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(customView: characterCountLabel)
        return barButtonItem
    }()

    let publishButton: UIButton = {
        let button = RoundedEdgesButton(type: .custom)
        button.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 16, bottom: 5, right: 16)     // set 28pt height
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        button.setTitle(L10n.Scene.Compose.composeAction, for: .normal)
        return button
    }()
    private(set) lazy var publishBarButtonItem: UIBarButtonItem = {
        configurePublishButtonApperance()
        let shadowBackgroundContainer = ShadowBackgroundContainer()
        publishButton.translatesAutoresizingMaskIntoConstraints = false
        shadowBackgroundContainer.addSubview(publishButton)
        NSLayoutConstraint.activate([
            publishButton.topAnchor.constraint(equalTo: shadowBackgroundContainer.topAnchor),
            publishButton.leadingAnchor.constraint(equalTo: shadowBackgroundContainer.leadingAnchor),
            publishButton.trailingAnchor.constraint(equalTo: shadowBackgroundContainer.trailingAnchor),
            publishButton.bottomAnchor.constraint(equalTo: shadowBackgroundContainer.bottomAnchor),
        ])
        let barButtonItem = UIBarButtonItem(customView: shadowBackgroundContainer)
        return barButtonItem
    }()
    private func configurePublishButtonApperance() {
        publishButton.adjustsImageWhenHighlighted = false
        publishButton.setBackgroundImage(.placeholder(color: Asset.Colors.Label.primary.color), for: .normal)
        publishButton.setBackgroundImage(.placeholder(color: Asset.Colors.Label.primary.color.withAlphaComponent(0.5)), for: .highlighted)
        publishButton.setBackgroundImage(.placeholder(color: Asset.Colors.Button.disabled.color), for: .disabled)
        publishButton.setTitleColor(Asset.Colors.Label.primaryReverse.color, for: .normal)
    }
    
//    var systemKeyboardHeight: CGFloat = .zero {
//        didSet {
//            // note: some system AutoLayout warning here
//            let height = max(300, systemKeyboardHeight)
//            customEmojiPickerInputView.frame.size.height = height
//        }
//    }
//
//    // CustomEmojiPickerView
//    let customEmojiPickerInputView: CustomEmojiPickerInputView = {
//        let view = CustomEmojiPickerInputView(frame: CGRect(x: 0, y: 0, width: 0, height: 300), inputViewStyle: .keyboard)
//        return view
//    }()
//
//    let composeToolbarView = ComposeToolbarView()
//    var composeToolbarViewBottomLayoutConstraint: NSLayoutConstraint!
//    let composeToolbarBackgroundView = UIView()
//
//

    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ComposeViewController {
    private static func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsetsReference = .readableContent
        // section.interGroupSpacing = 10
        // section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        return UICollectionViewCompositionalLayout(section: section)
    }
}

extension ComposeViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = cancelBarButtonItem
        navigationItem.rightBarButtonItem = publishBarButtonItem
        viewModel.traitCollectionDidChangePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard self.traitCollection.userInterfaceIdiom == .pad else { return }
                var items = [self.publishBarButtonItem]
                if self.traitCollection.horizontalSizeClass == .regular {
                    items.append(self.characterCountBarButtonItem)
                }
                self.navigationItem.rightBarButtonItems = items
            }
            .store(in: &disposeBag)
        publishButton.addTarget(self, action: #selector(ComposeViewController.publishBarButtonItemPressed(_:)), for: .touchUpInside)
        
        addChild(composeContentViewController)
        composeContentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(composeContentViewController.view)
        NSLayoutConstraint.activate([
            composeContentViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            composeContentViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            composeContentViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            composeContentViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        composeContentViewController.didMove(toParent: self)

//        configureNavigationBarTitleStyle()
//        viewModel.traitCollectionDidChangePublisher
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] _ in
//                guard let self = self else { return }
//                self.configureNavigationBarTitleStyle()
//            }
//            .store(in: &disposeBag)
//
//        viewModel.$title
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] title in
//                guard let self = self else { return }
//                self.title = title
//            }
//            .store(in: &disposeBag)
//
//        composeToolbarView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(composeToolbarView)
//        composeToolbarViewBottomLayoutConstraint = view.bottomAnchor.constraint(equalTo: composeToolbarView.bottomAnchor)
//        NSLayoutConstraint.activate([
//            composeToolbarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            composeToolbarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            composeToolbarViewBottomLayoutConstraint,
//            composeToolbarView.heightAnchor.constraint(equalToConstant: ComposeToolbarView.toolbarHeight),
//        ])
//        composeToolbarView.preservesSuperviewLayoutMargins = true
//        composeToolbarView.delegate = self
//
//        composeToolbarBackgroundView.translatesAutoresizingMaskIntoConstraints = false
//        view.insertSubview(composeToolbarBackgroundView, belowSubview: composeToolbarView)
//        NSLayoutConstraint.activate([
//            composeToolbarBackgroundView.topAnchor.constraint(equalTo: composeToolbarView.topAnchor),
//            composeToolbarBackgroundView.leadingAnchor.constraint(equalTo: composeToolbarView.leadingAnchor),
//            composeToolbarBackgroundView.trailingAnchor.constraint(equalTo: composeToolbarView.trailingAnchor),
//            view.bottomAnchor.constraint(equalTo: composeToolbarBackgroundView.bottomAnchor),
//        ])

//        tableView.delegate = self
//        viewModel.setupDataSource(
//            tableView: tableView,
//            metaTextDelegate: self,
//            metaTextViewDelegate: self,
//            customEmojiPickerInputViewModel: viewModel.customEmojiPickerInputViewModel,
//            composeStatusAttachmentCollectionViewCellDelegate: self,
//            composeStatusPollOptionCollectionViewCellDelegate: self,
//            composeStatusPollOptionAppendEntryCollectionViewCellDelegate: self,
//            composeStatusPollExpiresOptionCollectionViewCellDelegate: self
//        )

//        viewModel.composeStatusAttribute.$composeContent
//            .removeDuplicates()
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] _ in
//                guard let self = self else { return }
//                guard self.view.window != nil else { return }
//                UIView.performWithoutAnimation {
//                    self.tableView.beginUpdates()
//                    self.tableView.setNeedsLayout()
//                    self.tableView.layoutIfNeeded()
//                    self.tableView.endUpdates()
//                }
//            }
//            .store(in: &disposeBag)
        
//        customEmojiPickerInputView.collectionView.delegate = self
//        viewModel.customEmojiPickerInputViewModel.customEmojiPickerInputView = customEmojiPickerInputView
//        viewModel.setupCustomEmojiPickerDiffableDataSource(
//            for: customEmojiPickerInputView.collectionView,
//            dependency: self
//        )
        
//        viewModel.composeStatusContentTableViewCell.delegate = self
//
//        // update layout when keyboard show/dismiss
//        view.layoutIfNeeded()
//
//        // bind publish bar button state
//        viewModel.$isPublishBarButtonItemEnabled
//            .receive(on: DispatchQueue.main)
//            .assign(to: \.isEnabled, on: publishButton)
//            .store(in: &disposeBag)
//
//        // bind media button toolbar state
//        viewModel.$isMediaToolbarButtonEnabled
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] isMediaToolbarButtonEnabled in
//                guard let self = self else { return }
//                self.composeToolbarView.mediaBarButtonItem.isEnabled = isMediaToolbarButtonEnabled
//                self.composeToolbarView.mediaButton.isEnabled = isMediaToolbarButtonEnabled
//            }
//            .store(in: &disposeBag)
//
//        // bind poll button toolbar state
//        viewModel.$isPollToolbarButtonEnabled
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] isPollToolbarButtonEnabled in
//                guard let self = self else { return }
//                self.composeToolbarView.pollBarButtonItem.isEnabled = isPollToolbarButtonEnabled
//                self.composeToolbarView.pollButton.isEnabled = isPollToolbarButtonEnabled
//            }
//            .store(in: &disposeBag)
//
//        Publishers.CombineLatest(
//            viewModel.$isPollComposing,
//            viewModel.$isPollToolbarButtonEnabled
//        )
//        .receive(on: DispatchQueue.main)
//        .sink { [weak self] isPollComposing, isPollToolbarButtonEnabled in
//            guard let self = self else { return }
//            guard isPollToolbarButtonEnabled else {
//                let accessibilityLabel = L10n.Scene.Compose.Accessibility.appendPoll
//                self.composeToolbarView.pollBarButtonItem.accessibilityLabel = accessibilityLabel
//                self.composeToolbarView.pollButton.accessibilityLabel = accessibilityLabel
//                return
//            }
//            let accessibilityLabel = isPollComposing ? L10n.Scene.Compose.Accessibility.removePoll : L10n.Scene.Compose.Accessibility.appendPoll
//            self.composeToolbarView.pollBarButtonItem.accessibilityLabel = accessibilityLabel
//            self.composeToolbarView.pollButton.accessibilityLabel = accessibilityLabel
//        }
//        .store(in: &disposeBag)
//
//        // bind image picker toolbar state
//        viewModel.$attachmentServices
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] attachmentServices in
//                guard let self = self else { return }
//                let isEnabled = attachmentServices.count < self.viewModel.maxMediaAttachments
//                self.composeToolbarView.mediaBarButtonItem.isEnabled = isEnabled
//                self.composeToolbarView.mediaButton.isEnabled = isEnabled
//                self.resetImagePicker()
//            }
//            .store(in: &disposeBag)
//
//        // bind content warning button state
//        viewModel.$isContentWarningComposing
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] isContentWarningComposing in
//                guard let self = self else { return }
//                let accessibilityLabel = isContentWarningComposing ? L10n.Scene.Compose.Accessibility.disableContentWarning : L10n.Scene.Compose.Accessibility.enableContentWarning
//                self.composeToolbarView.contentWarningBarButtonItem.accessibilityLabel = accessibilityLabel
//                self.composeToolbarView.contentWarningButton.accessibilityLabel = accessibilityLabel
//            }
//            .store(in: &disposeBag)
//
//        // bind visibility toolbar UI
//        Publishers.CombineLatest(
//            viewModel.$selectedStatusVisibility,
//            viewModel.traitCollectionDidChangePublisher
//        )
//        .receive(on: DispatchQueue.main)
//        .sink { [weak self] type, _ in
//            guard let self = self else { return }
//            let image = type.image(interfaceStyle: self.traitCollection.userInterfaceStyle)
//            self.composeToolbarView.visibilityBarButtonItem.image = image
//            self.composeToolbarView.visibilityButton.setImage(image, for: .normal)
//            self.composeToolbarView.activeVisibilityType.value = type
//        }
//        .store(in: &disposeBag)
//
//        viewModel.$characterCount
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] characterCount in
//                guard let self = self else { return }
//                let count = self.viewModel.composeContentLimit - characterCount
//                self.composeToolbarView.characterCountLabel.text = "\(count)"
//                self.characterCountLabel.text = "\(count)"
//                let font: UIFont
//                let textColor: UIColor
//                let accessibilityLabel: String
//                switch count {
//                case _ where count < 0:
//                    font = .monospacedDigitSystemFont(ofSize: 24, weight: .bold)
//                    textColor = Asset.Colors.danger.color
//                    accessibilityLabel = L10n.A11y.Plural.Count.inputLimitExceeds(abs(count))
//                default:
//                    font = .monospacedDigitSystemFont(ofSize: 15, weight: .regular)
//                    textColor = Asset.Colors.Label.secondary.color
//                    accessibilityLabel = L10n.A11y.Plural.Count.inputLimitRemains(count)
//                }
//                self.composeToolbarView.characterCountLabel.font = font
//                self.composeToolbarView.characterCountLabel.textColor = textColor
//                self.composeToolbarView.characterCountLabel.accessibilityLabel = accessibilityLabel
//                self.characterCountLabel.font = font
//                self.characterCountLabel.textColor = textColor
//                self.characterCountLabel.accessibilityLabel = accessibilityLabel
//                self.characterCountLabel.sizeToFit()
//            }
//            .store(in: &disposeBag)
//
//        // bind custom emoji picker UI
//        viewModel.customEmojiViewModel?.emojis
//            .receive(on: DispatchQueue.main)
//            .sink(receiveValue: { [weak self] emojis in
//                guard let self = self else { return }
//                if emojis.isEmpty {
//                    self.customEmojiPickerInputView.activityIndicatorView.startAnimating()
//                } else {
//                    self.customEmojiPickerInputView.activityIndicatorView.stopAnimating()
//                }
//            })
//            .store(in: &disposeBag)
//
//        configureToolbarDisplay(keyboardHasShortcutBar: keyboardHasShortcutBar.value)
//        Publishers.CombineLatest(
//            keyboardHasShortcutBar,
//            viewModel.traitCollectionDidChangePublisher
//        )
//        .receive(on: DispatchQueue.main)
//        .sink { [weak self] keyboardHasShortcutBar, _ in
//            guard let self = self else { return }
//            self.configureToolbarDisplay(keyboardHasShortcutBar: keyboardHasShortcutBar)
//        }
//        .store(in: &disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        // update MetaText without trigger call underlaying `UITextStorage.processEditing`
//        _ = textEditorView.processEditing(textEditorView.textStorage)
        
//        markTextEditorViewBecomeFirstResponser()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

//        viewModel.isViewAppeared = true
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
//        configurePublishButtonApperance()
//        viewModel.traitCollectionDidChangePublisher.send()
    }
    
}

//extension ComposeViewController {
//    
//    private var textEditorView: MetaText {
//        return viewModel.composeStatusContentTableViewCell.metaText
//    }
//    
//    private func markTextEditorViewBecomeFirstResponser() {
//        textEditorView.textView.becomeFirstResponder()
//    }
//    
//    private func contentWarningEditorTextView() -> UITextView? {
//        viewModel.composeStatusContentTableViewCell.statusContentWarningEditorView.textView
//    }
//    
//    private func pollOptionCollectionViewCell(of item: ComposeStatusPollItem) -> ComposeStatusPollOptionCollectionViewCell? {
//        guard case .pollOption = item else { return nil }
//        guard let dataSource = viewModel.composeStatusPollTableViewCell.dataSource else { return nil }
//        guard let indexPath = dataSource.indexPath(for: item),
//              let cell = viewModel.composeStatusPollTableViewCell.collectionView.cellForItem(at: indexPath) as? ComposeStatusPollOptionCollectionViewCell else {
//            return nil
//        }
//
//        return cell
//    }
//    
//    private func firstPollOptionCollectionViewCell() -> ComposeStatusPollOptionCollectionViewCell? {
//        guard let dataSource = viewModel.composeStatusPollTableViewCell.dataSource else { return nil }
//        let items = dataSource.snapshot().itemIdentifiers(inSection: .main)
//        let firstPollItem = items.first { item -> Bool in
//            guard case .pollOption = item else { return false }
//            return true
//        }
//
//        guard let item = firstPollItem else {
//            return nil
//        }
//
//        return pollOptionCollectionViewCell(of: item)
//    }
//    
//    private func lastPollOptionCollectionViewCell() -> ComposeStatusPollOptionCollectionViewCell? {
//        guard let dataSource = viewModel.composeStatusPollTableViewCell.dataSource else { return nil }
//        let items = dataSource.snapshot().itemIdentifiers(inSection: .main)
//        let lastPollItem = items.last { item -> Bool in
//            guard case .pollOption = item else { return false }
//            return true
//        }
//
//        guard let item = lastPollItem else {
//            return nil
//        }
//
//        return pollOptionCollectionViewCell(of: item)
//    }
//    
//    private func markFirstPollOptionCollectionViewCellBecomeFirstResponser() {
//        guard let cell = firstPollOptionCollectionViewCell() else { return }
//        cell.pollOptionView.optionTextField.becomeFirstResponder()
//    }
//
//    private func markLastPollOptionCollectionViewCellBecomeFirstResponser() {
//        guard let cell = lastPollOptionCollectionViewCell() else { return }
//        cell.pollOptionView.optionTextField.becomeFirstResponder()
//    }
//    
//    private func showDismissConfirmAlertController() {
//        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//        let discardAction = UIAlertAction(title: L10n.Common.Controls.Actions.discard, style: .destructive) { [weak self] _ in
//            guard let self = self else { return }
//            self.dismiss(animated: true, completion: nil)
//        }
//        alertController.addAction(discardAction)
//        let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel)
//        alertController.addAction(cancelAction)
//        alertController.popoverPresentationController?.barButtonItem = cancelBarButtonItem
//        present(alertController, animated: true, completion: nil)
//    }
//    
//    private func resetImagePicker() {
//        let selectionLimit = max(1, viewModel.maxMediaAttachments - viewModel.attachmentServices.count)
//        let configuration = ComposeViewController.createPhotoLibraryPickerConfiguration(selectionLimit: selectionLimit)
//        photoLibraryPicker = createImagePicker(configuration: configuration)
//    }
//    
//    private func createImagePicker(configuration: PHPickerConfiguration) -> PHPickerViewController {
//        let imagePicker = PHPickerViewController(configuration: configuration)
//        imagePicker.delegate = self
//        return imagePicker
//    }
//
//    private func setupBackgroundColor(theme: Theme) {
//        let backgroundColor = UIColor(dynamicProvider: { traitCollection in
//            switch traitCollection.userInterfaceStyle {
//            case .light:
//                return .systemBackground
//            default:
//                return theme.systemElevatedBackgroundColor
//            }
//        })
//        view.backgroundColor = backgroundColor
////        tableView.backgroundColor = backgroundColor
////        composeToolbarBackgroundView.backgroundColor = theme.composeToolbarBackgroundColor
//    }
//    
//    // keyboard shortcutBar
//    private func setupInputAssistantItem(item: UITextInputAssistantItem) {
//        let barButtonItems = [
//            composeToolbarView.mediaBarButtonItem,
//            composeToolbarView.pollBarButtonItem,
//            composeToolbarView.contentWarningBarButtonItem,
//            composeToolbarView.visibilityBarButtonItem,
//        ]
//        let group = UIBarButtonItemGroup(barButtonItems: barButtonItems, representativeItem: nil)
//        
//        item.trailingBarButtonGroups = [group]
//    }
//    
//    private func configureToolbarDisplay(keyboardHasShortcutBar: Bool) {
//        switch self.traitCollection.userInterfaceIdiom {
//        case .pad:
//            let shouldHideToolbar = keyboardHasShortcutBar && self.traitCollection.horizontalSizeClass == .regular
//            self.composeToolbarView.alpha = shouldHideToolbar ? 0 : 1
//            self.composeToolbarBackgroundView.alpha = shouldHideToolbar ? 0 : 1
//        default:
//            break
//        }
//    }
//    
//    private func configureNavigationBarTitleStyle() {
//        switch traitCollection.userInterfaceIdiom {
//        case .pad:
//            navigationController?.navigationBar.prefersLargeTitles = traitCollection.horizontalSizeClass == .regular
//        default:
//            break
//        }
//    }
//
//}
//
extension ComposeViewController {

    @objc private func cancelBarButtonItemPressed(_ sender: UIBarButtonItem) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
//        guard viewModel.shouldDismiss else {
//            showDismissConfirmAlertController()
//            return
//        }
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func publishBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
//        do {
//            try viewModel.checkAttachmentPrecondition()
//        } catch {
//            let alertController = UIAlertController(for: error, title: nil, preferredStyle: .alert)
//            let okAction = UIAlertAction(title: L10n.Common.Controls.Actions.ok, style: .default, handler: nil)
//            alertController.addAction(okAction)
//            coordinator.present(scene: .alertController(alertController: alertController), from: nil, transition: .alertController(animated: true, completion: nil))
//            return
//        }
        
//        guard viewModel.publishStateMachine.enter(ComposeViewModel.PublishState.Publishing.self) else {
//            // TODO: handle error
//            return
//        }
        
        // context.statusPublishService.publish(composeViewModel: viewModel)
        
        do {
            let statusPublisher = try composeContentViewModel.statusPublisher()
            // let result = try await statusPublisher.publish(api: context.apiService, authContext: viewModel.authContext)
            // if let reactor = presentingViewController?.topMostNotModal as? StatusPublisherReactor {
            //     statusPublisher.reactor = reactor
            // }
            viewModel.context.publisherService.enqueue(
                statusPublisher: statusPublisher,
                authContext: viewModel.authContext
            )
        } catch {
            let alertController = UIAlertController.standardAlert(of: error)
            present(alertController, animated: true)
            return
        }

        dismiss(animated: true, completion: nil)
    }
    
}

//// MARK: - MetaTextDelegate
//extension ComposeViewController: MetaTextDelegate {
//    func metaText(_ metaText: MetaText, processEditing textStorage: MetaTextStorage) -> MetaContent? {
//        let string = metaText.textStorage.string
//        let content = MastodonContent(
//            content: string,
//            emojis: viewModel.customEmojiViewModel?.emojiMapping.value ?? [:]
//        )
//        let metaContent = MastodonMetaContent.convert(text: content)
//        return metaContent
//    }
//}
//
//// MARK: - UITextViewDelegate
//extension ComposeViewController: UITextViewDelegate {
//    
//    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
//        setupInputAssistantItem(item: textView.inputAssistantItem)
//        return true
//    }
//

//

//

//
//    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
//        switch textView {
//        case textEditorView.textView:
//            return false
//        default:
//            return true
//        }
//    }
//
//    func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
//        switch textView {
//        case textEditorView.textView:
//            return false
//        default:
//            return true
//        }
//    }
//
//}
//
//// MARK: - ComposeToolbarViewDelegate
//extension ComposeViewController: ComposeToolbarViewDelegate {

//    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, pollButtonDidPressed sender: Any) {
//        // toggle poll composing state
//        viewModel.isPollComposing.toggle()
//
//        // cancel custom picker input
//        viewModel.isCustomEmojiComposing = false
//        
//        // setup initial poll option if needs
//        if viewModel.isPollComposing, viewModel.pollOptionAttributes.isEmpty {
//            viewModel.pollOptionAttributes = [ComposeStatusPollItem.PollOptionAttribute(), ComposeStatusPollItem.PollOptionAttribute()]
//        }
//        
//        if viewModel.isPollComposing {
//            // Magic RunLoop
//            DispatchQueue.main.async {
//                self.markFirstPollOptionCollectionViewCellBecomeFirstResponser()
//            }
//        } else {
//            markTextEditorViewBecomeFirstResponser()
//        }
//    }
//    
//    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, emojiButtonDidPressed sender: Any) {
//        viewModel.isCustomEmojiComposing.toggle()
//    }
//    
//    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, contentWarningButtonDidPressed sender: Any) {
//        // cancel custom picker input
//        viewModel.isCustomEmojiComposing = false
//
//        // restore first responder for text editor when content warning dismiss
//        if viewModel.isContentWarningComposing {
//            if contentWarningEditorTextView()?.isFirstResponder == true {
//                markTextEditorViewBecomeFirstResponser()
//            }
//        }
//        
//        // toggle composing status
//        viewModel.isContentWarningComposing.toggle()
//        
//        // active content warning after toggled
//        if viewModel.isContentWarningComposing {
//            contentWarningEditorTextView()?.becomeFirstResponder()
//        }
//    }
//    
//    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, visibilityButtonDidPressed sender: Any, visibilitySelectionType type: ComposeToolbarView.VisibilitySelectionType) {
//        viewModel.selectedStatusVisibility = type
//    }
//    
//}

//// MARK: - UITableViewDelegate
//extension ComposeViewController: UITableViewDelegate { }
//
//// MARK: - UICollectionViewDelegate
//extension ComposeViewController: UICollectionViewDelegate {
//    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: select %s", ((#file as NSString).lastPathComponent), #line, #function, indexPath.debugDescription)
//
//        if collectionView === customEmojiPickerInputView.collectionView {
//            guard let diffableDataSource = viewModel.customEmojiPickerDiffableDataSource else { return }
//            let item = diffableDataSource.itemIdentifier(for: indexPath)
//            guard case let .emoji(attribute) = item else { return }
//            let emoji = attribute.emoji
//
//            // make click sound
//            UIDevice.current.playInputClick()
//
//            // retrieve active text input and insert emoji
//            // the trailing space is REQUIRED to make regex happy
//            _ = viewModel.customEmojiPickerInputViewModel.insertText(":\(emoji.shortcode): ")
//        } else {
//            // do nothing
//        }
//    }
//}

// MARK: - UIAdaptivePresentationControllerDelegate
extension ComposeViewController: UIAdaptivePresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        switch traitCollection.horizontalSizeClass {
        case .compact:
            return .overFullScreen
        default:
            return .pageSheet
        }
    }

//    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
//        return viewModel.shouldDismiss
//    }
    
//    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
//        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
//        showDismissConfirmAlertController()
//    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

//// MARK: - ComposeStatusAttachmentTableViewCellDelegate
//extension ComposeViewController: ComposeStatusAttachmentCollectionViewCellDelegate {
//    
//    func composeStatusAttachmentCollectionViewCell(_ cell: ComposeStatusAttachmentCollectionViewCell, removeButtonDidPressed button: UIButton) {
//        guard let diffableDataSource = viewModel.composeStatusAttachmentTableViewCell.dataSource else { return }
//        guard let indexPath = viewModel.composeStatusAttachmentTableViewCell.collectionView.indexPath(for: cell) else { return }
//        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
//        guard case let .attachment(attachmentService) = item else { return }
//
//        var attachmentServices = viewModel.attachmentServices
//        guard let index = attachmentServices.firstIndex(of: attachmentService) else { return }
//        let removedItem = attachmentServices[index]
//        attachmentServices.remove(at: index)
//        viewModel.attachmentServices = attachmentServices
//
//        // cancel task
//        removedItem.disposeBag.removeAll()
//    }
//    
//}
//
//// MARK: - ComposeStatusPollOptionCollectionViewCellDelegate
//extension ComposeViewController: ComposeStatusPollOptionCollectionViewCellDelegate {
//    
//    func composeStatusPollOptionCollectionViewCell(_ cell: ComposeStatusPollOptionCollectionViewCell, textFieldDidBeginEditing textField: UITextField) {
//        
//        setupInputAssistantItem(item: textField.inputAssistantItem)
//        
//        // FIXME: make poll section visible
//        // DispatchQueue.main.async {
//        //     self.collectionView.scroll(to: .bottom, animated: true)
//        // }
//    }
//
//    
//    // handle delete backward event for poll option input
//    func composeStatusPollOptionCollectionViewCell(_ cell: ComposeStatusPollOptionCollectionViewCell, textBeforeDeleteBackward text: String?) {
//        guard (text ?? "").isEmpty else { return }
//        guard let dataSource = viewModel.composeStatusPollTableViewCell.dataSource else { return }
//        guard let indexPath = viewModel.composeStatusPollTableViewCell.collectionView.indexPath(for: cell) else { return }
//        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
//        guard case let .pollOption(attribute) = item else { return }
//
//        var pollAttributes = viewModel.pollOptionAttributes
//        guard let index = pollAttributes.firstIndex(of: attribute) else { return }
//
//        // mark previous (fallback to next) item of removed middle poll option become first responder
//        let pollItems = dataSource.snapshot().itemIdentifiers(inSection: .main)
//        if let indexOfItem = pollItems.firstIndex(of: item), index > 0 {
//            func cellBeforeRemoved() -> ComposeStatusPollOptionCollectionViewCell? {
//                guard index > 0 else { return nil }
//                let indexBeforeRemoved = pollItems.index(before: indexOfItem)
//                let itemBeforeRemoved = pollItems[indexBeforeRemoved]
//                return pollOptionCollectionViewCell(of: itemBeforeRemoved)
//            }
//
//            func cellAfterRemoved() -> ComposeStatusPollOptionCollectionViewCell? {
//                guard index < pollItems.count - 1 else { return nil }
//                let indexAfterRemoved = pollItems.index(after: index)
//                let itemAfterRemoved = pollItems[indexAfterRemoved]
//                return pollOptionCollectionViewCell(of: itemAfterRemoved)
//            }
//
//            var cell: ComposeStatusPollOptionCollectionViewCell? = cellBeforeRemoved()
//            if cell == nil {
//                cell = cellAfterRemoved()
//            }
//            cell?.pollOptionView.optionTextField.becomeFirstResponder()
//        }
//
//        guard pollAttributes.count > 2 else {
//            return
//        }
//        pollAttributes.remove(at: index)
//
//        // update data source
//        viewModel.pollOptionAttributes = pollAttributes
//    }
//    
//    // handle keyboard return event for poll option input
//    func composeStatusPollOptionCollectionViewCell(_ cell: ComposeStatusPollOptionCollectionViewCell, pollOptionTextFieldDidReturn: UITextField) {
//        guard let dataSource = viewModel.composeStatusPollTableViewCell.dataSource else { return }
//        guard let indexPath = viewModel.composeStatusPollTableViewCell.collectionView.indexPath(for: cell) else { return }
//        let pollItems = dataSource.snapshot().itemIdentifiers(inSection: .main).filter { item in
//            guard case .pollOption = item else { return false }
//            return true
//        }
//        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
//        guard let index = pollItems.firstIndex(of: item) else { return }
//
//        if index == pollItems.count - 1 {
//            // is the last
//            viewModel.createNewPollOptionIfPossible()
//            DispatchQueue.main.async {
//                self.markLastPollOptionCollectionViewCellBecomeFirstResponser()
//            }
//        } else {
//            // not the last
//            let indexAfter = pollItems.index(after: index)
//            let itemAfter = pollItems[indexAfter]
//            let cell = pollOptionCollectionViewCell(of: itemAfter)
//            cell?.pollOptionView.optionTextField.becomeFirstResponder()
//        }
//    }
//    
//}
//
//// MARK: - ComposeStatusPollOptionAppendEntryCollectionViewCellDelegate
//extension ComposeViewController: ComposeStatusPollOptionAppendEntryCollectionViewCellDelegate {
//    func composeStatusPollOptionAppendEntryCollectionViewCellDidPressed(_ cell: ComposeStatusPollOptionAppendEntryCollectionViewCell) {
//        viewModel.createNewPollOptionIfPossible()
//        DispatchQueue.main.async {
//            self.markLastPollOptionCollectionViewCellBecomeFirstResponser()
//        }
//    }
//}
//
//// MARK: - ComposeStatusPollExpiresOptionCollectionViewCellDelegate
//extension ComposeViewController: ComposeStatusPollExpiresOptionCollectionViewCellDelegate {
//    func composeStatusPollExpiresOptionCollectionViewCell(_ cell: ComposeStatusPollExpiresOptionCollectionViewCell, didSelectExpiresOption expiresOption: ComposeStatusPollItem.PollExpiresOptionAttribute.ExpiresOption) {
//        viewModel.pollExpiresOptionAttribute.expiresOption.value = expiresOption
//    }
//}
//
//// MARK: - ComposeStatusContentTableViewCellDelegate
//extension ComposeViewController: ComposeStatusContentTableViewCellDelegate {
//    func composeStatusContentTableViewCell(_ cell: ComposeStatusContentTableViewCell, textViewShouldBeginEditing textView: UITextView) -> Bool {
//        setupInputAssistantItem(item: textView.inputAssistantItem)
//        return true
//    }
//}
//
//// MARK: - AutoCompleteViewControllerDelegate
//extension ComposeViewController: AutoCompleteViewControllerDelegate {
//    func autoCompleteViewController(_ viewController: AutoCompleteViewController, didSelectItem item: AutoCompleteItem) {
//        guard let info = viewModel.autoCompleteInfo else { return }
//        let _replacedText: String? = {
//            var text: String
//            switch item {
//            case .hashtag(let hashtag):
//                text = "#" + hashtag.name
//            case .hashtagV1(let hashtagName):
//                text = "#" + hashtagName
//            case .account(let account):
//                text = "@" + account.acct
//            case .emoji(let emoji):
//                text = ":" + emoji.shortcode + ":"
//            case .bottomLoader:
//                return nil
//            }
//            return text
//        }()
//        guard let replacedText = _replacedText else { return }
//        guard let text = textEditorView.textView.text else { return }
//
//        let range = NSRange(info.toHighlightEndRange, in: text)
//        textEditorView.textStorage.replaceCharacters(in: range, with: replacedText)
//        DispatchQueue.main.async {
//            self.textEditorView.textView.insertText(" ") // trigger textView delegate update
//        }
//        viewModel.autoCompleteInfo = nil
//
//        switch item {
//        case .emoji, .bottomLoader:
//            break
//        default:
//            // set selected range except emoji
//            let newRange = NSRange(location: range.location + (replacedText as NSString).length, length: 0)
//            guard textEditorView.textStorage.length <= newRange.location else { return }
//            textEditorView.textView.selectedRange = newRange
//        }
//    }
//}
//
//extension ComposeViewController {
//    override var keyCommands: [UIKeyCommand]? {
//        composeKeyCommands
//    }
//}
//
//extension ComposeViewController {
//    
//    enum ComposeKeyCommand: String, CaseIterable {
//        case discardPost
//        case publishPost
//        case mediaBrowse
//        case mediaPhotoLibrary
//        case mediaCamera
//        case togglePoll
//        case toggleContentWarning
//        case selectVisibilityPublic
//        // TODO: remove selectVisibilityUnlisted from codebase
//        // case selectVisibilityUnlisted
//        case selectVisibilityPrivate
//        case selectVisibilityDirect
//
//        var title: String {
//            switch self {
//            case .discardPost:              return L10n.Scene.Compose.Keyboard.discardPost
//            case .publishPost:              return L10n.Scene.Compose.Keyboard.publishPost
//            case .mediaBrowse:              return L10n.Scene.Compose.Keyboard.appendAttachmentEntry(L10n.Scene.Compose.MediaSelection.browse)
//            case .mediaPhotoLibrary:        return L10n.Scene.Compose.Keyboard.appendAttachmentEntry(L10n.Scene.Compose.MediaSelection.photoLibrary)
//            case .mediaCamera:              return L10n.Scene.Compose.Keyboard.appendAttachmentEntry(L10n.Scene.Compose.MediaSelection.camera)
//            case .togglePoll:               return L10n.Scene.Compose.Keyboard.togglePoll
//            case .toggleContentWarning:     return L10n.Scene.Compose.Keyboard.toggleContentWarning
//            case .selectVisibilityPublic:   return L10n.Scene.Compose.Keyboard.selectVisibilityEntry(L10n.Scene.Compose.Visibility.public)
//            // case .selectVisibilityUnlisted: return L10n.Scene.Compose.Keyboard.selectVisibilityEntry(L10n.Scene.Compose.Visibility.unlisted)
//            case .selectVisibilityPrivate:  return L10n.Scene.Compose.Keyboard.selectVisibilityEntry(L10n.Scene.Compose.Visibility.private)
//            case .selectVisibilityDirect:   return L10n.Scene.Compose.Keyboard.selectVisibilityEntry(L10n.Scene.Compose.Visibility.direct)
//            }
//        }
//        
//        // UIKeyCommand input
//        var input: String {
//            switch self {
//            case .discardPost:              return "w"      // + command
//            case .publishPost:              return "\r"     // (enter) + command
//            case .mediaBrowse:              return "b"      // + option + command
//            case .mediaPhotoLibrary:        return "p"      // + option + command
//            case .mediaCamera:              return "c"      // + option + command
//            case .togglePoll:               return "p"      // + shift + command
//            case .toggleContentWarning:     return "c"      // + shift + command
//            case .selectVisibilityPublic:   return "1"      // + command
//            // case .selectVisibilityUnlisted: return "2"      // + command
//            case .selectVisibilityPrivate:  return "2"      // + command
//            case .selectVisibilityDirect:   return "3"      // + command
//            }
//        }
//        
//        var modifierFlags: UIKeyModifierFlags {
//            switch self {
//            case .discardPost:              return [.command]
//            case .publishPost:              return [.command]
//            case .mediaBrowse:              return [.alternate, .command]
//            case .mediaPhotoLibrary:        return [.alternate, .command]
//            case .mediaCamera:              return [.alternate, .command]
//            case .togglePoll:               return [.shift, .command]
//            case .toggleContentWarning:     return [.shift, .command]
//            case .selectVisibilityPublic:   return [.command]
//            // case .selectVisibilityUnlisted: return [.command]
//            case .selectVisibilityPrivate:  return [.command]
//            case .selectVisibilityDirect:   return [.command]
//            }
//        }
//        
//        var propertyList: Any {
//            return rawValue
//        }
//    }
//    
//    var composeKeyCommands: [UIKeyCommand]? {
//        ComposeKeyCommand.allCases.map { command in
//            UIKeyCommand(
//                title: command.title,
//                image: nil,
//                action: #selector(Self.composeKeyCommandHandler(_:)),
//                input: command.input,
//                modifierFlags: command.modifierFlags,
//                propertyList: command.propertyList,
//                alternates: [],
//                discoverabilityTitle: nil,
//                attributes: [],
//                state: .off
//            )
//        }
//    }
//    
//    @objc private func composeKeyCommandHandler(_ sender: UIKeyCommand) {
//        guard let rawValue = sender.propertyList as? String,
//              let command = ComposeKeyCommand(rawValue: rawValue) else { return }
//        
//        switch command {
//        case .discardPost:
//            cancelBarButtonItemPressed(cancelBarButtonItem)
//        case .publishPost:
//            publishBarButtonItemPressed(publishBarButtonItem)
//        case .mediaBrowse:
//            present(documentPickerController, animated: true, completion: nil)
//        case .mediaPhotoLibrary:
//            present(photoLibraryPicker, animated: true, completion: nil)
//        case .mediaCamera:
//            guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
//                return
//            }
//            present(imagePickerController, animated: true, completion: nil)
//        case .togglePoll:
//            composeToolbarView.pollButton.sendActions(for: .touchUpInside)
//        case .toggleContentWarning:
//            composeToolbarView.contentWarningButton.sendActions(for: .touchUpInside)
//        case .selectVisibilityPublic:
//            viewModel.selectedStatusVisibility = .public
//        // case .selectVisibilityUnlisted:
//        //     viewModel.selectedStatusVisibility.value = .unlisted
//        case .selectVisibilityPrivate:
//            viewModel.selectedStatusVisibility = .private
//        case .selectVisibilityDirect:
//            viewModel.selectedStatusVisibility = .direct
//        }
//    }
//    
//}
