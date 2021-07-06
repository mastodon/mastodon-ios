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
import ActiveLabel
import AlamofireImage
import CropViewController
import TwitterTextEditor
import MastodonMeta

protocol ProfileHeaderViewControllerDelegate: AnyObject {
    func profileHeaderViewController(_ viewController: ProfileHeaderViewController, viewLayoutDidUpdate view: UIView)
    func profileHeaderViewController(_ viewController: ProfileHeaderViewController, pageSegmentedControlValueChanged segmentedControl: UISegmentedControl, selectedSegmentIndex index: Int)
    func profileHeaderViewController(_ viewController: ProfileHeaderViewController, profileFieldCollectionViewCell: ProfileFieldCollectionViewCell, activeLabel: ActiveLabel, didSelectActiveEntity entity: ActiveEntity)
}

final class ProfileHeaderViewController: UIViewController {

    static let segmentedControlHeight: CGFloat = 32
    static let segmentedControlMarginHeight: CGFloat = 20
    static let headerMinHeight: CGFloat = segmentedControlHeight + 2 * segmentedControlMarginHeight
    
    var disposeBag = Set<AnyCancellable>()
    weak var delegate: ProfileHeaderViewControllerDelegate?
    
    var viewModel: ProfileHeaderViewModel!
    
    let titleView: DoubleTitleLabelNavigationBarTitleView = {
        let titleView = DoubleTitleLabelNavigationBarTitleView()
        titleView.titleLabel.textColor = .white
        titleView.titleLabel.alpha = 0
        titleView.subtitleLabel.textColor = .white
        titleView.subtitleLabel.alpha = 0
        titleView.layer.masksToBounds = true
        return titleView
    }()
    
    let profileHeaderView = ProfileHeaderView()
    let pageSegmentedControl: UISegmentedControl = {
        let segmenetedControl = UISegmentedControl(items: ["A", "B"])
        segmenetedControl.selectedSegmentIndex = 0
        return segmenetedControl
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

        ThemeService.shared.currentTheme
            .receive(on: RunLoop.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.view.backgroundColor = theme.systemGroupedBackgroundColor
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
        
        profileHeaderView.fieldCollectionView.delegate = self
        viewModel.setupProfileFieldCollectionViewDiffableDataSource(
            collectionView: profileHeaderView.fieldCollectionView,
            profileFieldCollectionViewCellDelegate: self,
            profileFieldAddEntryCollectionViewCellDelegate: self
        )

        let longPressReorderGesture = UILongPressGestureRecognizer(target: self, action: #selector(ProfileHeaderViewController.longPressReorderGestureHandler(_:)))
        profileHeaderView.fieldCollectionView.addGestureRecognizer(longPressReorderGesture)
        
        pageSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageSegmentedControl)
        NSLayoutConstraint.activate([
            pageSegmentedControl.topAnchor.constraint(equalTo: profileHeaderView.bottomAnchor, constant: ProfileHeaderViewController.segmentedControlMarginHeight),
            pageSegmentedControl.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            pageSegmentedControl.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: pageSegmentedControl.bottomAnchor, constant: ProfileHeaderViewController.segmentedControlMarginHeight),
            pageSegmentedControl.heightAnchor.constraint(equalToConstant: ProfileHeaderViewController.segmentedControlHeight).priority(.defaultHigh),
        ])
        
        pageSegmentedControl.addTarget(self, action: #selector(ProfileHeaderViewController.pageSegmentedControlValueChanged(_:)), for: .valueChanged)

        Publishers.CombineLatest(
            viewModel.viewDidAppear.eraseToAnyPublisher(),
            viewModel.isTitleViewContentOffsetSet.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] viewDidAppear, isTitleViewContentOffsetDidSetted in
            guard let self = self else { return }
            self.titleView.titleLabel.alpha = viewDidAppear && isTitleViewContentOffsetDidSetted ? 1 : 0
            self.titleView.subtitleLabel.alpha = viewDidAppear && isTitleViewContentOffsetDidSetted ? 1 : 0
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
            viewModel.isEditing.eraseToAnyPublisher(),
            viewModel.displayProfileInfo.avatarImageResource.eraseToAnyPublisher(),
            viewModel.editProfileInfo.avatarImageResource.eraseToAnyPublisher(),
            viewModel.viewDidAppear.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] isEditing, resource, editingResource, _ in
            guard let self = self else { return }
            let url: URL? = {
                guard case let .url(url) = resource else { return nil }
                return url

            }()
            let image: UIImage? = {
                guard case let .image(image) = editingResource else { return nil }
                return image
            }()
            self.profileHeaderView.configure(
                with: AvatarConfigurableViewConfiguration(
                    avatarImageURL: image == nil ? url : nil,       // set only when image empty
                    placeholderImage: image,
                    keepImageCorner: true                           // fit preview transitioning
                )
            )
        }
        .store(in: &disposeBag)
        Publishers.CombineLatest4(
            viewModel.isEditing,
            viewModel.displayProfileInfo.name.removeDuplicates(),
            viewModel.editProfileInfo.name.removeDuplicates(),
            viewModel.emojiDict
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] isEditing, name, editingName, emojiDict in
            guard let self = self else { return }
            do {
                var emojis = MastodonContent.Emojis()
                for (key, value) in emojiDict {
                    emojis[key] = value.absoluteString
                }
                let metaContent = try MastodonMetaContent.convert(
                    document: MastodonContent(content: name ?? " ", emojis: emojis)
                )
                self.profileHeaderView.nameMetaText.configure(content: metaContent)
            } catch {
                assertionFailure()
            }
            self.profileHeaderView.nameTextField.text = isEditing ? editingName : name
        }
        .store(in: &disposeBag)
        
        Publishers.CombineLatest3(
            viewModel.isEditing.eraseToAnyPublisher(),
            viewModel.displayProfileInfo.note.removeDuplicates().eraseToAnyPublisher(),
            viewModel.editProfileInfo.note.removeDuplicates().eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] isEditing, note, editingNote in
            guard let self = self else { return }
            self.profileHeaderView.bioActiveLabel.configure(note: note ?? "", emojiDict: [:])       // FIXME: custom emoji
            self.profileHeaderView.bioTextEditorView.text = editingNote ?? ""
        }
        .store(in: &disposeBag)
        
        profileHeaderView.bioTextEditorView.changeObserver = self
        NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: profileHeaderView.nameTextField)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self else { return }
                guard let textField = notification.object as? UITextField else { return }
                self.viewModel.editProfileInfo.name.value = textField.text
            }
            .store(in: &disposeBag)
        
        Publishers.CombineLatest3(
            viewModel.isEditing,
            viewModel.displayProfileInfo.fields,
            viewModel.needsFiledCollectionViewHidden
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] isEditing, fields, needsHidden in
            guard let self = self else { return }
            guard !needsHidden else {
                self.profileHeaderView.fieldCollectionView.isHidden = true
                return
            }
            self.profileHeaderView.fieldCollectionView.isHidden = isEditing ? false : fields.isEmpty
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

    @objc private func pageSegmentedControlValueChanged(_ sender: UISegmentedControl) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: selectedSegmentIndex: %ld", ((#file as NSString).lastPathComponent), #line, #function, sender.selectedSegmentIndex)
        delegate?.profileHeaderViewController(self, pageSegmentedControlValueChanged: sender, selectedSegmentIndex: sender.selectedSegmentIndex)
    }
    
    // seealso: ProfileHeaderViewModel.setupProfileFieldCollectionViewDiffableDataSource(…)
    @objc private func longPressReorderGestureHandler(_ sender: UILongPressGestureRecognizer) {
        guard sender.view === profileHeaderView.fieldCollectionView else {
            assertionFailure()
            return
        }
        let collectionView = profileHeaderView.fieldCollectionView
        switch(sender.state) {
        case .began:
            guard let selectedIndexPath = collectionView.indexPathForItem(at: sender.location(in: collectionView)),
                  let cell = collectionView.cellForItem(at: selectedIndexPath) as? ProfileFieldCollectionViewCell else {
                break
            }
            // check if pressing reorder bar no not
            let locationInCell = sender.location(in: cell.reorderBarImageView)
            guard cell.reorderBarImageView.bounds.contains(locationInCell) else {
                return
            }

            collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            guard let selectedIndexPath = collectionView.indexPathForItem(at: sender.location(in: collectionView)),
                  let diffableDataSource = viewModel.fieldDiffableDataSource else {
                break
            }
            guard let item = diffableDataSource.itemIdentifier(for: selectedIndexPath),
                  case .field = item else {
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
            setProfileBannerFade(alpha: 0)
        } else if progress > -abs(throttle) {
            // y = -(1/0.8T)x
            let alpha = -1 / abs(0.8 * throttle) * progress
            setProfileBannerFade(alpha: alpha)
        } else {
            setProfileBannerFade(alpha: 1)
        }
    }

    private func setProfileBannerFade(alpha: CGFloat) {
        profileHeaderView.avatarImageViewBackgroundView.alpha = alpha
        profileHeaderView.avatarImageView.alpha = alpha
        profileHeaderView.editAvatarBackgroundView.alpha = alpha
        profileHeaderView.nameTextFieldBackgroundView.alpha = alpha
        profileHeaderView.displayNameStackView.alpha = alpha
        profileHeaderView.usernameLabel.alpha = alpha
    }
    
}

// MARK: - TextEditorViewChangeObserver
extension ProfileHeaderViewController: TextEditorViewChangeObserver {
    func textEditorView(_ textEditorView: TextEditorView, didChangeWithChangeResult changeResult: TextEditorViewChangeResult) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: text: %s", ((#file as NSString).lastPathComponent), #line, #function, textEditorView.text)
        guard changeResult.isTextChanged else { return }
        assert(textEditorView === profileHeaderView.bioTextEditorView)
        viewModel.editProfileInfo.note.value = textEditorView.text
    }
}

// MARK: - PHPickerViewControllerDelegate
extension ProfileHeaderViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        guard let result = results.first else { return }
        PHPickerResultLoader.loadImageData(from: result)
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
        viewModel.editProfileInfo.avatarImageResource.value = .image(image)
        cropViewController.dismiss(animated: true, completion: nil)
    }
}

// MARK: - UICollectionViewDelegate
extension ProfileHeaderViewController: UICollectionViewDelegate {

}

// MARK: - ProfileFieldCollectionViewCellDelegate
extension ProfileHeaderViewController: ProfileFieldCollectionViewCellDelegate {
    // should be remove style edit button
    func profileFieldCollectionViewCell(_ cell: ProfileFieldCollectionViewCell, editButtonDidPressed button: UIButton) {
        guard let diffableDataSource = viewModel.fieldDiffableDataSource else { return }
        guard let indexPath = profileHeaderView.fieldCollectionView.indexPath(for: cell) else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.removeFieldItem(item: item)
    }

    func profileFieldCollectionViewCell(_ cell: ProfileFieldCollectionViewCell, activeLabel: ActiveLabel, didSelectActiveEntity entity: ActiveEntity) {
        delegate?.profileHeaderViewController(self, profileFieldCollectionViewCell: cell, activeLabel: activeLabel, didSelectActiveEntity: entity)
    }
}

// MARK: - ProfileFieldAddEntryCollectionViewCellDelegate
extension ProfileHeaderViewController: ProfileFieldAddEntryCollectionViewCellDelegate {
    func ProfileFieldAddEntryCollectionViewCellDidPressed(_ cell: ProfileFieldAddEntryCollectionViewCell) {
        viewModel.appendFieldItem()
    }
}
