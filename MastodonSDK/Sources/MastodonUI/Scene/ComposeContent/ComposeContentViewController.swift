//
//  ComposeContentViewController.swift
//  
//
//  Created by MainasuK on 22/9/30.
//

import os.log
import UIKit
import SwiftUI
import Combine
import PhotosUI
import MastodonCore

public final class ComposeContentViewController: UIViewController {
    
    static let minAutoCompleteVisibleHeight: CGFloat = 100

    let logger = Logger(subsystem: "ComposeContentViewController", category: "ViewController")
    
    var disposeBag = Set<AnyCancellable>()
    public var viewModel: ComposeContentViewModel!
    private(set) lazy var composeContentToolbarViewModel = ComposeContentToolbarView.ViewModel(delegate: self)
    
    // tableView container
    let tableView: ComposeTableView = {
        let tableView = ComposeTableView()
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.alwaysBounceVertical = true
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
    // auto complete
    private(set) lazy var autoCompleteViewController: AutoCompleteViewController = {
        let viewController = AutoCompleteViewController()
        viewController.viewModel = AutoCompleteViewModel(context: viewModel.context, authContext: viewModel.authContext)
        viewController.delegate = self
        // viewController.viewModel.customEmojiViewModel.value = viewModel.customEmojiViewModel
        return viewController
    }()
    
    // toolbar
    lazy var composeContentToolbarView = ComposeContentToolbarView(viewModel: composeContentToolbarViewModel)
    var composeContentToolbarViewBottomLayoutConstraint: NSLayoutConstraint!
    let composeContentToolbarBackgroundView = UIView()
    
    // media picker
    
    static func createPhotoLibraryPickerConfiguration(selectionLimit: Int = 4) -> PHPickerConfiguration {
        var configuration = PHPickerConfiguration()
        configuration.filter = .any(of: [.images, .videos])
        configuration.selectionLimit = selectionLimit
        return configuration
    }

    public private(set) lazy var photoLibraryPicker: PHPickerViewController = {
        let imagePicker = PHPickerViewController(configuration: ComposeContentViewController.createPhotoLibraryPickerConfiguration())
        imagePicker.delegate = self
        return imagePicker
    }()
    
    public private(set) lazy var imagePickerController: UIImagePickerController = {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .camera
        imagePickerController.delegate = self
        return imagePickerController
    }()

    public private(set) lazy var documentPickerController: UIDocumentPickerViewController = {
        let documentPickerController = UIDocumentPickerViewController(forOpeningContentTypes: [.image, .movie])
        documentPickerController.delegate = self
        return documentPickerController
    }()
    
    // emoji picker inputView
    let customEmojiPickerInputView: CustomEmojiPickerInputView = {
        let view = CustomEmojiPickerInputView(
            frame: CGRect(x: 0, y: 0, width: 0, height: 300),
            inputViewStyle: .keyboard
        )
        return view
    }()

    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }

}

extension ComposeContentViewController {
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.delegate = self
        
        // setup view
        self.setupBackgroundColor(theme: ThemeService.shared.currentTheme.value)
        ThemeService.shared.currentTheme
            .receive(on: RunLoop.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.setupBackgroundColor(theme: theme)
            }
            .store(in: &disposeBag)
        
        // setup tableView
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.pinToParent()
        
        tableView.delegate = self
        viewModel.setupDataSource(tableView: tableView)
        
        // setup emoji picker
        customEmojiPickerInputView.collectionView.delegate = self
        viewModel.customEmojiPickerInputViewModel.customEmojiPickerInputView = customEmojiPickerInputView
        viewModel.setupCustomEmojiPickerDiffableDataSource(collectionView: customEmojiPickerInputView.collectionView)
        
        // setup toolbar
        let toolbarHostingView = UIHostingController(rootView: composeContentToolbarView)
        toolbarHostingView.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbarHostingView.view)
        composeContentToolbarViewBottomLayoutConstraint = view.bottomAnchor.constraint(equalTo: toolbarHostingView.view.bottomAnchor)
        NSLayoutConstraint.activate([
            toolbarHostingView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarHostingView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            composeContentToolbarViewBottomLayoutConstraint,
            toolbarHostingView.view.heightAnchor.constraint(equalToConstant: ComposeContentToolbarView.toolbarHeight),
        ])
        toolbarHostingView.view.preservesSuperviewLayoutMargins = true
        //composeToolbarView.delegate = self
        
        composeContentToolbarBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(composeContentToolbarBackgroundView, belowSubview: toolbarHostingView.view)
        NSLayoutConstraint.activate([
            composeContentToolbarBackgroundView.topAnchor.constraint(equalTo: toolbarHostingView.view.topAnchor),
            composeContentToolbarBackgroundView.leadingAnchor.constraint(equalTo: toolbarHostingView.view.leadingAnchor),
            composeContentToolbarBackgroundView.trailingAnchor.constraint(equalTo: toolbarHostingView.view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: composeContentToolbarBackgroundView.bottomAnchor),
        ])
        
        // bind keyboard
        let keyboardEventPublishers = Publishers.CombineLatest3(
            KeyboardResponderService.shared.isShow,
            KeyboardResponderService.shared.state,
            KeyboardResponderService.shared.endFrame
        )
        Publishers.CombineLatest3(
            keyboardEventPublishers,
            viewModel.$isEmojiActive,
            viewModel.$autoCompleteInfo
        )
        .sink(receiveValue: { [weak self] keyboardEvents, isEmojiActive, autoCompleteInfo in
            guard let self = self else { return }
            
            let (isShow, state, endFrame) = keyboardEvents
    
            let extraMargin: CGFloat = {
                var margin = ComposeContentToolbarView.toolbarHeight
                if autoCompleteInfo != nil {
                    margin += ComposeContentViewController.minAutoCompleteVisibleHeight
                }
                return margin
            }()
            
            guard isShow, state == .dock else {
                self.tableView.contentInset.bottom = extraMargin
                self.tableView.verticalScrollIndicatorInsets.bottom = extraMargin

                if let superView = self.autoCompleteViewController.tableView.superview {
                    let autoCompleteTableViewBottomInset: CGFloat = {
                        let tableViewFrameInWindow = superView.convert(self.autoCompleteViewController.tableView.frame, to: nil)
                        let padding = tableViewFrameInWindow.maxY + ComposeContentToolbarView.toolbarHeight + AutoCompleteViewController.chevronViewHeight - self.view.frame.maxY
                        return max(0, padding)
                    }()
                    self.autoCompleteViewController.tableView.contentInset.bottom = autoCompleteTableViewBottomInset
                    self.autoCompleteViewController.tableView.verticalScrollIndicatorInsets.bottom = autoCompleteTableViewBottomInset
                }

                UIView.animate(withDuration: 0.3) {
                    self.composeContentToolbarViewBottomLayoutConstraint.constant = self.view.safeAreaInsets.bottom
                    if self.view.window != nil {
                        self.view.layoutIfNeeded()
                    }
                }
                return
            }
            // isShow AND dock state

            // adjust inset for auto-complete
            let autoCompleteTableViewBottomInset: CGFloat = {
                guard let superview = self.autoCompleteViewController.tableView.superview else { return .zero }
                let tableViewFrameInWindow = superview.convert(self.autoCompleteViewController.tableView.frame, to: nil)
                let padding = tableViewFrameInWindow.maxY + ComposeContentToolbarView.toolbarHeight + AutoCompleteViewController.chevronViewHeight - endFrame.minY
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
                self.composeContentToolbarViewBottomLayoutConstraint.constant = endFrame.height
                self.view.layoutIfNeeded()
            }
        })
        .store(in: &disposeBag)
        
        // setup snap behavior
        Publishers.CombineLatest(
            viewModel.$replyToCellFrame,
            viewModel.$scrollViewState
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] replyToCellFrame, scrollViewState in
            guard let self = self else { return }
            guard replyToCellFrame != .zero else { return }
            switch scrollViewState {
            case .fold:
                self.tableView.contentInset.top = -replyToCellFrame.height
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: set contentInset.top: -%s", ((#file as NSString).lastPathComponent), #line, #function, replyToCellFrame.height.description)
            case .expand:
                self.tableView.contentInset.top = 0
            }
        }
        .store(in: &disposeBag)
        
        // bind auto-complete
        viewModel.$autoCompleteInfo
            .receive(on: DispatchQueue.main)
            .sink { [weak self] info in
                guard let self = self else { return }
                guard let textView = self.viewModel.contentMetaText?.textView else { return }
                if self.autoCompleteViewController.view.superview == nil {
                    self.autoCompleteViewController.view.frame = self.view.bounds
                    // add to container view. seealso: `viewDidLayoutSubviews()`
                    self.viewModel.composeContentTableViewCell.contentView.addSubview(self.autoCompleteViewController.view)
                    self.addChild(self.autoCompleteViewController)
                    self.autoCompleteViewController.didMove(toParent: self)
                    self.autoCompleteViewController.view.isHidden = true
                    self.tableView.autoCompleteViewController = self.autoCompleteViewController
                }
                self.updateAutoCompleteViewControllerLayout()
                self.autoCompleteViewController.view.isHidden = info == nil
                guard let info = info else { return }
                let symbolBoundingRectInContainer = textView.convert(info.symbolBoundingRect, to: self.autoCompleteViewController.chevronView)
                print(info.symbolBoundingRect)
                self.autoCompleteViewController.view.frame.origin.y = info.textBoundingRect.maxY + self.viewModel.contentTextViewFrame.minY
                self.autoCompleteViewController.viewModel.symbolBoundingRect.value = symbolBoundingRectInContainer
                self.autoCompleteViewController.viewModel.inputText.value = String(info.inputText)
            }
            .store(in: &disposeBag)
        
        // bind emoji picker
        viewModel.customEmojiViewModel?.emojis
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
        
        // bind toolbar
        bindToolbarViewModel()
        
        // bind attachment picker
        viewModel.$attachmentViewModels
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.resetImagePicker()
            }
            .store(in: &disposeBag)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        viewModel.viewLayoutFrame.update(view: view)
        updateAutoCompleteViewControllerLayout()
    }
    
    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        viewModel.viewLayoutFrame.update(view: view)
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { [weak self] coordinatorContext in
            guard let self = self else { return }
            self.viewModel.viewLayoutFrame.update(view: self.view)
        }
    }
}

extension ComposeContentViewController {
    private func setupBackgroundColor(theme: Theme) {
        let backgroundColor = UIColor(dynamicProvider: { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .light: return .systemBackground
            default:     return theme.systemElevatedBackgroundColor
            }
        })
        view.backgroundColor = backgroundColor
        tableView.backgroundColor = backgroundColor
        composeContentToolbarBackgroundView.backgroundColor = theme.composeToolbarBackgroundColor
    }
    
    private func bindToolbarViewModel() {
        viewModel.$isAttachmentButtonEnabled.assign(to: &composeContentToolbarViewModel.$isAttachmentButtonEnabled)
        viewModel.$isPollButtonEnabled.assign(to: &composeContentToolbarViewModel.$isPollButtonEnabled)
        viewModel.$isPollActive.assign(to: &composeContentToolbarViewModel.$isPollActive)
        viewModel.$isEmojiActive.assign(to: &composeContentToolbarViewModel.$isEmojiActive)
        viewModel.$isContentWarningActive.assign(to: &composeContentToolbarViewModel.$isContentWarningActive)
        viewModel.$visibility.assign(to: &composeContentToolbarViewModel.$visibility)
        viewModel.$maxTextInputLimit.assign(to: &composeContentToolbarViewModel.$maxTextInputLimit)
        viewModel.$contentWeightedLength.assign(to: &composeContentToolbarViewModel.$contentWeightedLength)
        viewModel.$contentWarningWeightedLength.assign(to: &composeContentToolbarViewModel.$contentWarningWeightedLength)
        
        // bind back to source due to visibility not update via delegate
        composeContentToolbarViewModel.$visibility
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] visibility in
                guard let self = self else { return }
                if self.viewModel.visibility != visibility {
                    self.viewModel.visibility = visibility
                }
            }
            .store(in: &disposeBag)
    }
    
    private func updateAutoCompleteViewControllerLayout() {
        // pin autoCompleteViewController frame to current view
        if let containerView = autoCompleteViewController.view.superview {
            let viewFrameInWindow = containerView.convert(autoCompleteViewController.view.frame, to: view)
            if viewFrameInWindow.origin.x != 0 {
                autoCompleteViewController.view.frame.origin.x = -viewFrameInWindow.origin.x
            }
            autoCompleteViewController.view.frame.size.width = view.frame.width
        }
    }
    
    private func resetImagePicker() {
        let selectionLimit = max(1, viewModel.maxMediaAttachmentLimit - viewModel.attachmentViewModels.count)
        let configuration = ComposeContentViewController.createPhotoLibraryPickerConfiguration(selectionLimit: selectionLimit)
        photoLibraryPicker = createImagePicker(configuration: configuration)
    }
    
    private func createImagePicker(configuration: PHPickerConfiguration) -> PHPickerViewController {
        let imagePicker = PHPickerViewController(configuration: configuration)
        imagePicker.delegate = self
        return imagePicker
    }
}

// MARK: - UIScrollViewDelegate
extension ComposeContentViewController {
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard scrollView === tableView else { return }

        let replyToCellFrame = viewModel.replyToCellFrame
        guard replyToCellFrame != .zero else { return }

        // try to find some patterns:
        // print("""
        // repliedToCellFrame: \(viewModel.repliedToCellFrame.value.height)
        // scrollView.contentOffset.y: \(scrollView.contentOffset.y)
        // scrollView.contentSize.height: \(scrollView.contentSize.height)
        // scrollView.frame: \(scrollView.frame)
        // scrollView.adjustedContentInset.top: \(scrollView.adjustedContentInset.top)
        // scrollView.adjustedContentInset.bottom: \(scrollView.adjustedContentInset.bottom)
        // """)

        switch viewModel.scrollViewState {
        case .fold:
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fold")
            guard velocity.y < 0 else { return }
            let offsetY = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
            if offsetY < -44 {
                tableView.contentInset.top = 0
                targetContentOffset.pointee = CGPoint(x: 0, y: -scrollView.adjustedContentInset.top)
                viewModel.scrollViewState = .expand
            }

        case .expand:
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): expand")
            guard velocity.y > 0 else { return }
            // check if top across
            let topOffset = (scrollView.contentOffset.y + scrollView.adjustedContentInset.top) - replyToCellFrame.height

            // check if bottom bounce
            let bottomOffsetY = scrollView.contentOffset.y + (scrollView.frame.height - scrollView.adjustedContentInset.bottom)
            let bottomOffset = bottomOffsetY - scrollView.contentSize.height

            if topOffset > 44 {
                // do not interrupt user scrolling
                viewModel.scrollViewState = .fold
            } else if bottomOffset > 44 {
                tableView.contentInset.top = -replyToCellFrame.height
                targetContentOffset.pointee = CGPoint(x: 0, y: -replyToCellFrame.height)
                viewModel.scrollViewState = .fold
            }
        }
    }
}

// MARK: - UITableViewDelegate
extension ComposeContentViewController: UITableViewDelegate { }

// MARK: - PHPickerViewControllerDelegate
extension ComposeContentViewController: PHPickerViewControllerDelegate {
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)

        let attachmentViewModels: [AttachmentViewModel] = results.map { result in
            AttachmentViewModel(
                api: viewModel.context.apiService,
                authContext: viewModel.authContext,
                input: .pickerResult(result),
                sizeLimit: viewModel.sizeLimit,
                delegate: viewModel
            )
        }
        viewModel.attachmentViewModels += attachmentViewModels
    }
}

// MARK: - UIImagePickerControllerDelegate
extension ComposeContentViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)

        guard let image = info[.originalImage] as? UIImage else { return }

        let attachmentViewModel = AttachmentViewModel(
            api: viewModel.context.apiService,
            authContext: viewModel.authContext,
            input: .image(image),
            sizeLimit: viewModel.sizeLimit,
            delegate: viewModel
        )
        viewModel.attachmentViewModels += [attachmentViewModel]
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - UIDocumentPickerDelegate
extension ComposeContentViewController: UIDocumentPickerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }

        let attachmentViewModel = AttachmentViewModel(
            api: viewModel.context.apiService,
            authContext: viewModel.authContext,
            input: .url(url),
            sizeLimit: viewModel.sizeLimit,
            delegate: viewModel
        )
        viewModel.attachmentViewModels += [attachmentViewModel]
    }
}

// MARK: - ComposeContentToolbarViewDelegate
extension ComposeContentViewController: ComposeContentToolbarViewDelegate {
    func composeContentToolbarView(
        _ viewModel: ComposeContentToolbarView.ViewModel,
        toolbarItemDidPressed action: ComposeContentToolbarView.ViewModel.Action
    ) {
        switch action {
        case .attachment:
            assertionFailure()
        case .poll:
            self.viewModel.isPollActive.toggle()
        case .emoji:
            self.viewModel.isEmojiActive.toggle()
        case .contentWarning:
            self.viewModel.isContentWarningActive.toggle()
            if self.viewModel.isContentWarningActive {
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: .second / 20)     // 0.05s
                    self.viewModel.setContentWarningTextViewFirstResponderIfNeeds()
                }   // end Task
            } else {
                if self.viewModel.contentWarningMetaText?.textView.isFirstResponder == true {
                    self.viewModel.setContentTextViewFirstResponderIfNeeds()
                }
            }
        case .visibility:
            assertionFailure()
        }
    }
    
    func composeContentToolbarView(
        _ viewModel: ComposeContentToolbarView.ViewModel,
        attachmentMenuDidPressed action: ComposeContentToolbarView.ViewModel.AttachmentAction
    ) {
        switch action {
        case .photoLibrary:
            present(photoLibraryPicker, animated: true, completion: nil)
        case .camera:
                present(imagePickerController, animated: true, completion: nil)
        case .browse:
            #if SNAPSHOT
            guard let image = UIImage(named: "Athens") else { return }
            
            let attachmentService = MastodonAttachmentService(
                context: context,
                image: image,
                initialAuthenticationBox: viewModel.authenticationBox
            )
            viewModel.attachmentServices = viewModel.attachmentServices + [attachmentService]
            #else
            present(documentPickerController, animated: true, completion: nil)
            #endif
        }
    }
}

// MARK: - AutoCompleteViewControllerDelegate
extension ComposeContentViewController: AutoCompleteViewControllerDelegate {
    func autoCompleteViewController(
        _ viewController: AutoCompleteViewController,
        didSelectItem item: AutoCompleteItem
    ) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): did select item: \(String(describing: item))")
        
        guard let info = viewModel.autoCompleteInfo else { return }
        guard let metaText = viewModel.contentMetaText else { return }
        
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
            return text
        }()
        guard let replacedText = _replacedText else { return }
        guard let text = metaText.textView.text else { return }
        
        let range = NSRange(info.toHighlightEndRange, in: text)
        metaText.textStorage.replaceCharacters(in: range, with: replacedText)
        viewModel.autoCompleteInfo = nil
        
        // set selected range
        let newRange = NSRange(location: range.location + (replacedText as NSString).length, length: 0)
        guard metaText.textStorage.length <= newRange.location else { return }
        metaText.textView.selectedRange = newRange
        
        // append a space and trigger textView delegate update
        DispatchQueue.main.async {
            metaText.textView.insertText(" ")
        }
    }
}

// MARK: - UICollectionViewDelegate
extension ComposeContentViewController: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: select %s", ((#file as NSString).lastPathComponent), #line, #function, indexPath.debugDescription)
        
        switch collectionView {
        case customEmojiPickerInputView.collectionView:
            guard let diffableDataSource = viewModel.customEmojiPickerDiffableDataSource else { return }
            let item = diffableDataSource.itemIdentifier(for: indexPath)
            guard case let .emoji(attribute) = item else { return }
            let emoji = attribute.emoji
            
            // make click sound
            UIDevice.current.playInputClick()
            
            // retrieve active text input and insert emoji
            // the trailing space is REQUIRED to make regex happy
            _ = viewModel.customEmojiPickerInputViewModel.insertText(":\(emoji.shortcode): ")
        default:
            assertionFailure()
        }
    }   // end func
    
}

// MARK: - ComposeContentViewModelDelegate
extension ComposeContentViewController: ComposeContentViewModelDelegate {
    public func composeContentViewModel(
        _ viewModel: ComposeContentViewModel,
        handleAutoComplete info: ComposeContentViewModel.AutoCompleteInfo
    ) -> Bool {
        let snapshot = autoCompleteViewController.viewModel.diffableDataSource.snapshot()
        guard let item = snapshot.itemIdentifiers.first else { return false }
        
        // FIXME: redundant code
        guard let metaText = viewModel.contentMetaText else { return false }
        guard let text = metaText.textView.text else { return false }
        let _replacedText: String? = {
            var text: String
            switch item {
            case .hashtag, .hashtagV1:
                // do no fill the hashtag
                // allow user delete suffix and post they want
                return nil
            case .account(let account):
                text = "@" + account.acct
            case .emoji(let emoji):
                text = ":" + emoji.shortcode + ":"
            case .bottomLoader:
                return nil
            }
            return text
        }()
        guard let replacedText = _replacedText else { return false }

        let range = NSRange(info.toHighlightEndRange, in: text)
        metaText.textStorage.replaceCharacters(in: range, with: replacedText)
        viewModel.autoCompleteInfo = nil
        
        // set selected range
        let newRange = NSRange(location: range.location + (replacedText as NSString).length, length: 0)
        guard metaText.textStorage.length <= newRange.location else { return true }
        metaText.textView.selectedRange = newRange
        
        // append a space and trigger textView delegate update
        DispatchQueue.main.async {
            metaText.textView.insertText(" ")
        }
        
        return true
    }
}
