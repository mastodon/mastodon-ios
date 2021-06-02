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
import Kingfisher
import MastodonSDK
import TwitterTextEditor

final class ComposeViewController: UIViewController, NeedsDependency {
    
    static let minAutoCompleteVisibleHeight: CGFloat = 100
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ComposeViewModel!
    
    private var suffixedAttachmentViews: [UIView] = []
    
    let publishButton: UIButton = {
        let button = RoundedEdgesButton(type: .custom)
        button.setTitle(L10n.Scene.Compose.composeAction, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        button.setBackgroundImage(.placeholder(color: Asset.Colors.Button.normal.color), for: .normal)
        button.setBackgroundImage(.placeholder(color: Asset.Colors.Button.normal.color.withAlphaComponent(0.5)), for: .highlighted)
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
    
    let collectionView: ComposeCollectionView = {
        let collectionViewLayout = ComposeViewController.createLayout()
        let collectionView = ComposeCollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.register(ComposeRepliedToStatusContentCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ComposeRepliedToStatusContentCollectionViewCell.self))
        collectionView.register(ComposeStatusContentCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ComposeStatusContentCollectionViewCell.self))
        collectionView.register(ComposeStatusAttachmentCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ComposeStatusAttachmentCollectionViewCell.self))
        collectionView.register(ComposeStatusPollOptionCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ComposeStatusPollOptionCollectionViewCell.self))
        collectionView.register(ComposeStatusPollOptionAppendEntryCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ComposeStatusPollOptionAppendEntryCollectionViewCell.self))
        collectionView.register(ComposeStatusPollExpiresOptionCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ComposeStatusPollExpiresOptionCollectionViewCell.self))
        collectionView.backgroundColor = Asset.Scene.Compose.background.color
        collectionView.alwaysBounceVertical = true
        return collectionView
    }()
    
    var systemKeyboardHeight: CGFloat = .zero {
        didSet {
            // note: some system AutoLayout warning here
            customEmojiPickerInputView.frame.size.height = systemKeyboardHeight != .zero ? systemKeyboardHeight : 300
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
        view.backgroundColor = Asset.Scene.Compose.background.color
        navigationItem.leftBarButtonItem = cancelBarButtonItem
        navigationItem.rightBarButtonItem = publishBarButtonItem
        publishButton.addTarget(self, action: #selector(ComposeViewController.publishBarButtonItemPressed(_:)), for: .touchUpInside)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
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
        
        collectionView.delegate = self
        viewModel.setupDiffableDataSource(
            for: collectionView,
            dependency: self,
            customEmojiPickerInputViewModel: viewModel.customEmojiPickerInputViewModel,
            textEditorViewTextAttributesDelegate: self,
            textEditorViewChangeObserver: self,
            composeStatusAttachmentTableViewCellDelegate: self,
            composeStatusPollOptionCollectionViewCellDelegate: self,
            composeStatusNewPollOptionCollectionViewCellDelegate: self,
            composeStatusPollExpiresOptionCollectionViewCellDelegate: self
        )
        let longPressReorderGesture = UILongPressGestureRecognizer(target: self, action: #selector(ComposeViewController.longPressReorderGestureHandler(_:)))
        collectionView.addGestureRecognizer(longPressReorderGesture)
        
        customEmojiPickerInputView.collectionView.delegate = self
        viewModel.customEmojiPickerInputViewModel.customEmojiPickerInputView = customEmojiPickerInputView
        viewModel.setupCustomEmojiPickerDiffableDataSource(
            for: customEmojiPickerInputView.collectionView,
            dependency: self
        )
        
        // update layout when keyboard show/dismiss
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
            
            // update keyboard background color

            guard isShow, state == .dock else {
                self.collectionView.contentInset.bottom = self.view.safeAreaInsets.bottom + extraMargin
                self.collectionView.verticalScrollIndicatorInsets.bottom = self.view.safeAreaInsets.bottom + extraMargin
            
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
                self.updateKeyboardBackground(isKeyboardDisplay: isShow)
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
            
            // adjust inset for collectionView
            let contentFrame = self.view.convert(self.collectionView.frame, to: nil)
            let padding = contentFrame.maxY + extraMargin - endFrame.minY
            guard padding > 0 else {
                self.collectionView.contentInset.bottom = self.view.safeAreaInsets.bottom + extraMargin
                self.collectionView.verticalScrollIndicatorInsets.bottom = self.view.safeAreaInsets.bottom + extraMargin

                self.updateKeyboardBackground(isKeyboardDisplay: false)
                return
            }

            self.collectionView.contentInset.bottom = padding
            self.collectionView.verticalScrollIndicatorInsets.bottom = padding
            UIView.animate(withDuration: 0.3) {
                self.composeToolbarViewBottomLayoutConstraint.constant = endFrame.height
                self.view.layoutIfNeeded()
            }
            self.updateKeyboardBackground(isKeyboardDisplay: isShow)
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
                    textEditorView.superview!.addSubview(self.autoCompleteViewController.view)
                    self.addChild(self.autoCompleteViewController)
                    self.autoCompleteViewController.didMove(toParent: self)
                    self.autoCompleteViewController.view.isHidden = true
                    self.collectionView.autoCompleteViewController = self.autoCompleteViewController
                }
                self.autoCompleteViewController.view.isHidden = info == nil
                guard let info = info else { return }
                let symbolBoundingRectInContainer = textEditorView.convert(info.symbolBoundingRect, to: self.autoCompleteViewController.chevronView)
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
                    self.composeToolbarView.characterCountLabel.font = .systemFont(ofSize: 24, weight: .bold)
                    self.composeToolbarView.characterCountLabel.textColor = Asset.Colors.danger.color
                    self.composeToolbarView.characterCountLabel.accessibilityLabel = L10n.Scene.Compose.Accessibility.inputLimitExceedsCount(abs(count))
                default:
                    self.composeToolbarView.characterCountLabel.font = .systemFont(ofSize: 15, weight: .regular)
                    self.composeToolbarView.characterCountLabel.textColor = Asset.Colors.Label.secondary.color
                    self.composeToolbarView.characterCountLabel.accessibilityLabel = L10n.Scene.Compose.Accessibility.inputLimitRemainsCount(count)
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
            viewModel.repliedToCellFrame.removeDuplicates().eraseToAnyPublisher(),
            viewModel.collectionViewState.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] repliedToCellFrame, collectionViewState in
            guard let self = self else { return }
            guard repliedToCellFrame != .zero else { return }
            switch collectionViewState {
            case .fold:
                self.collectionView.contentInset.top = -repliedToCellFrame.height
            case .expand:
                self.collectionView.contentInset.top = 0
            }
        }
        .store(in: &disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Fix AutoLayout conflict issue
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.markTextEditorViewBecomeFirstResponser()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        viewModel.traitCollectionDidChangePublisher.send()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // pin autoCompleteViewController frame to window
        if let containerView = autoCompleteViewController.view.superview {
            let viewFrameInWindow = containerView.convert(autoCompleteViewController.view.frame, to: nil)
            if viewFrameInWindow.origin.x != 0 {
                autoCompleteViewController.view.frame.origin.x = -viewFrameInWindow.origin.x
            }
        }
    }
    
}

extension ComposeViewController {
    
    private func textEditorView() -> TextEditorView? {
        guard let diffableDataSource = viewModel.diffableDataSource else { return nil }
        let items = diffableDataSource.snapshot().itemIdentifiers
        for item in items {
            switch item {
            case .input:
                guard let indexPath = diffableDataSource.indexPath(for: item),
                      let cell = collectionView.cellForItem(at: indexPath) as? ComposeStatusContentCollectionViewCell else {
                    continue
                }
                return cell.textEditorView
            default:
                continue
            }
        }
        
        return nil
    }
    
    private func markTextEditorViewBecomeFirstResponser() {
        textEditorView()?.isEditing = true
    }
    
    private func contentWarningEditorTextView() -> UITextView? {
        guard let diffableDataSource = viewModel.diffableDataSource else { return nil }
        let items = diffableDataSource.snapshot().itemIdentifiers
        for item in items {
            switch item {
            case .input:
                guard let indexPath = diffableDataSource.indexPath(for: item),
                      let cell = collectionView.cellForItem(at: indexPath) as? ComposeStatusContentCollectionViewCell else {
                    continue
                }
                return cell.statusContentWarningEditorView.textView
            default:
                continue
            }
        }
        
        return nil
    }
    
    private func pollOptionCollectionViewCell(of item: ComposeStatusItem) -> ComposeStatusPollOptionCollectionViewCell? {
        guard case .pollOption = item else { return nil }
        guard let diffableDataSource = viewModel.diffableDataSource else { return nil }
        guard let indexPath = diffableDataSource.indexPath(for: item),
              let cell = collectionView.cellForItem(at: indexPath) as? ComposeStatusPollOptionCollectionViewCell else {
            return nil
        }
        
        return cell
    }
    
    private func firstPollOptionCollectionViewCell() -> ComposeStatusPollOptionCollectionViewCell? {
        guard let diffableDataSource = viewModel.diffableDataSource else { return nil }
        let items = diffableDataSource.snapshot().itemIdentifiers(inSection: .poll)
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
        guard let diffableDataSource = viewModel.diffableDataSource else { return nil }
        let items = diffableDataSource.snapshot().itemIdentifiers(inSection: .poll)
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
    
    private func updateKeyboardBackground(isKeyboardDisplay: Bool) {
        guard isKeyboardDisplay else {
            composeToolbarBackgroundView.backgroundColor = Asset.Scene.Compose.toolbarBackground.color
            return
        }
        composeToolbarBackgroundView.backgroundColor = UIColor(dynamicProvider: { traitCollection -> UIColor in
            // avoid elevated color
            switch traitCollection.userInterfaceStyle {
            case .light:        return .white
            default:            return .black
            }
        })
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
    
    // seealso: ComposeViewModel.setupDiffableDataSource(…)
    @objc private func longPressReorderGestureHandler(_ sender: UILongPressGestureRecognizer) {
        switch(sender.state) {
        case .began:
            guard let selectedIndexPath = collectionView.indexPathForItem(at: sender.location(in: collectionView)),
                  let cell = collectionView.cellForItem(at: selectedIndexPath) as? ComposeStatusPollOptionCollectionViewCell else {
                break
            }
            // check if pressing reorder bar no not
            let locationInCell = sender.location(in: cell)
            guard cell.reorderBarImageView.frame.contains(locationInCell) else {
                return
            }
            
            collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            guard let selectedIndexPath = collectionView.indexPathForItem(at: sender.location(in: collectionView)),
                  let diffableDataSource = viewModel.diffableDataSource else {
                break
            }
            guard let item = diffableDataSource.itemIdentifier(for: selectedIndexPath),
                  case .pollOption = item else {
                collectionView.cancelInteractiveMovement()
                return
            }

            var position = sender.location(in: collectionView)
            position.x = collectionView.frame.width * 0.5
            collectionView.updateInteractiveMovementTargetPosition(position)
        case .ended:
            collectionView.endInteractiveMovement()
            collectionView.reloadData()
        default:
            collectionView.cancelInteractiveMovement()
        }
    }
    
}

// MARK: - TextEditorViewTextAttributesDelegate
extension ComposeViewController: TextEditorViewTextAttributesDelegate {
    
    func textEditorView(
        _ textEditorView: TextEditorView,
        updateAttributedString attributedString: NSAttributedString,
        completion: @escaping (NSAttributedString?) -> Void
    ) {
        // FIXME: needs O(1) update completion to fix profermance issue
        DispatchQueue.global().async {
            let string = attributedString.string
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: update: %s", ((#file as NSString).lastPathComponent), #line, #function, string)

            let stringRange = NSRange(location: 0, length: string.length)
            let highlightMatches = string.matches(pattern: MastodonRegex.highlightPattern)
            let emojiMatches = string.matches(pattern: MastodonRegex.emojiPattern)
            // only accept http/https scheme
            let urlMatches = string.matches(pattern: "(?i)https?://\\S+(?:/|\\b)")

            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    completion(nil)
                    return
                }
                let customEmojiViewModel = self.viewModel.customEmojiViewModel.value
                for view in self.suffixedAttachmentViews {
                    view.removeFromSuperview()
                }
                self.suffixedAttachmentViews.removeAll()

                // set normal apperance
                let attributedString = NSMutableAttributedString(attributedString: attributedString)
                attributedString.removeAttribute(.suffixedAttachment, range: stringRange)
                attributedString.removeAttribute(.underlineStyle, range: stringRange)
                attributedString.addAttribute(.foregroundColor, value: Asset.Colors.Label.primary.color, range: stringRange)
                attributedString.addAttribute(.font, value: UIFont.preferredFont(forTextStyle: .body), range: stringRange)

                // hashtag
                for match in highlightMatches {
                    // set highlight
                    var attributes = [NSAttributedString.Key: Any]()
                    attributes[.foregroundColor] = Asset.Colors.Label.highlight.color
                    
                    // See `traitCollectionDidChange(_:)`
                    // set accessibility
                    if #available(iOS 13.0, *) {
                        switch self.traitCollection.accessibilityContrast {
                        case .high:
                            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
                        default:
                            break
                        }
                    }
                    attributedString.addAttributes(attributes, range: match.range)
                }
                
                // emoji
                if let customEmojiViewModel = customEmojiViewModel, !customEmojiViewModel.emojiDict.value.isEmpty {
                    for match in emojiMatches {
                        guard let name = string.substring(with: match, at: 2) else { continue }
                        guard let emoji = customEmojiViewModel.emoji(shortcode: name) else { continue }
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: handle emoji: %s", ((#file as NSString).lastPathComponent), #line, #function, name)
                        
                        // set emoji token invisiable (without upper bounce space)
                        var attributes = [NSAttributedString.Key: Any]()
                        attributes[.font] = UIFont.systemFont(ofSize: 0.01)
                        attributedString.addAttributes(attributes, range: match.range)
                        
                        // append emoji attachment
                        let imageViewSize = CGSize(width: 20, height: 20)
                        let imageView = UIImageView(frame: CGRect(origin: .zero, size: imageViewSize))
                        textEditorView.textContentView.addSubview(imageView)
                        self.suffixedAttachmentViews.append(imageView)
                        let processor = DownsamplingImageProcessor(size: imageViewSize)
                        imageView.kf.setImage(
                            with: URL(string: emoji.url),
                            placeholder: UIImage.placeholder(size: imageViewSize, color: .systemFill),
                            options: [
                                .processor(processor),
                                .scaleFactor(textEditorView.traitCollection.displayScale),
                            ], completionHandler: nil
                        )
                        let layoutInTextContainer = { [weak textEditorView] (view: UIView, frame: CGRect) in
                            // `textEditorView` retains `textStorage`, which retains this block as a part of attributes.
                            guard let textEditorView = textEditorView else {
                                return
                            }
                            let insets = textEditorView.textContentInsets
                            view.frame = frame.offsetBy(dx: insets.left, dy: insets.top)
                        }
                        let attachment = TextAttributes.SuffixedAttachment(
                            size: imageViewSize,
                            attachment: .view(view: imageView, layoutInTextContainer: layoutInTextContainer)
                        )
                        let index = match.range.upperBound - 1
                        attributedString.addAttribute(
                            .suffixedAttachment,
                            value: attachment,
                            range: NSRange(location: index, length: 1)
                        )
                    }
                }
                
                // url
                for match in urlMatches {
                    guard let name = string.substring(with: match, at: 0) else { continue }
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: handle emoji: %s", ((#file as NSString).lastPathComponent), #line, #function, name)
                    
                    // set highlight
                    var attributes = [NSAttributedString.Key: Any]()
                    attributes[.foregroundColor] = Asset.Colors.Label.highlight.color
                    
                    // See `traitCollectionDidChange(_:)`
                    // set accessibility
                    if #available(iOS 13.0, *) {
                        switch self.traitCollection.accessibilityContrast {
                        case .high:
                            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
                        default:
                            break
                        }
                    }
                    attributedString.addAttributes(attributes, range: match.range)
                }
                
                if string.count > ComposeViewModel.composeContentLimit {
                    var attributes = [NSAttributedString.Key: Any]()
                    attributes[.foregroundColor] = Asset.Colors.danger.color
                    let boundStart = string.index(string.startIndex, offsetBy: ComposeViewModel.composeContentLimit)
                    let boundEnd = string.endIndex
                    let range = boundStart..<boundEnd
                    attributedString.addAttributes(attributes, range: NSRange(range, in: string))
                }
                
                completion(attributedString)
            }
        }
    }
    
}

// MARK: - TextEditorViewChangeObserver
extension ComposeViewController: TextEditorViewChangeObserver {
    
    func textEditorView(_ textEditorView: TextEditorView, didChangeWithChangeResult changeResult: TextEditorViewChangeResult) {
        guard var autoCompeletion = ComposeViewController.scanAutoCompleteInfo(textEditorView: textEditorView) else {
            viewModel.autoCompleteInfo.value = nil
            return
        }
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: auto complete %s (%s)", ((#file as NSString).lastPathComponent), #line, #function, String(autoCompeletion.toHighlightEndString), String(autoCompeletion.toCursorString))

        // get layout text bounding rect
        var glyphRange = NSRange()
        textEditorView.layoutManager.characterRange(forGlyphRange: NSRange(autoCompeletion.toCursorRange, in: textEditorView.text), actualGlyphRange: &glyphRange)
        let textContainer = textEditorView.layoutManager.textContainers[0]
        let textBoundingRect = textEditorView.layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        
        let retryLayoutTimes = viewModel.autoCompleteRetryLayoutTimes.value
        guard textBoundingRect.size != .zero else {
            viewModel.autoCompleteRetryLayoutTimes.value += 1
            // avoid infinite loop
            guard retryLayoutTimes < 3 else { return }
            // needs retry calculate layout when the rect position changing
            DispatchQueue.main.async {
                self.textEditorView(textEditorView, didChangeWithChangeResult: changeResult)
            }
            return
        }
        viewModel.autoCompleteRetryLayoutTimes.value = 0
        
        // get symbol bounding rect
        textEditorView.layoutManager.characterRange(forGlyphRange: NSRange(autoCompeletion.symbolRange, in: textEditorView.text), actualGlyphRange: &glyphRange)
        let symbolBoundingRect = textEditorView.layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        
        // set bounding rect and trigger layout
        autoCompeletion.textBoundingRect = textBoundingRect
        autoCompeletion.symbolBoundingRect = symbolBoundingRect
        viewModel.autoCompleteInfo.value = autoCompeletion
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
    
    private static func scanAutoCompleteInfo(textEditorView: TextEditorView) -> AutoCompleteInfo? {
        let text = textEditorView.text

        guard textEditorView.selectedRange.location > 0, !text.isEmpty,
              let selectedRange = Range(textEditorView.selectedRange, in: text) else {
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
        viewModel.isPollComposing.value.toggle()
        
        // setup initial poll option if needs
        if viewModel.isPollComposing.value, viewModel.pollOptionAttributes.value.isEmpty {
            viewModel.pollOptionAttributes.value = [ComposeStatusItem.ComposePollOptionAttribute(), ComposeStatusItem.ComposePollOptionAttribute()]
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
        guard scrollView === collectionView else { return }

        let repliedToCellFrame = viewModel.repliedToCellFrame.value
        guard repliedToCellFrame != .zero else { return }
        let throttle = viewModel.repliedToCellFrame.value.height - scrollView.adjustedContentInset.top
        // print("\(throttle) - \(scrollView.contentOffset.y)")

        switch viewModel.collectionViewState.value {
        case .fold:
            if scrollView.contentOffset.y < throttle {
                viewModel.collectionViewState.value = .expand
            }
            os_log("%{public}s[%{public}ld], %{public}s: fold", ((#file as NSString).lastPathComponent), #line, #function)

        case .expand:
            if scrollView.contentOffset.y > -44 {
                viewModel.collectionViewState.value = .fold
                os_log("%{public}s[%{public}ld], %{public}s: expand", ((#file as NSString).lastPathComponent), #line, #function)
            }
        }
    }
}

// MARK: - UICollectionViewDelegate
extension ComposeViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: select %s", ((#file as NSString).lastPathComponent), #line, #function, indexPath.debugDescription)

        if collectionView === customEmojiPickerInputView.collectionView {
            guard let diffableDataSource = viewModel.customEmojiPickerDiffableDataSource else { return }
            let item = diffableDataSource.itemIdentifier(for: indexPath)
            guard case let .emoji(attribute) = item else { return }
            let emoji = attribute.emoji
            let textEditorView = self.textEditorView()
            
            // retrive active text input and insert emoji
            // the leading and trailing space is REQUIRED to fix `UITextStorage` layout issue
            let reference = viewModel.customEmojiPickerInputViewModel.insertText(" :\(emoji.shortcode): ")
            
            // workaround: non-user interactive change do not trigger value update event
            if reference?.value === textEditorView {
                viewModel.composeStatusAttribute.composeContent.value = textEditorView?.text
                // update text storage
                textEditorView?.setNeedsUpdateTextAttributes()
                // collection self-size
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.collectionView.collectionViewLayout.invalidateLayout()
                }
            }
        } else {
            // do nothing
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension ComposeViewController: UIAdaptivePresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .fullScreen
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
                initalAuthenticationBox: viewModel.activeAuthenticationBox.value
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
            initalAuthenticationBox: viewModel.activeAuthenticationBox.value
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
            initalAuthenticationBox: viewModel.activeAuthenticationBox.value
        )
        viewModel.attachmentServices.value = viewModel.attachmentServices.value + [attachmentService]
    }
}

// MARK: - ComposeStatusAttachmentTableViewCellDelegate
extension ComposeViewController: ComposeStatusAttachmentCollectionViewCellDelegate {
    
    func composeStatusAttachmentCollectionViewCell(_ cell: ComposeStatusAttachmentCollectionViewCell, removeButtonDidPressed button: UIButton) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
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
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        guard case let .pollOption(attribute) = item else { return }
        
        var pollAttributes = viewModel.pollOptionAttributes.value
        guard let index = pollAttributes.firstIndex(of: attribute) else { return }
    
        // mark previous (fallback to next) item of removed middle poll option become first responder
        let pollItems = diffableDataSource.snapshot().itemIdentifiers(inSection: .poll)
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
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let pollItems = diffableDataSource.snapshot().itemIdentifiers(inSection: .poll).filter { item in
            guard case .pollOption = item else { return false }
            return true
        }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
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
    func composeStatusPollExpiresOptionCollectionViewCell(_ cell: ComposeStatusPollExpiresOptionCollectionViewCell, didSelectExpiresOption expiresOption: ComposeStatusItem.ComposePollExpiresOptionAttribute.ExpiresOption) {
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

        guard let textEditorView = textEditorView() else { return }
        let text = textEditorView.text
        
        do {
            try textEditorView.updateByReplacing(range: NSRange(info.toHighlightEndRange, in: text), with: replacedText)
            viewModel.autoCompleteInfo.value = nil
        } catch {
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: auto complete fail %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
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
        case selectVisibilityUnlisted
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
            case .selectVisibilityUnlisted: return L10n.Scene.Compose.Keyboard.selectVisibilityEntry(L10n.Scene.Compose.Visibility.unlisted)
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
            case .selectVisibilityUnlisted: return "2"      // + command
            case .selectVisibilityPrivate:  return "3"      // + command
            case .selectVisibilityDirect:   return "4"      // + command
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
            case .selectVisibilityUnlisted: return [.command]
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
        case .selectVisibilityUnlisted:
            viewModel.selectedStatusVisibility.value = .unlisted
        case .selectVisibilityPrivate:
            viewModel.selectedStatusVisibility.value = .private
        case .selectVisibilityDirect:
            viewModel.selectedStatusVisibility.value = .direct
        }
    }
    
}
