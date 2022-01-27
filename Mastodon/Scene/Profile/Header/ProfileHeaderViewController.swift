//
//  ProfileHeaderViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-29.
//

import os.log
import UIKit
import Combine
import PhotosUI
import AlamofireImage
import CropViewController
import MastodonMeta
import MetaTextKit
import MastodonAsset
import MastodonLocalization
import Tabman

protocol ProfileHeaderViewControllerDelegate: AnyObject {
    func profileHeaderViewController(_ viewController: ProfileHeaderViewController, viewLayoutDidUpdate view: UIView)
}

final class ProfileHeaderViewController: UIViewController {

    static let segmentedControlHeight: CGFloat = 50
    static let headerMinHeight: CGFloat = segmentedControlHeight
    
    var disposeBag = Set<AnyCancellable>()
    weak var delegate: ProfileHeaderViewControllerDelegate?
    
    var viewModel: ProfileHeaderViewModel!
    
    let titleView: DoubleTitleLabelNavigationBarTitleView = {
        let titleView = DoubleTitleLabelNavigationBarTitleView()
        titleView.titleLabel.textColor = .white
        titleView.titleLabel.textAttributes[.foregroundColor] = UIColor.white
        titleView.titleLabel.alpha = 0
        titleView.subtitleLabel.textColor = .white
        titleView.subtitleLabel.alpha = 0
        titleView.layer.masksToBounds = true
        return titleView
    }()
    
    let profileHeaderView = ProfileHeaderView()
    
    let buttonBar: TMBar.ButtonBar = {
        let buttonBar = TMBar.ButtonBar()
        buttonBar.buttons.customize { button in
            button.selectedTintColor = Asset.Colors.Label.primary.color
            button.tintColor = Asset.Colors.Label.secondary.color
            button.backgroundColor = .clear
        }
        buttonBar.indicator.backgroundColor = Asset.Colors.Label.primary.color
        buttonBar.backgroundView.style = .clear
        buttonBar.layout.contentInset = .zero
        return buttonBar
    }()

    private var isBannerPinned = false
    private var bottomShadowAlpha: CGFloat = 0.0

    // private var isAdjustBannerImageViewForSafeAreaInset = false
    private var containerSafeAreaInset: UIEdgeInsets = .zero
    
    private(set) lazy var imagePicker: PHPickerViewController = {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1

        let imagePicker = PHPickerViewController(configuration: configuration)
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
        let documentPickerController = UIDocumentPickerViewController(forOpeningContentTypes: [.image])
        documentPickerController.delegate = self
        return documentPickerController
    }()

    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ProfileHeaderViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ThemeService.shared.currentTheme.value.systemBackgroundColor
        ThemeService.shared.currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.view.backgroundColor = theme.systemBackgroundColor
            }
            .store(in: &disposeBag)

        profileHeaderView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(profileHeaderView)
        NSLayoutConstraint.activate([
            profileHeaderView.topAnchor.constraint(equalTo: view.topAnchor),
            profileHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            profileHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        profileHeaderView.preservesSuperviewLayoutMargins = true
    
        Publishers.CombineLatest(
            viewModel.viewDidAppear.eraseToAnyPublisher(),
            viewModel.isTitleViewContentOffsetSet.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] viewDidAppear, isTitleViewContentOffsetDidSet in
            guard let self = self else { return }
            self.titleView.titleLabel.alpha = viewDidAppear && isTitleViewContentOffsetDidSet ? 1 : 0
            self.titleView.subtitleLabel.alpha = viewDidAppear && isTitleViewContentOffsetDidSet ? 1 : 0
        }
        .store(in: &disposeBag)
        
        viewModel.needsSetupBottomShadow
            .receive(on: DispatchQueue.main)
            .sink { [weak self] needsSetupBottomShadow in
                guard let self = self else { return }
                self.setupBottomShadow()
            }
            .store(in: &disposeBag)
        
        Publishers.CombineLatest4(
            viewModel.$isEditing.eraseToAnyPublisher(),
            viewModel.displayProfileInfo.$avatarImageResource.eraseToAnyPublisher(),
            viewModel.editProfileInfo.$avatarImageResource.eraseToAnyPublisher(),
            viewModel.viewDidAppear.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] isEditing, displayResource, editingResource, _ in
            guard let self = self else { return }
            
            let url = displayResource.url
            let image = editingResource.image
            
            self.profileHeaderView.avatarButton.avatarImageView.configure(
                configuration: AvatarImageView.Configuration(
                    url: isEditing && image != nil ? nil : url,
                    placeholder: image ?? UIImage.placeholder(color: Asset.Theme.Mastodon.systemGroupedBackground.color)
                )
            )
        }
        .store(in: &disposeBag)
        Publishers.CombineLatest4(
            viewModel.$isEditing,
            viewModel.displayProfileInfo.$name.removeDuplicates(),
            viewModel.editProfileInfo.$name.removeDuplicates(),
            viewModel.$emojiMeta
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] isEditing, name, editingName, emojiMeta in
            guard let self = self else { return }
            do {
                let mastodonContent = MastodonContent(content: name ?? " ", emojis: emojiMeta)
                let metaContent = try MastodonMetaContent.convert(document: mastodonContent)
                self.profileHeaderView.nameMetaText.configure(content: metaContent)
            } catch {
                assertionFailure()
            }
            self.profileHeaderView.nameTextField.text = isEditing ? editingName : name
        }
        .store(in: &disposeBag)
        
        let profileNote = Publishers.CombineLatest3(
            viewModel.$isEditing.removeDuplicates(),
            viewModel.displayProfileInfo.$note.removeDuplicates(),
            viewModel.editProfileInfoDidInitialized
        )
        .map { isEditing, displayNote, _ -> String? in
            if isEditing {
                return self.viewModel.editProfileInfo.note
            } else {
                return displayNote
            }
        }
        .eraseToAnyPublisher()

        Publishers.CombineLatest3(
            viewModel.$isEditing.removeDuplicates(),
            profileNote.removeDuplicates(),
            viewModel.$emojiMeta.removeDuplicates()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] isEditing, note, emojiMeta in
            guard let self = self else { return }
            
            self.profileHeaderView.bioMetaText.textView.isEditable = isEditing
            
            if isEditing {
                let metaContent = PlaintextMetaContent(string: note ?? "")
                self.profileHeaderView.bioMetaText.configure(content: metaContent)
            } else {
                let mastodonContent = MastodonContent(content: note ?? "", emojis: emojiMeta)
                do {
                    let metaContent = try MastodonMetaContent.convert(document: mastodonContent)
                    self.profileHeaderView.bioMetaText.configure(content: metaContent)
                } catch {
                    assertionFailure()
                    self.profileHeaderView.bioMetaText.reset()
                }
            }
        }
        .store(in: &disposeBag)
        
        profileHeaderView.bioMetaText.delegate = self

        NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: profileHeaderView.nameTextField)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self else { return }
                guard let textField = notification.object as? UITextField else { return }
                self.viewModel.editProfileInfo.name = textField.text
            }
            .store(in: &disposeBag)
        
        profileHeaderView.editAvatarButton.menu = createAvatarContextMenu()
        profileHeaderView.editAvatarButton.showsMenuAsPrimaryAction = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.viewDidAppear.value = true

        // set display after view appear
        profileHeaderView.setupAvatarOverlayViews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        delegate?.profileHeaderViewController(self, viewLayoutDidUpdate: view)
        setupBottomShadow()
    }
    
}

extension ProfileHeaderViewController {
    private func createAvatarContextMenu() -> UIMenu {
        var children: [UIMenuElement] = []
        let photoLibraryAction = UIAction(title: L10n.Scene.Compose.MediaSelection.photoLibrary, image: UIImage(systemName: "rectangle.on.rectangle"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off) { [weak self] _ in
            guard let self = self else { return }
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: mediaSelectionType: .photoLibaray", ((#file as NSString).lastPathComponent), #line, #function)
            self.present(self.imagePicker, animated: true, completion: nil)
        }
        children.append(photoLibraryAction)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAction(title: L10n.Scene.Compose.MediaSelection.camera, image: UIImage(systemName: "camera"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off, handler: { [weak self] _ in
                guard let self = self else { return }
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: mediaSelectionType: .camera", ((#file as NSString).lastPathComponent), #line, #function)
                self.present(self.imagePickerController, animated: true, completion: nil)
            })
            children.append(cameraAction)
        }
        let browseAction = UIAction(title: L10n.Scene.Compose.MediaSelection.browse, image: UIImage(systemName: "ellipsis"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off) { [weak self] _ in
            guard let self = self else { return }
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: mediaSelectionType: .browse", ((#file as NSString).lastPathComponent), #line, #function)
            self.present(self.documentPickerController, animated: true, completion: nil)
        }
        children.append(browseAction)
        
        return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: children)
    }
    
    private func cropImage(image: UIImage, pickerViewController: UIViewController) {
        DispatchQueue.main.async {
            let cropController = CropViewController(croppingStyle: .default, image: image)
            cropController.delegate = self
            cropController.setAspectRatioPreset(.presetSquare, animated: true)
            cropController.aspectRatioPickerButtonHidden = true
            cropController.aspectRatioLockEnabled = true
            pickerViewController.dismiss(animated: true, completion: {
                self.present(cropController, animated: true, completion: nil)
            })
        }
    }
}

extension ProfileHeaderViewController {
    
    func updateHeaderContainerSafeAreaInset(_ inset: UIEdgeInsets) {
        containerSafeAreaInset = inset
    }
    
    func setupBottomShadow() {
        guard viewModel.needsSetupBottomShadow.value else {
            view.layer.shadowColor = nil
            view.layer.shadowRadius = 0
            return
        }
        view.layer.setupShadow(color: UIColor.black.withAlphaComponent(0.12), alpha: Float(bottomShadowAlpha), x: 0, y: 2, blur: 2, spread: 0, roundedRect: view.bounds, byRoundingCorners: .allCorners, cornerRadii: .zero)
    }
    
    private func updateHeaderBottomShadow(progress: CGFloat) {
        let alpha = min(max(0, 10 * progress - 9), 1)
        if bottomShadowAlpha != alpha {
            bottomShadowAlpha = alpha
            view.setNeedsLayout()
        }
    }
    
    func updateHeaderScrollProgress(_ progress: CGFloat, throttle: CGFloat) {
        // os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: progress: %.2f", ((#file as NSString).lastPathComponent), #line, #function, progress)
        updateHeaderBottomShadow(progress: progress)
                
        let bannerImageView = profileHeaderView.bannerImageView
        guard bannerImageView.bounds != .zero else {
            // wait layout finish
            return
        }
        
        let bannerContainerInWindow = profileHeaderView.convert(profileHeaderView.bannerContainerView.frame, to: nil)
        let bannerContainerBottomOffset = bannerContainerInWindow.origin.y + bannerContainerInWindow.height
    
        // scroll from bottom to top: 1 -> 2 -> 3
        if bannerContainerInWindow.origin.y > containerSafeAreaInset.top {
            // 1
            // banner top pin to window top and expand
            bannerImageView.frame.origin.y = -bannerContainerInWindow.origin.y
            bannerImageView.frame.size.height = bannerContainerInWindow.origin.y + bannerContainerInWindow.size.height
        } else if bannerContainerBottomOffset < containerSafeAreaInset.top {
            // 3
            // banner bottom pin to navigation bar bottom and
            // the `progress` growth to 1 then segmented control pin to top
            bannerImageView.frame.origin.y = -containerSafeAreaInset.top
            let bannerImageHeight = bannerContainerInWindow.size.height + containerSafeAreaInset.top + (containerSafeAreaInset.top - bannerContainerBottomOffset)
            bannerImageView.frame.size.height = bannerImageHeight
        } else {
            // 2
            // banner move with scrolling from bottom to top until the
            // banner bottom higher than navigation bar bottom
            bannerImageView.frame.origin.y = -containerSafeAreaInset.top
            bannerImageView.frame.size.height = bannerContainerInWindow.size.height + containerSafeAreaInset.top
        }
        
        // set title view offset
        let nameTextFieldInWindow = profileHeaderView.nameTextField.superview!.convert(profileHeaderView.nameTextField.frame, to: nil)
        let nameTextFieldTopToNavigationBarBottomOffset = containerSafeAreaInset.top - nameTextFieldInWindow.origin.y
        let titleViewContentOffset: CGFloat = titleView.frame.height - nameTextFieldTopToNavigationBarBottomOffset
        let transformY = max(0, titleViewContentOffset)
        titleView.containerView.transform = CGAffineTransform(translationX: 0, y: transformY)
        viewModel.isTitleViewDisplaying.value = transformY < titleView.containerView.frame.height

        if viewModel.viewDidAppear.value {
            viewModel.isTitleViewContentOffsetSet.value = true
        }
                
        // set avatar fade
        if progress > 0 {
            setProfileAvatar(alpha: 0)
        } else if progress > -abs(throttle) {
            // y = -(1/0.8T)x
            let alpha = -1 / abs(0.8 * throttle) * progress
            setProfileAvatar(alpha: alpha)
        } else {
            setProfileAvatar(alpha: 1)
        }
    }

    private func setProfileAvatar(alpha: CGFloat) {
        profileHeaderView.avatarImageViewBackgroundView.alpha = alpha
        profileHeaderView.avatarButton.alpha = alpha
        profileHeaderView.editAvatarBackgroundView.alpha = alpha
    }
    
}

// MARK: - MetaTextDelegate
extension ProfileHeaderViewController: MetaTextDelegate {
    func metaText(_ metaText: MetaText, processEditing textStorage: MetaTextStorage) -> MetaContent? {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: text: %s", ((#file as NSString).lastPathComponent), #line, #function, metaText.backedString)
        
        switch metaText {
        case profileHeaderView.bioMetaText:
            guard viewModel.isEditing else { break }
            viewModel.editProfileInfo.note = metaText.backedString
            let metaContent = PlaintextMetaContent(string: metaText.backedString)
            return metaContent
        default:
            assertionFailure()
        }

        return nil
    }
}

// MARK: - PHPickerViewControllerDelegate
extension ProfileHeaderViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        guard let result = results.first else { return }
        ItemProviderLoader.loadImageData(from: result)
            .sink { [weak self] completion in
                guard let _ = self else { return }
                switch completion {
                case .failure:
                    // TODO: handle error
                    break
                case .finished:
                    break
                }
            } receiveValue: { [weak self] file in
                guard let self = self else { return }
                guard let imageData = file?.data else { return }
                guard let image = UIImage(data: imageData) else { return }
                self.cropImage(image: image, pickerViewController: picker)
            }
            .store(in: &disposeBag)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension ProfileHeaderViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)

        guard let image = info[.originalImage] as? UIImage else { return }
        cropImage(image: image, pickerViewController: picker)
    }
        
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - UIDocumentPickerDelegate
extension ProfileHeaderViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        do {
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            let imageData = try Data(contentsOf: url)
            guard let image = UIImage(data: imageData) else { return }
            cropImage(image: image, pickerViewController: controller)
        } catch {
            os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
        }
    }
}

// MARK: - CropViewControllerDelegate
extension ProfileHeaderViewController: CropViewControllerDelegate {
    public func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        viewModel.editProfileInfo.avatarImage = image
        cropViewController.dismiss(animated: true, completion: nil)
    }
}
