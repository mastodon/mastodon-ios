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
import MastodonSDK
import MetaTextKit
import MastodonMeta
import Meta
import MastodonUI

final class ComposeViewController: UIViewController, NeedsDependency {
    
    static let minAutoCompleteVisibleHeight: CGFloat = 100
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ComposeViewModel!

    let logger = Logger(subsystem: "ComposeViewController", category: "logic")

    private var suffixedAttachmentViews: [UIView] = []
    
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
    
    private(set) lazy var cancelBarButtonItem = UIBarButtonItem(title: L10n.Common.Controls.Actions.cancel, style: .plain, target: self, action: #selector(ComposeViewController.cancelBarButtonItemPressed(_:)))
    private(set) lazy var publishBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(customView: publishButton)
        return barButtonItem
    }()

    let tableView: ComposeTableView = {
        let tableView = ComposeTableView()
        tableView.register(ComposeRepliedToStatusContentTableViewCell.self, forCellReuseIdentifier: String(describing: ComposeRepliedToStatusContentTableViewCell.self))
        tableView.register(ComposeStatusContentTableViewCell.self, forCellReuseIdentifier: String(describing: ComposeStatusContentTableViewCell.self))
        tableView.register(ComposeStatusAttachmentTableViewCell.self, forCellReuseIdentifier: String(describing: ComposeStatusAttachmentTableViewCell.self))
        tableView.alwaysBounceVertical = true
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
    var systemKeyboardHeight: CGFloat = .zero {
        didSet {
            // note: some system AutoLayout warning here
            let height = max(300, systemKeyboardHeight)
            customEmojiPickerInputView.frame.size.height = height
        }
    }
    
    // CustomEmojiPickerView
    let customEmojiPickerInputView: CustomEmojiPickerInputView = {
        let view = CustomEmojiPickerInputView(frame: CGRect(x: 0, y: 0, width: 0, height: 300), inputViewStyle: .keyboard)
        return view
    }()
    
    let composeToolbarView = ComposeToolbarView()
    var composeToolbarViewBottomLayoutConstraint: NSLayoutConstraint!
    let composeToolbarBackgroundView = UIView()
    
    static func createPhotoLibraryPickerConfiguration(selectionLimit: Int = 4) -> PHPickerConfiguration {
        var configuration = PHPickerConfiguration()
        configuration.filter = .any(of: [.images, .videos])
        configuration.selectionLimit = selectionLimit
        return configuration
    }
    
    private(set) lazy var photoLibraryPicker: PHPickerViewController = {
        let imagePicker = PHPickerViewController(configuration: ComposeViewController.createPhotoLibraryPickerConfiguration())
        imagePicker.delegate = self
        return imagePicker
    }()
    private(set) lazy var imagePickerController: UIImagePickerController = {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .camera
        imagePickerController.delegate = self
        return imagePickerController
    }()
    
    private(set) lazy var documentPickerController: UIDocumentPickerViewController = {
        let documentPickerController = UIDocumentPickerViewController(forOpeningContentTypes: [.image, .movie])
        documentPickerController.delegate = self
        return documentPickerController
    }()
    
    private(set) lazy var autoCompleteViewController: AutoCompleteViewController = {
        let viewController = AutoCompleteViewController()
        viewController.viewModel = AutoCompleteViewModel(context: context)
        viewController.delegate = self
        viewModel.customEmojiViewModel
            .assign(to: \.value, on: viewController.viewModel.customEmojiViewModel)
            .store(in: &disposeBag)
        return viewController
    }()
    
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
        
        viewModel.title
            .receive(on: DispatchQueue.main)
            .sink { [weak self] title in
                guard let self = self else { return }
                self.title = title
            }
            .store(in: &disposeBag)
        self.setupBackgroundColor(theme: ThemeService.shared.currentTheme.value)
        ThemeService.shared.currentTheme
            .receive(on: RunLoop.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.setupBackgroundColor(theme: theme)
            }
            .store(in: &disposeBag)
        navigationItem.leftBarButtonItem = cancelBarButtonItem
        navigationItem.rightBarButtonItem = publishBarButtonItem
        publishButton.addTarget(self, action: #selector(ComposeViewController.publishBarButtonItemPressed(_:)), for: .touchUpInside)


        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
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

        tableView.delegate = self
        viewModel.setupDataSource(
            tableView: tableView,
            metaTextDelegate: self,
            metaTextViewDelegate: self,
            customEmojiPickerInputViewModel: viewModel.customEmojiPickerInputViewModel,
            composeStatusAttachmentCollectionViewCellDelegate: self,
            composeStatusPollOptionCollectionViewCellDelegate: self,
            composeStatusPollOptionAppendEntryCollectionViewCellDelegate: self,
            composeStatusPollExpiresOptionCollectionViewCellDelegate: self
        )

        viewModel.composeStatusAttribute.composeContent
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard self.view.window != nil else { return }
                UIView.performWithoutAnimation {
                    self.tableView.beginUpdates()
                    self.tableView.endUpdates()
                }
            }
            .store(in: &disposeBag)
        
        customEmojiPickerInputView.collectionView.delegate = self
        viewModel.customEmojiPickerInputViewModel.customEmojiPickerInputView = customEmojiPickerInputView
        viewModel.setupCustomEmojiPickerDiffableDataSource(
            for: customEmojiPickerInputView.collectionView,
            dependency: self
        )
        
        // update layout when keyboard show/dismiss
        view.layoutIfNeeded()
        let keyboardEventPublishers = Publishers.CombineLatest3(
            KeyboardResponderService.shared.isShow,
            KeyboardResponderService.shared.state,
            KeyboardResponderService.shared.endFrame
        )
        Publishers.CombineLatest3(
            keyboardEventPublishers,
            viewModel.isCustomEmojiComposing,
            viewModel.autoCompleteInfo
        )
        .sink(receiveValue: { [weak self] keyboardEvents, isCustomEmojiComposing, autoCompleteInfo in
            guard let self = self else { return }

            let (isShow, state, endFrame) = keyboardEvents
            let extraMargin: CGFloat = {
                var margin = self.composeToolbarView.frame.height
                if autoCompleteInfo != nil {
                    margin += ComposeViewController.minAutoCompleteVisibleHeight
                }
                return margin
            }()

            guard isShow, state == .dock else {
                self.tableView.contentInset.bottom = extraMargin
                self.tableView.verticalScrollIndicatorInsets.bottom = extraMargin
            
                if let superView = self.autoCompleteViewController.tableView.superview {
                    let autoCompleteTableViewBottomInset: CGFloat = {
                        let tableViewFrameInWindow = superView.convert(self.autoCompleteViewController.tableView.frame, to: nil)
                        let padding = tableViewFrameInWindow.maxY + self.composeToolbarView.frame.height + AutoCompleteViewController.chevronViewHeight - self.view.frame.maxY
                        return max(0, padding)
                    }()
                    self.autoCompleteViewController.tableView.contentInset.bottom = autoCompleteTableViewBottomInset
                    self.autoCompleteViewController.tableView.verticalScrollIndicatorInsets.bottom = autoCompleteTableViewBottomInset
                }
                
                UIView.animate(withDuration: 0.3) {
                    self.composeToolbarViewBottomLayoutConstraint.constant = self.view.safeAreaInsets.bottom
                    if self.view.window != nil {
                        self.view.layoutIfNeeded()
                    }
                }
                return
            }
            // isShow AND dock state
            self.systemKeyboardHeight = endFrame.height
            
            // adjust inset for auto-complete
            let autoCompleteTableViewBottomInset: CGFloat = {
                guard let superview = self.autoCompleteViewController.tableView.superview else { return .zero }
                let tableViewFrameInWindow = superview.convert(self.autoCompleteViewController.tableView.frame, to: nil)
                let padding = tableViewFrameInWindow.maxY + self.composeToolbarView.frame.height + AutoCompleteViewController.chevronViewHeight - endFrame.minY
                return max(0, padding)
            }()
            self.autoCompleteViewController.tableView.contentInset.bottom = autoCompleteTableViewBottomInset
            self.autoCompleteViewController.tableView.verticalScrollIndicatorInsets.bottom = autoCompleteTableViewBottomInset
            
            // adjust inset for tableView
            let contentFrame = self.view.convert(self.tableView.frame, to: nil)
            let padding = contentFrame.maxY + extraMargin - endFrame.minY
            guard padding > 0 else {
                self.tableView.contentInset.bottom = self.view.safeAreaInsets.bottom + extraMargin
                self.tableView.verticalScrollIndicatorInsets.bottom = self.view.safeAreaInsets.bottom + extraMargin
                return
            }

            self.tableView.contentInset.bottom = padding - self.view.safeAreaInsets.bottom
            self.tableView.verticalScrollIndicatorInsets.bottom = padding - self.view.safeAreaInsets.bottom
            UIView.animate(withDuration: 0.3) {
                self.composeToolbarViewBottomLayoutConstraint.constant = endFrame.height
                self.view.layoutIfNeeded()
            }
        })
        .store(in: &disposeBag)
        
        // bind auto-complete
        viewModel.autoCompleteInfo
            .receive(on: DispatchQueue.main)
            .sink { [weak self] info in
                guard let self = self else { return }
                guard let textEditorView = self.textEditorView() else { return }
                if self.autoCompleteViewController.view.superview == nil {
                    self.autoCompleteViewController.view.frame = self.view.bounds
                    // add to container view. seealso: `viewDidLayoutSubviews()`
                    self.viewModel.composeStatusContentTableViewCell.textEditorViewContainerView.addSubview(self.autoCompleteViewController.view)
                    self.addChild(self.autoCompleteViewController)
                    self.autoCompleteViewController.didMove(toParent: self)
                    self.autoCompleteViewController.view.isHidden = true
                    self.tableView.autoCompleteViewController = self.autoCompleteViewController
                }
                self.updateAutoCompleteViewControllerLayout()
                self.autoCompleteViewController.view.isHidden = info == nil
                guard let info = info else { return }
                let symbolBoundingRectInContainer = textEditorView.textView.convert(info.symbolBoundingRect, to: self.autoCompleteViewController.chevronView)
                self.autoCompleteViewController.view.frame.origin.y = info.textBoundingRect.maxY
                self.autoCompleteViewController.viewModel.symbolBoundingRect.value = symbolBoundingRectInContainer
                self.autoCompleteViewController.viewModel.inputText.value = String(info.inputText)
            }
            .store(in: &disposeBag)

        // bind publish bar button state
        viewModel.isPublishBarButtonItemEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: publishBarButtonItem)
            .store(in: &disposeBag)
        
        // bind media button toolbar state
        viewModel.isMediaToolbarButtonEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: composeToolbarView.mediaButton)
            .store(in: &disposeBag)
        
        // bind poll button toolbar state
        viewModel.isPollToolbarButtonEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: composeToolbarView.pollButton)
            .store(in: &disposeBag)
        
        Publishers.CombineLatest(
            viewModel.isPollComposing,
            viewModel.isPollToolbarButtonEnabled
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] isPollComposing, isPollToolbarButtonEnabled in
            guard let self = self else { return }
            guard isPollToolbarButtonEnabled else {
                self.composeToolbarView.pollButton.accessibilityLabel = L10n.Scene.Compose.Accessibility.appendPoll
                return
            }
            self.composeToolbarView.pollButton.accessibilityLabel = isPollComposing ? L10n.Scene.Compose.Accessibility.removePoll : L10n.Scene.Compose.Accessibility.appendPoll
        }
        .store(in: &disposeBag)

        // bind image picker toolbar state
        viewModel.attachmentServices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] attachmentServices in
                guard let self = self else { return }
                self.composeToolbarView.mediaButton.isEnabled = attachmentServices.count < 4
                self.resetImagePicker()
            }
            .store(in: &disposeBag)
        
        // bind content warning button state
        viewModel.isContentWarningComposing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isContentWarningComposing in
                guard let self = self else { return }
                self.composeToolbarView.contentWarningButton.accessibilityLabel = isContentWarningComposing ? L10n.Scene.Compose.Accessibility.disableContentWarning : L10n.Scene.Compose.Accessibility.enableContentWarning
            }
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
        
        viewModel.characterCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] characterCount in
                guard let self = self else { return }
                let count = ComposeViewModel.composeContentLimit - characterCount
                self.composeToolbarView.characterCountLabel.text = "\(count)"
                switch count {
                case _ where count < 0:
                    self.composeToolbarView.characterCountLabel.font = .monospacedDigitSystemFont(ofSize: 24, weight: .bold)
                    self.composeToolbarView.characterCountLabel.textColor = Asset.Colors.danger.color
                    self.composeToolbarView.characterCountLabel.accessibilityLabel = L10n.A11y.Plural.Count.inputLimitExceeds(abs(count))
                default:
                    self.composeToolbarView.characterCountLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .regular)
                    self.composeToolbarView.characterCountLabel.textColor = Asset.Colors.Label.secondary.color
                    self.composeToolbarView.characterCountLabel.accessibilityLabel = L10n.A11y.Plural.Count.inputLimitRemains(count)
                }
            }
            .store(in: &disposeBag)

        // bind custom emoji picker UI
        viewModel.customEmojiViewModel
            .map { viewModel -> AnyPublisher<[Mastodon.Entity.Emoji], Never> in
                guard let viewModel = viewModel else {
                    return Just([]).eraseToAnyPublisher()
                }
                return viewModel.emojis.eraseToAnyPublisher()
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] emojis in
                guard let self = self else { return }
                if emojis.isEmpty {
                    self.customEmojiPickerInputView.activityIndicatorView.startAnimating()
                } else {
                    self.customEmojiPickerInputView.activityIndicatorView.stopAnimating()
                }
            })
            .store(in: &disposeBag)
        
        // setup snap behavior
        Publishers.CombineLatest(
            viewModel.repliedToCellFrame,
            viewModel.collectionViewState
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] repliedToCellFrame, collectionViewState in
            guard let self = self else { return }
            guard repliedToCellFrame != .zero else { return }
            switch collectionViewState {
            case .fold:
                self.tableView.contentInset.top = -repliedToCellFrame.height
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: set contentInset.top: -%s", ((#file as NSString).lastPathComponent), #line, #function, repliedToCellFrame.height.description)

            case .expand:
                self.tableView.contentInset.top = 0
            }
        }
        .store(in: &disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // using index to make table view layout
        // otherwise, the content offset will be wrong
        guard let indexPath = tableView.indexPath(for: viewModel.composeStatusContentTableViewCell),
              let cell = tableView.cellForRow(at: indexPath) as? ComposeStatusContentTableViewCell else {
            assertionFailure()
            return
        }
        cell.metaText.textView.becomeFirstResponder()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.isViewAppeared = true
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        viewModel.traitCollectionDidChangePublisher.send()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateAutoCompleteViewControllerLayout()
    }

    func updateAutoCompleteViewControllerLayout() {
        // pin autoCompleteViewController frame to current view
        if let containerView = autoCompleteViewController.view.superview {
            let viewFrameInWindow = containerView.convert(autoCompleteViewController.view.frame, to: view)
            if viewFrameInWindow.origin.x != 0 {
                autoCompleteViewController.view.frame.origin.x = -viewFrameInWindow.origin.x
            }
            autoCompleteViewController.view.frame.size.width = view.frame.width
        }
    }
    
}

extension ComposeViewController {
    
    private func textEditorView() -> MetaText? {
        return viewModel.composeStatusContentTableViewCell.metaText
    }
    
    private func markTextEditorViewBecomeFirstResponser() {
        textEditorView()?.textView.becomeFirstResponder()
    }
    
    private func contentWarningEditorTextView() -> UITextView? {
        viewModel.composeStatusContentTableViewCell.statusContentWarningEditorView.textView
    }
    
    private func pollOptionCollectionViewCell(of item: ComposeStatusPollItem) -> ComposeStatusPollOptionCollectionViewCell? {
        guard case .pollOption = item else { return nil }
        guard let dataSource = viewModel.composeStatusPollTableViewCell.dataSource else { return nil }
        guard let indexPath = dataSource.indexPath(for: item),
              let cell = viewModel.composeStatusPollTableViewCell.collectionView.cellForItem(at: indexPath) as? ComposeStatusPollOptionCollectionViewCell else {
            return nil
        }

        return cell
    }
    
    private func firstPollOptionCollectionViewCell() -> ComposeStatusPollOptionCollectionViewCell? {
        guard let dataSource = viewModel.composeStatusPollTableViewCell.dataSource else { return nil }
        let items = dataSource.snapshot().itemIdentifiers(inSection: .main)
        let firstPollItem = items.first { item -> Bool in
            guard case .pollOption = item else { return false }
            return true
        }

        guard let item = firstPollItem else {
            return nil
        }

        return pollOptionCollectionViewCell(of: item)
    }
    
    private func lastPollOptionCollectionViewCell() -> ComposeStatusPollOptionCollectionViewCell? {
        guard let dataSource = viewModel.composeStatusPollTableViewCell.dataSource else { return nil }
        let items = dataSource.snapshot().itemIdentifiers(inSection: .main)
        let lastPollItem = items.last { item -> Bool in
            guard case .pollOption = item else { return false }
            return true
        }

        guard let item = lastPollItem else {
            return nil
        }

        return pollOptionCollectionViewCell(of: item)
    }
    
    private func markFirstPollOptionCollectionViewCellBecomeFirstResponser() {
        guard let cell = firstPollOptionCollectionViewCell() else { return }
        cell.pollOptionView.optionTextField.becomeFirstResponder()
    }

    private func markLastPollOptionCollectionViewCellBecomeFirstResponser() {
        guard let cell = lastPollOptionCollectionViewCell() else { return }
        cell.pollOptionView.optionTextField.becomeFirstResponder()
    }
    
    private func showDismissConfirmAlertController() {
        let alertController = UIAlertController(
            title: L10n.Common.Alerts.DiscardPostContent.title,
            message: L10n.Common.Alerts.DiscardPostContent.message,
            preferredStyle: .alert
        )
        let discardAction = UIAlertAction(title: L10n.Common.Controls.Actions.discard, style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(discardAction)
        let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    private func resetImagePicker() {
        let selectionLimit = max(1, 4 - viewModel.attachmentServices.value.count)
        let configuration = ComposeViewController.createPhotoLibraryPickerConfiguration(selectionLimit: selectionLimit)
        photoLibraryPicker = createImagePicker(configuration: configuration)
    }
    
    private func createImagePicker(configuration: PHPickerConfiguration) -> PHPickerViewController {
        let imagePicker = PHPickerViewController(configuration: configuration)
        imagePicker.delegate = self
        return imagePicker
    }

    private func setupBackgroundColor(theme: Theme) {
        view.backgroundColor = theme.systemElevatedBackgroundColor
        tableView.backgroundColor = theme.systemElevatedBackgroundColor
        composeToolbarBackgroundView.backgroundColor = theme.composeToolbarBackgroundColor
    }

}

extension ComposeViewController {

    @objc private func cancelBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard viewModel.shouldDismiss.value else {
            showDismissConfirmAlertController()
            return
        }
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func publishBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        do {
            try viewModel.checkAttachmentPrecondition()
        } catch {
            let alertController = UIAlertController(for: error, title: nil, preferredStyle: .alert)
            let okAction = UIAlertAction(title: L10n.Common.Controls.Actions.ok, style: .default, handler: nil)
            alertController.addAction(okAction)
            coordinator.present(scene: .alertController(alertController: alertController), from: nil, transition: .alertController(animated: true, completion: nil))
            return
        }
        
        guard viewModel.publishStateMachine.enter(ComposeViewModel.PublishState.Publishing.self) else {
            // TODO: handle error
            return
        }
        context.statusPublishService.publish(composeViewModel: viewModel)
        dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - MetaTextDelegate
extension ComposeViewController: MetaTextDelegate {
    func metaText(_ metaText: MetaText, processEditing textStorage: MetaTextStorage) -> MetaContent? {
        let string = metaText.textStorage.string
        let content = MastodonContent(
            content: string,
            emojis: viewModel.customEmojiViewModel.value?.emojiMapping.value ?? [:]
        )
        let metaContent = MastodonMetaContent.convert(text: content)
        return metaContent
    }
}

// MARK: - UITextViewDelegate
extension ComposeViewController: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        if textEditorView()?.textView === textView {
            // update model
            guard let metaText = textEditorView() else { return }
            let backedString = metaText.backedString
            viewModel.composeStatusAttribute.composeContent.value = backedString
            logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(backedString)")

            // configure auto completion
            setupAutoComplete(for: textView)
        }
    }

    struct AutoCompleteInfo {
        // model
        let inputText: Substring
        // range
        let symbolRange: Range<String.Index>
        let symbolString: Substring
        let toCursorRange: Range<String.Index>
        let toCursorString: Substring
        let toHighlightEndRange: Range<String.Index>
        let toHighlightEndString: Substring
        // geometry
        var textBoundingRect: CGRect = .zero
        var symbolBoundingRect: CGRect = .zero
    }

    private func setupAutoComplete(for textView: UITextView) {
        guard var autoCompletion = ComposeViewController.scanAutoCompleteInfo(textView: textView) else {
            viewModel.autoCompleteInfo.value = nil
            return
        }
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: auto complete %s (%s)", ((#file as NSString).lastPathComponent), #line, #function, String(autoCompletion.toHighlightEndString), String(autoCompletion.toCursorString))

        // get layout text bounding rect
        var glyphRange = NSRange()
        textView.layoutManager.characterRange(forGlyphRange: NSRange(autoCompletion.toCursorRange, in: textView.text), actualGlyphRange: &glyphRange)
        let textContainer = textView.layoutManager.textContainers[0]
        let textBoundingRect = textView.layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)

        let retryLayoutTimes = viewModel.autoCompleteRetryLayoutTimes.value
        guard textBoundingRect.size != .zero else {
            viewModel.autoCompleteRetryLayoutTimes.value += 1
            // avoid infinite loop
            guard retryLayoutTimes < 3 else { return }
            // needs retry calculate layout when the rect position changing
            DispatchQueue.main.async {
                self.setupAutoComplete(for: textView)
            }
            return
        }
        viewModel.autoCompleteRetryLayoutTimes.value = 0

        // get symbol bounding rect
        textView.layoutManager.characterRange(forGlyphRange: NSRange(autoCompletion.symbolRange, in: textView.text), actualGlyphRange: &glyphRange)
        let symbolBoundingRect = textView.layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)

        // set bounding rect and trigger layout
        autoCompletion.textBoundingRect = textBoundingRect
        autoCompletion.symbolBoundingRect = symbolBoundingRect
        viewModel.autoCompleteInfo.value = autoCompletion
    }

    private static func scanAutoCompleteInfo(textView: UITextView) -> AutoCompleteInfo? {
        guard let text = textView.text,
              textView.selectedRange.location > 0, !text.isEmpty,
              let selectedRange = Range(textView.selectedRange, in: text) else {
            return nil
        }
        let cursorIndex = selectedRange.upperBound
        let _highlightStartIndex: String.Index? = {
            var index = text.index(before: cursorIndex)
            while index > text.startIndex {
                let char = text[index]
                if char == "@" || char == "#" || char == ":" {
                    return index
                }
                index = text.index(before: index)
            }
            assert(index == text.startIndex)
            let char = text[index]
            if char == "@" || char == "#" || char == ":" {
                return index
            } else {
                return nil
            }
        }()

        guard let highlightStartIndex = _highlightStartIndex else { return nil }
        let scanRange = NSRange(highlightStartIndex..<text.endIndex, in: text)

        guard let match = text.firstMatch(pattern: MastodonRegex.autoCompletePattern, options: [], range: scanRange) else { return nil }
        guard let matchRange = Range(match.range(at: 0), in: text) else { return nil }
        let matchStartIndex = matchRange.lowerBound
        let matchEndIndex = matchRange.upperBound

        guard matchStartIndex == highlightStartIndex, matchEndIndex >= cursorIndex else { return nil }
        let symbolRange = highlightStartIndex..<text.index(after: highlightStartIndex)
        let symbolString = text[symbolRange]
        let toCursorRange = highlightStartIndex..<cursorIndex
        let toCursorString = text[toCursorRange]
        let toHighlightEndRange = matchStartIndex..<matchEndIndex
        let toHighlightEndString = text[toHighlightEndRange]

        let inputText = toHighlightEndString
        let autoCompleteInfo = AutoCompleteInfo(
            inputText: inputText,
            symbolRange: symbolRange,
            symbolString: symbolString,
            toCursorRange: toCursorRange,
            toCursorString: toCursorString,
            toHighlightEndRange: toHighlightEndRange,
            toHighlightEndString: toHighlightEndString
        )
        return autoCompleteInfo
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if textView === textEditorView()?.textView {
            return false
        }

        return true
    }

    func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if textView === textEditorView()?.textView {
            return false
        }

        return true
    }

}

// MARK: - ComposeToolbarViewDelegate
extension ComposeViewController: ComposeToolbarViewDelegate {
    
    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, cameraButtonDidPressed sender: UIButton, mediaSelectionType type: ComposeToolbarView.MediaSelectionType) {
        switch type {
        case .photoLibrary:
            present(photoLibraryPicker, animated: true, completion: nil)
        case .camera:
            present(imagePickerController, animated: true, completion: nil)
        case .browse:
            present(documentPickerController, animated: true, completion: nil)
        }
    }
    
    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, pollButtonDidPressed sender: UIButton) {
        // toggle poll composing state
        viewModel.isPollComposing.value.toggle()

        // cancel custom picker input
        viewModel.isCustomEmojiComposing.value = false
        
        // setup initial poll option if needs
        if viewModel.isPollComposing.value, viewModel.pollOptionAttributes.value.isEmpty {
            viewModel.pollOptionAttributes.value = [ComposeStatusPollItem.PollOptionAttribute(), ComposeStatusPollItem.PollOptionAttribute()]
        }
        
        if viewModel.isPollComposing.value {
            // Magic RunLoop
            DispatchQueue.main.async {
                self.markFirstPollOptionCollectionViewCellBecomeFirstResponser()
            }
        } else {
            markTextEditorViewBecomeFirstResponser()
        }
    }
    
    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, emojiButtonDidPressed sender: UIButton) {
        viewModel.isCustomEmojiComposing.value.toggle()
    }
    
    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, contentWarningButtonDidPressed sender: UIButton) {
        // cancel custom picker input
        viewModel.isCustomEmojiComposing.value = false

        // restore first responder for text editor when content warning dismiss
        if viewModel.isContentWarningComposing.value {
            if contentWarningEditorTextView()?.isFirstResponder == true {
                markTextEditorViewBecomeFirstResponser()
            }
        }
        
        // toggle composing status
        viewModel.isContentWarningComposing.value.toggle()
        
        // active content warning after toggled
        if viewModel.isContentWarningComposing.value {
            contentWarningEditorTextView()?.becomeFirstResponder()
        }
    }
    
    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, visibilityButtonDidPressed sender: UIButton, visibilitySelectionType type: ComposeToolbarView.VisibilitySelectionType) {
        viewModel.selectedStatusVisibility.value = type
    }
    
}

// MARK: - UIScrollViewDelegate
extension ComposeViewController {
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard scrollView === tableView else { return }

        let repliedToCellFrame = viewModel.repliedToCellFrame.value
        guard repliedToCellFrame != .zero else { return }

         // try to find some patterns:
         // print("""
         // repliedToCellFrame: \(viewModel.repliedToCellFrame.value.height)
         // scrollView.contentOffset.y: \(scrollView.contentOffset.y)
         // scrollView.contentSize.height: \(scrollView.contentSize.height)
         // scrollView.frame: \(scrollView.frame)
         // scrollView.adjustedContentInset.top: \(scrollView.adjustedContentInset.top)
         // scrollView.adjustedContentInset.bottom: \(scrollView.adjustedContentInset.bottom)
         // """)

        switch viewModel.collectionViewState.value {
        case .fold:
            os_log("%{public}s[%{public}ld], %{public}s: fold", ((#file as NSString).lastPathComponent), #line, #function)
            guard velocity.y < 0 else { return }
            let offsetY = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
            if offsetY < -44 {
                tableView.contentInset.top = 0
                targetContentOffset.pointee = CGPoint(x: 0, y: -scrollView.adjustedContentInset.top)
                viewModel.collectionViewState.value = .expand
            }

        case .expand:
            os_log("%{public}s[%{public}ld], %{public}s: expand", ((#file as NSString).lastPathComponent), #line, #function)
            guard velocity.y > 0 else { return }
            // check if top across
            let topOffset = (scrollView.contentOffset.y + scrollView.adjustedContentInset.top) - repliedToCellFrame.height

            // check if bottom bounce
            let bottomOffsetY = scrollView.contentOffset.y + (scrollView.frame.height - scrollView.adjustedContentInset.bottom)
            let bottomOffset = bottomOffsetY - scrollView.contentSize.height

            if topOffset > 44 {
                // do not interrupt user scrolling
                viewModel.collectionViewState.value = .fold
            } else if bottomOffset > 44 {
                tableView.contentInset.top = -repliedToCellFrame.height
                targetContentOffset.pointee = CGPoint(x: 0, y: -repliedToCellFrame.height)
                viewModel.collectionViewState.value = .fold
            }
        }
    }
}

// MARK: - UITableViewDelegate
extension ComposeViewController: UITableViewDelegate { }

// MARK: - UICollectionViewDelegate
extension ComposeViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: select %s", ((#file as NSString).lastPathComponent), #line, #function, indexPath.debugDescription)

        if collectionView === customEmojiPickerInputView.collectionView {
            guard let diffableDataSource = viewModel.customEmojiPickerDiffableDataSource else { return }
            let item = diffableDataSource.itemIdentifier(for: indexPath)
            guard case let .emoji(attribute) = item else { return }
            let emoji = attribute.emoji

            // make click sound
            UIDevice.current.playInputClick()

            // retrieve active text input and insert emoji
            // the trailing space is REQUIRED to make regex happy
            _ = viewModel.customEmojiPickerInputViewModel.insertText(":\(emoji.shortcode): ")
        } else {
            // do nothing
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension ComposeViewController: UIAdaptivePresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .overFullScreen
        //return traitCollection.userInterfaceIdiom == .pad ? .formSheet : .automatic
    }

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return viewModel.shouldDismiss.value
    }
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        showDismissConfirmAlertController()

    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

// MARK: - PHPickerViewControllerDelegate
extension ComposeViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        
        let attachmentServices: [MastodonAttachmentService] = results.map { result in
            let service = MastodonAttachmentService(
                context: context,
                pickerResult: result,
                initialAuthenticationBox: viewModel.activeAuthenticationBox.value
            )
            return service
        }
        viewModel.attachmentServices.value = viewModel.attachmentServices.value + attachmentServices
    }
}

// MARK: - UIImagePickerControllerDelegate
extension ComposeViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)

        guard let image = info[.originalImage] as? UIImage else { return }
        
        let attachmentService = MastodonAttachmentService(
            context: context,
            image: image,
            initialAuthenticationBox: viewModel.activeAuthenticationBox.value
        )
        viewModel.attachmentServices.value = viewModel.attachmentServices.value + [attachmentService]
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - UIDocumentPickerDelegate
extension ComposeViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }

        let attachmentService = MastodonAttachmentService(
            context: context,
            documentURL: url,
            initialAuthenticationBox: viewModel.activeAuthenticationBox.value
        )
        viewModel.attachmentServices.value = viewModel.attachmentServices.value + [attachmentService]
    }
}

// MARK: - ComposeStatusAttachmentTableViewCellDelegate
extension ComposeViewController: ComposeStatusAttachmentCollectionViewCellDelegate {
    
    func composeStatusAttachmentCollectionViewCell(_ cell: ComposeStatusAttachmentCollectionViewCell, removeButtonDidPressed button: UIButton) {
        guard let diffableDataSource = viewModel.composeStatusAttachmentTableViewCell.dataSource else { return }
        guard let indexPath = viewModel.composeStatusAttachmentTableViewCell.collectionView.indexPath(for: cell) else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        guard case let .attachment(attachmentService) = item else { return }

        var attachmentServices = viewModel.attachmentServices.value
        guard let index = attachmentServices.firstIndex(of: attachmentService) else { return }
        let removedItem = attachmentServices[index]
        attachmentServices.remove(at: index)
        viewModel.attachmentServices.value = attachmentServices

        // cancel task
        removedItem.disposeBag.removeAll()
    }
    
}

// MARK: - ComposeStatusPollOptionCollectionViewCellDelegate
extension ComposeViewController: ComposeStatusPollOptionCollectionViewCellDelegate {
    
    func composeStatusPollOptionCollectionViewCell(_ cell: ComposeStatusPollOptionCollectionViewCell, textFieldDidBeginEditing textField: UITextField) {
        // FIXME: make poll section visible
        // DispatchQueue.main.async {
        //     self.collectionView.scroll(to: .bottom, animated: true)
        // }
    }

    
    // handle delete backward event for poll option input
    func composeStatusPollOptionCollectionViewCell(_ cell: ComposeStatusPollOptionCollectionViewCell, textBeforeDeleteBackward text: String?) {
        guard (text ?? "").isEmpty else { return }
        guard let dataSource = viewModel.composeStatusPollTableViewCell.dataSource else { return }
        guard let indexPath = viewModel.composeStatusPollTableViewCell.collectionView.indexPath(for: cell) else { return }
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        guard case let .pollOption(attribute) = item else { return }

        var pollAttributes = viewModel.pollOptionAttributes.value
        guard let index = pollAttributes.firstIndex(of: attribute) else { return }

        // mark previous (fallback to next) item of removed middle poll option become first responder
        let pollItems = dataSource.snapshot().itemIdentifiers(inSection: .main)
        if let indexOfItem = pollItems.firstIndex(of: item), index > 0 {
            func cellBeforeRemoved() -> ComposeStatusPollOptionCollectionViewCell? {
                guard index > 0 else { return nil }
                let indexBeforeRemoved = pollItems.index(before: indexOfItem)
                let itemBeforeRemoved = pollItems[indexBeforeRemoved]
                return pollOptionCollectionViewCell(of: itemBeforeRemoved)
            }

            func cellAfterRemoved() -> ComposeStatusPollOptionCollectionViewCell? {
                guard index < pollItems.count - 1 else { return nil }
                let indexAfterRemoved = pollItems.index(after: index)
                let itemAfterRemoved = pollItems[indexAfterRemoved]
                return pollOptionCollectionViewCell(of: itemAfterRemoved)
            }

            var cell: ComposeStatusPollOptionCollectionViewCell? = cellBeforeRemoved()
            if cell == nil {
                cell = cellAfterRemoved()
            }
            cell?.pollOptionView.optionTextField.becomeFirstResponder()
        }

        guard pollAttributes.count > 2 else {
            return
        }
        pollAttributes.remove(at: index)

        // update data source
        viewModel.pollOptionAttributes.value = pollAttributes
    }
    
    // handle keyboard return event for poll option input
    func composeStatusPollOptionCollectionViewCell(_ cell: ComposeStatusPollOptionCollectionViewCell, pollOptionTextFieldDidReturn: UITextField) {
        guard let dataSource = viewModel.composeStatusPollTableViewCell.dataSource else { return }
        guard let indexPath = viewModel.composeStatusPollTableViewCell.collectionView.indexPath(for: cell) else { return }
        let pollItems = dataSource.snapshot().itemIdentifiers(inSection: .main).filter { item in
            guard case .pollOption = item else { return false }
            return true
        }
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        guard let index = pollItems.firstIndex(of: item) else { return }

        if index == pollItems.count - 1 {
            // is the last
            viewModel.createNewPollOptionIfPossible()
            DispatchQueue.main.async {
                self.markLastPollOptionCollectionViewCellBecomeFirstResponser()
            }
        } else {
            // not the last
            let indexAfter = pollItems.index(after: index)
            let itemAfter = pollItems[indexAfter]
            let cell = pollOptionCollectionViewCell(of: itemAfter)
            cell?.pollOptionView.optionTextField.becomeFirstResponder()
        }
    }
    
}

// MARK: - ComposeStatusPollOptionAppendEntryCollectionViewCellDelegate
extension ComposeViewController: ComposeStatusPollOptionAppendEntryCollectionViewCellDelegate {
    func composeStatusPollOptionAppendEntryCollectionViewCellDidPressed(_ cell: ComposeStatusPollOptionAppendEntryCollectionViewCell) {
        viewModel.createNewPollOptionIfPossible()
        DispatchQueue.main.async {
            self.markLastPollOptionCollectionViewCellBecomeFirstResponser()
        }
    }
}

// MARK: - ComposeStatusPollExpiresOptionCollectionViewCellDelegate
extension ComposeViewController: ComposeStatusPollExpiresOptionCollectionViewCellDelegate {
    func composeStatusPollExpiresOptionCollectionViewCell(_ cell: ComposeStatusPollExpiresOptionCollectionViewCell, didSelectExpiresOption expiresOption: ComposeStatusPollItem.PollExpiresOptionAttribute.ExpiresOption) {
        viewModel.pollExpiresOptionAttribute.expiresOption.value = expiresOption
    }
}

// MARK: - AutoCompleteViewControllerDelegate
extension ComposeViewController: AutoCompleteViewControllerDelegate {
    func autoCompleteViewController(_ viewController: AutoCompleteViewController, didSelectItem item: AutoCompleteItem) {
        guard let info = viewModel.autoCompleteInfo.value else { return }
        let _replacedText: String? = {
            var text: String
            switch item {
            case .hashtag(let hashtag):
                text = "#" + hashtag.name
            case .hashtagV1(let hashtagName):
                text = "#" + hashtagName
            case .account(let account):
                text = "@" + account.acct
            case .emoji(let emoji):
                text = ":" + emoji.shortcode + ":"
            case .bottomLoader:
                return nil
            }
            text.append(" ")
            return text
        }()
        guard let replacedText = _replacedText else { return }

        guard let textEditorView = textEditorView(),
              let text = textEditorView.textView.text else { return }


        let range = NSRange(info.toHighlightEndRange, in: text)
        textEditorView.textStorage.replaceCharacters(in: range, with: replacedText)
        viewModel.autoCompleteInfo.value = nil

        switch item {
        case .emoji, .bottomLoader:
            break
        default:
            // set selected range except emoji
            let newRange = NSRange(location: range.location + (replacedText as NSString).length, length: 0)
            guard textEditorView.textStorage.length <= newRange.location else { return }
            textEditorView.textView.selectedRange = newRange
        }
    }
}

extension ComposeViewController {
    override var keyCommands: [UIKeyCommand]? {
        composeKeyCommands
    }
}

extension ComposeViewController {
    
    enum ComposeKeyCommand: String, CaseIterable {
        case discardPost
        case publishPost
        case mediaBrowse
        case mediaPhotoLibrary
        case mediaCamera
        case togglePoll
        case toggleContentWarning
        case selectVisibilityPublic
        // TODO: remove selectVisibilityUnlisted from codebase
        // case selectVisibilityUnlisted
        case selectVisibilityPrivate
        case selectVisibilityDirect

        var title: String {
            switch self {
            case .discardPost:              return L10n.Scene.Compose.Keyboard.discardPost
            case .publishPost:              return L10n.Scene.Compose.Keyboard.publishPost
            case .mediaBrowse:              return L10n.Scene.Compose.Keyboard.appendAttachmentEntry(L10n.Scene.Compose.MediaSelection.browse)
            case .mediaPhotoLibrary:        return L10n.Scene.Compose.Keyboard.appendAttachmentEntry(L10n.Scene.Compose.MediaSelection.photoLibrary)
            case .mediaCamera:              return L10n.Scene.Compose.Keyboard.appendAttachmentEntry(L10n.Scene.Compose.MediaSelection.camera)
            case .togglePoll:               return L10n.Scene.Compose.Keyboard.togglePoll
            case .toggleContentWarning:     return L10n.Scene.Compose.Keyboard.toggleContentWarning
            case .selectVisibilityPublic:   return L10n.Scene.Compose.Keyboard.selectVisibilityEntry(L10n.Scene.Compose.Visibility.public)
            // case .selectVisibilityUnlisted: return L10n.Scene.Compose.Keyboard.selectVisibilityEntry(L10n.Scene.Compose.Visibility.unlisted)
            case .selectVisibilityPrivate:  return L10n.Scene.Compose.Keyboard.selectVisibilityEntry(L10n.Scene.Compose.Visibility.private)
            case .selectVisibilityDirect:   return L10n.Scene.Compose.Keyboard.selectVisibilityEntry(L10n.Scene.Compose.Visibility.direct)
            }
        }
        
        // UIKeyCommand input
        var input: String {
            switch self {
            case .discardPost:              return "w"      // + command
            case .publishPost:              return "\r"     // (enter) + command
            case .mediaBrowse:              return "b"      // + option + command
            case .mediaPhotoLibrary:        return "p"      // + option + command
            case .mediaCamera:              return "c"      // + option + command
            case .togglePoll:               return "p"      // + shift + command
            case .toggleContentWarning:     return "c"      // + shift + command
            case .selectVisibilityPublic:   return "1"      // + command
            // case .selectVisibilityUnlisted: return "2"      // + command
            case .selectVisibilityPrivate:  return "2"      // + command
            case .selectVisibilityDirect:   return "3"      // + command
            }
        }
        
        var modifierFlags: UIKeyModifierFlags {
            switch self {
            case .discardPost:              return [.command]
            case .publishPost:              return [.command]
            case .mediaBrowse:              return [.alternate, .command]
            case .mediaPhotoLibrary:        return [.alternate, .command]
            case .mediaCamera:              return [.alternate, .command]
            case .togglePoll:               return [.shift, .command]
            case .toggleContentWarning:     return [.shift, .command]
            case .selectVisibilityPublic:   return [.command]
            // case .selectVisibilityUnlisted: return [.command]
            case .selectVisibilityPrivate:  return [.command]
            case .selectVisibilityDirect:   return [.command]
            }
        }
        
        var propertyList: Any {
            return rawValue
        }
    }
    
    var composeKeyCommands: [UIKeyCommand]? {
        ComposeKeyCommand.allCases.map { command in
            UIKeyCommand(
                title: command.title,
                image: nil,
                action: #selector(Self.composeKeyCommandHandler(_:)),
                input: command.input,
                modifierFlags: command.modifierFlags,
                propertyList: command.propertyList,
                alternates: [],
                discoverabilityTitle: nil,
                attributes: [],
                state: .off
            )
        }
    }
    
    @objc private func composeKeyCommandHandler(_ sender: UIKeyCommand) {
        guard let rawValue = sender.propertyList as? String,
              let command = ComposeKeyCommand(rawValue: rawValue) else { return }
        
        switch command {
        case .discardPost:
            cancelBarButtonItemPressed(cancelBarButtonItem)
        case .publishPost:
            publishBarButtonItemPressed(publishBarButtonItem)
        case .mediaBrowse:
            present(documentPickerController, animated: true, completion: nil)
        case .mediaPhotoLibrary:
            present(photoLibraryPicker, animated: true, completion: nil)
        case .mediaCamera:
            guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                return
            }
            present(imagePickerController, animated: true, completion: nil)
        case .togglePoll:
            composeToolbarView.pollButton.sendActions(for: .touchUpInside)
        case .toggleContentWarning:
            composeToolbarView.contentWarningButton.sendActions(for: .touchUpInside)
        case .selectVisibilityPublic:
            viewModel.selectedStatusVisibility.value = .public
        // case .selectVisibilityUnlisted:
        //     viewModel.selectedStatusVisibility.value = .unlisted
        case .selectVisibilityPrivate:
            viewModel.selectedStatusVisibility.value = .private
        case .selectVisibilityDirect:
            viewModel.selectedStatusVisibility.value = .direct
        }
    }
    
}
