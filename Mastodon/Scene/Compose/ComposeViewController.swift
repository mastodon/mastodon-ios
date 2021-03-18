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
import TwitterTextEditor

final class ComposeViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ComposeViewModel!
    
    private var suffixedAttachmentViews: [UIView] = []
    
    let composeTootBarButtonItem: UIBarButtonItem = {
        let button = RoundedEdgesButton(type: .custom)
        button.setTitle(L10n.Scene.Compose.composeAction, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        button.setBackgroundImage(.placeholder(color: Asset.Colors.Button.normal.color), for: .normal)
        button.setBackgroundImage(.placeholder(color: Asset.Colors.Button.normal.color.withAlphaComponent(0.5)), for: .highlighted)
        button.setBackgroundImage(.placeholder(color: Asset.Colors.Button.disabled.color), for: .disabled)
        button.setTitleColor(.white, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 3, left: 16, bottom: 3, right: 16)
        button.adjustsImageWhenHighlighted = false
        let barButtonItem = UIBarButtonItem(customView: button)
        return barButtonItem
    }()
    
    let tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.register(ComposeRepliedToTootContentTableViewCell.self, forCellReuseIdentifier: String(describing: ComposeRepliedToTootContentTableViewCell.self))
        tableView.register(ComposeStatusContentTableViewCell.self, forCellReuseIdentifier: String(describing: ComposeStatusContentTableViewCell.self))
        tableView.register(ComposeStatusAttachmentTableViewCell.self, forCellReuseIdentifier: String(describing: ComposeStatusAttachmentTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        return tableView
    }()
    
    let composeToolbarView: ComposeToolbarView = {
        let composeToolbarView = ComposeToolbarView()
        composeToolbarView.backgroundColor = .secondarySystemBackground
        return composeToolbarView
    }()
    var composeToolbarViewBottomLayoutConstraint: NSLayoutConstraint!
    let composeToolbarBackgroundView: UIView = {
        let backgroundView = UIView()
        backgroundView.backgroundColor = .secondarySystemBackground
        return backgroundView
    }()
    
    lazy var imagePicker: PHPickerViewController = {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 4

        let imagePicker = PHPickerViewController(configuration: configuration)
        imagePicker.delegate = self
        return imagePicker
    }()
    
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
        view.backgroundColor = Asset.Colors.Background.systemBackground.color
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: L10n.Common.Controls.Actions.cancel, style: .plain, target: self, action: #selector(ComposeViewController.cancelBarButtonItemPressed(_:)))
        navigationItem.rightBarButtonItem = composeTootBarButtonItem
        
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
        viewModel.setupDiffableDataSource(
            for: tableView,
            dependency: self,
            textEditorViewTextAttributesDelegate: self,
            composeStatusAttachmentTableViewCellDelegate: self
        )
        
        // respond scrollView overlap change
        view.layoutIfNeeded()
        // update layout when keyboard show/dismiss
        Publishers.CombineLatest3(
            KeyboardResponderService.shared.isShow.eraseToAnyPublisher(),
            KeyboardResponderService.shared.state.eraseToAnyPublisher(),
            KeyboardResponderService.shared.endFrame.eraseToAnyPublisher()
        )
        .sink(receiveValue: { [weak self] isShow, state, endFrame in
            guard let self = self else { return }
            
            guard isShow, state == .dock else {
                self.tableView.contentInset.bottom = 0.0
                self.tableView.verticalScrollIndicatorInsets.bottom = 0.0
                UIView.animate(withDuration: 0.3) {
                    self.composeToolbarViewBottomLayoutConstraint.constant = 0.0
                    self.view.layoutIfNeeded()
                }
                return
            }

            // isShow AND dock state
            let contentFrame = self.view.convert(self.tableView.frame, to: nil)
            let padding = contentFrame.maxY - endFrame.minY
            guard padding > 0 else {
                self.tableView.contentInset.bottom = 0.0
                self.tableView.verticalScrollIndicatorInsets.bottom = 0.0
                UIView.animate(withDuration: 0.3) {
                    self.composeToolbarViewBottomLayoutConstraint.constant = 0.0
                    self.view.layoutIfNeeded()
                }
                return
            }

            // add 16pt margin
            self.tableView.contentInset.bottom = padding + 16
            self.tableView.verticalScrollIndicatorInsets.bottom = padding + 16
            UIView.animate(withDuration: 0.3) {
                self.composeToolbarViewBottomLayoutConstraint.constant = padding
                self.view.layoutIfNeeded()
            }
        })
        .store(in: &disposeBag)
        
        viewModel.isComposeTootBarButtonItemEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: composeTootBarButtonItem)
            .store(in: &disposeBag)
        
        // bind custom emojis
        viewModel.customEmojiViewModel
            .compactMap { $0?.emojis }
            .switchToLatest()
            .sink(receiveValue: { [weak self] emojis in
                guard let self = self else { return }
                for emoji in emojis {
                    UITextChecker.learnWord(emoji.shortcode)
                    UITextChecker.learnWord(":" + emoji.shortcode + ":")
                }
                self.textEditorView()?.setNeedsUpdateTextAttributes()
            })
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
    
}

extension ComposeViewController {
    
    private func textEditorView() -> TextEditorView? {
        guard let diffableDataSource = viewModel.diffableDataSource else { return nil }
        let items = diffableDataSource.snapshot().itemIdentifiers
        for item in items {
            switch item {
            case .input:
                guard let indexPath = diffableDataSource.indexPath(for: item),
                      let cell = tableView.cellForRow(at: indexPath) as? ComposeStatusContentTableViewCell else {
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
    
}

// MARK: - TextEditorViewTextAttributesDelegate
extension ComposeViewController: TextEditorViewTextAttributesDelegate {
    
    func textEditorView(
        _ textEditorView: TextEditorView,
        updateAttributedString attributedString: NSAttributedString,
        completion: @escaping (NSAttributedString?) -> Void
    ) {
        DispatchQueue.global().async {
            let string = attributedString.string
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: update: %s", ((#file as NSString).lastPathComponent), #line, #function, string)

            let stringRange = NSRange(location: 0, length: string.length)
            let highlightMatches = string.matches(pattern: "(?:@([a-zA-Z0-9_]+)|#([^\\s.]+))")
            // accept ^\B: or \s: but not accept \B: to force user input a space to make emoji take effect
            // precondition :\B with following space 
            let emojiMatches = string.matches(pattern: "(?:(^\\B:|\\s:)([a-zA-Z0-9_]+)(:\\B(?=\\s)))")
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
                let emojis = customEmojiViewModel?.emojis.value ?? []
                if !emojis.isEmpty {
                    for match in emojiMatches {
                        guard let name = string.substring(with: match, at: 2) else { continue }
                        guard let emoji = emojis.first(where: { $0.shortcode == name }) else { continue }
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
                
                completion(attributedString)
            }
        }
    }
    
}

// MARK: - ComposeToolbarViewDelegate
extension ComposeViewController: ComposeToolbarViewDelegate {
    
    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, cameraButtonDidPressed sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        present(imagePicker, animated: true, completion: nil)
    }
    
    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, gifButtonDidPressed sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, atButtonDidPressed sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, topicButtonDidPressed sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
    func composeToolbarView(_ composeToolbarView: ComposeToolbarView, locationButtonDidPressed sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

// MARK: - UITableViewDelegate
extension ComposeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension ComposeViewController: UIAdaptivePresentationControllerDelegate {

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
        let attachmentServices = results.map { MastodonAttachmentService(pickerResult: $0) }
        viewModel.attachmentServices.value = viewModel.attachmentServices.value + attachmentServices
    }
}

// MARK: - ComposeStatusAttachmentTableViewCellDelegate
extension ComposeViewController: ComposeStatusAttachmentTableViewCellDelegate {
    
    func composeStatusAttachmentTableViewCell(_ cell: ComposeStatusAttachmentTableViewCell, removeButtonDidPressed button: UIButton) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        guard case let .attachment(attachmentService) = item else { return }
        
        var attachmentServices = viewModel.attachmentServices.value
        guard let index = attachmentServices.firstIndex(of: attachmentService) else { return }
        attachmentServices.remove(at: index)
        viewModel.attachmentServices.value = attachmentServices
    }
    
}
