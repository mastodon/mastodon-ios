//
//  ProfileHeaderViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-29.
//

import UIKit
import Combine
import CoreDataStack
import PhotosUI
import AlamofireImage
import CropViewController
import MastodonMeta
import MetaTextKit
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization
import TabBarPager
import MastodonSDK

protocol ProfileHeaderViewControllerDelegate: AnyObject {
    func profileHeaderViewController(_ profileHeaderViewController: ProfileHeaderViewController, profileHeaderView: ProfileHeaderView, relationshipButtonDidPressed button: ProfileRelationshipActionButton)
    func profileHeaderViewController(_ profileHeaderViewController: ProfileHeaderViewController, profileHeaderView: ProfileHeaderView, metaTextView: MetaTextView, metaDidPressed meta: Meta)
}

final class ProfileHeaderViewController: UIViewController, NeedsDependency, MediaPreviewableViewController {
    
    static let segmentedControlHeight: CGFloat = 50
    static let headerMinHeight: CGFloat = segmentedControlHeight
    
    weak var context: AppContext!
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    let viewModel: ProfileHeaderViewModel

    weak var delegate: ProfileHeaderViewControllerDelegate?
    weak var headerDelegate: TabBarPagerHeaderDelegate?
    
    let mediaPreviewTransitionController = MediaPreviewTransitionController()
    
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
    
    let profileHeaderView: ProfileHeaderView

//    private var isBannerPinned = false

    // private var isAdjustBannerImageViewForSafeAreaInset = false
    private var containerSafeAreaInset: UIEdgeInsets = .zero

    private var currentImageType = ImageType.avatar
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

    init(context: AppContext, authContext: AuthContext, coordinator: SceneCoordinator, profileViewModel: ProfileViewModel) {
        self.context = context
        self.coordinator = coordinator
        self.viewModel = ProfileHeaderViewModel(context: context, authContext: authContext, account: profileViewModel.account, me: profileViewModel.me, relationship: profileViewModel.relationship)
        self.profileHeaderView = ProfileHeaderView(account: profileViewModel.account, me: profileViewModel.me, relationship: profileViewModel.relationship)

        super.init(nibName: nil, bundle: nil)

        viewModel.$account
            .receive(on: DispatchQueue.main)
            .sink { [weak self] account in
                guard let self else { return }

                self.profileHeaderView.configuration(account: account)
            }
            .store(in: &disposeBag)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.setContentHuggingPriority(.required - 1, for: .vertical)

        view.backgroundColor = .systemBackground

//        profileHeaderView.preservesSuperviewLayoutMargins = true
        profileHeaderView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(profileHeaderView)
        NSLayoutConstraint.activate([
            profileHeaderView.topAnchor.constraint(equalTo: view.topAnchor),
            profileHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            profileHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: profileHeaderView.bottomAnchor),
        ])
        profileHeaderView.bioMetaText.delegate = self
        
        NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: profileHeaderView.nameTextField)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self else { return }
                guard let textField = notification.object as? UITextField else { return }
                self.viewModel.profileInfoEditing.name = textField.text
            }
            .store(in: &disposeBag)
        
        profileHeaderView.editBannerButton.menu = createImageContextMenu(.banner)
        profileHeaderView.editBannerButton.showsMenuAsPrimaryAction = true
        profileHeaderView.editAvatarButtonOverlayIndicatorView.menu = createImageContextMenu(.avatar)
        profileHeaderView.editAvatarButtonOverlayIndicatorView.showsMenuAsPrimaryAction = true
        profileHeaderView.delegate = self
        
        // bind viewModel
        viewModel.$isTitleViewContentOffsetSet
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isTitleViewContentOffsetDidSet in
                guard let self = self else { return }
                self.titleView.titleLabel.alpha = isTitleViewContentOffsetDidSet ? 1 : 0
                self.titleView.subtitleLabel.alpha = isTitleViewContentOffsetDidSet ? 1 : 0
            }
            .store(in: &disposeBag)
        viewModel.$relationship
            .assign(to: \.relationship, on: profileHeaderView.viewModel)
            .store(in: &disposeBag)
        viewModel.$account
            .assign(to: \.account, on: profileHeaderView.viewModel)
            .store(in: &disposeBag)
        viewModel.$isMyself
            .assign(to: \.isMyself, on: profileHeaderView.viewModel)
            .store(in: &disposeBag)
        viewModel.$isEditing
            .assign(to: \.isEditing, on: profileHeaderView.viewModel)
            .store(in: &disposeBag)
        viewModel.$isUpdating
            .assign(to: \.isUpdating, on: profileHeaderView.viewModel)
            .store(in: &disposeBag)
        viewModel.profileInfoEditing.$header
            .assign(to: \.headerImageEditing, on: profileHeaderView.viewModel)
            .store(in: &disposeBag)
        viewModel.profileInfoEditing.$avatar
            .assign(to: \.avatarImageEditing, on: profileHeaderView.viewModel)
            .store(in: &disposeBag)
        viewModel.profileInfoEditing.$name
            .assign(to: \.nameEditing, on: profileHeaderView.viewModel)
            .store(in: &disposeBag)
        viewModel.profileInfoEditing.$note
            .assign(to: \.noteEditing, on: profileHeaderView.viewModel)
            .store(in: &disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        profileHeaderView.viewModel.viewDidAppear.send()
        
        // set display after view appear
        profileHeaderView.setupImageOverlayViews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        headerDelegate?.viewLayoutDidUpdate(self)
    }
    
}

extension ProfileHeaderViewController {
    fileprivate enum ImageType {
        case avatar
        case banner
    }
    private func createImageContextMenu(_ type: ImageType) -> UIMenu {
        var children: [UIMenuElement] = []
        let photoLibraryAction = UIAction(title: L10n.Scene.Compose.MediaSelection.photoLibrary, image: UIImage(systemName: "rectangle.on.rectangle"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off) { [weak self] _ in
            guard let self = self else { return }
            self.currentImageType = type
            self.present(self.imagePicker, animated: true, completion: nil)
        }
        children.append(photoLibraryAction)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAction(title: L10n.Scene.Compose.MediaSelection.camera, image: UIImage(systemName: "camera"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off, handler: { [weak self] _ in
                guard let self = self else { return }
                self.currentImageType = type
                self.present(self.imagePickerController, animated: true, completion: nil)
            })
            children.append(cameraAction)
        }
        let browseAction = UIAction(title: L10n.Scene.Compose.MediaSelection.browse, image: UIImage(systemName: "ellipsis"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off) { [weak self] _ in
            guard let self = self else { return }
            self.currentImageType = type
            self.present(self.documentPickerController, animated: true, completion: nil)
        }
        children.append(browseAction)
        
        return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: children)
    }
    
    private func cropImage(image: UIImage, pickerViewController: UIViewController) {
        DispatchQueue.main.async {
            let cropController = CropViewController(croppingStyle: .default, image: image)
            cropController.delegate = self
            switch self.currentImageType {
            case .banner:
                cropController.customAspectRatio = CGSize(width: 3, height: 1)
                cropController.setAspectRatioPreset(.presetCustom, animated: true)
            case .avatar:
                cropController.setAspectRatioPreset(.presetSquare, animated: true)
            }
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
    
    func updateHeaderScrollProgress(_ progress: CGFloat, throttle: CGFloat) {
        // set title view offset
        let nameTextFieldInWindow = profileHeaderView.nameTextField.superview!.convert(profileHeaderView.nameTextField.frame, to: nil)
        let nameTextFieldTopToNavigationBarBottomOffset = containerSafeAreaInset.top - nameTextFieldInWindow.origin.y
        let titleViewContentOffset: CGFloat = titleView.frame.height - nameTextFieldTopToNavigationBarBottomOffset
        let transformY = max(0, titleViewContentOffset)
        titleView.containerView.transform = CGAffineTransform(translationX: 0, y: transformY)
        viewModel.isTitleViewDisplaying = transformY < titleView.containerView.frame.height
        viewModel.isTitleViewContentOffsetSet = true

        if progress > 0, throttle > 0 {
            // y = 1 - (x/t)
            // give: x = 0, y = 1
            //       x = t, y = 0
            let alpha = 1 - progress/throttle
            setProfileAvatar(alpha: alpha)
        } else {
            setProfileAvatar(alpha: 1)
        }
    }

    private func setProfileAvatar(alpha: CGFloat) {
        let scale = max(0.5, alpha * 0.5 + 0.5)
        profileHeaderView.avatarImageViewBackgroundView.transform = CGAffineTransform(scaleX: scale, y: scale)
    }

}

// MARK: - ProfileHeaderViewDelegate
extension ProfileHeaderViewController: ProfileHeaderViewDelegate {
    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, avatarButtonDidPressed button: AvatarButton) {
        Task {
            try await DataSourceFacade.coordinateToMediaPreviewScene(
                dependency: self,
                account: viewModel.account,
                previewContext: DataSourceFacade.ImagePreviewContext(
                    imageView: button.avatarImageView,
                    containerView: .profileAvatar(profileHeaderView)
                )
            )
        }
    }

    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, bannerImageViewDidPressed imageView: UIImageView) {
        Task {
            try await DataSourceFacade.coordinateToMediaPreviewScene(
                dependency: self,
                account: viewModel.account,
                previewContext: DataSourceFacade.ImagePreviewContext(
                    imageView: imageView,
                    containerView: .profileBanner(profileHeaderView)
                )
            )
        }
    }

    func profileHeaderView(
        _ profileHeaderView: ProfileHeaderView,
        relationshipButtonDidPressed button: ProfileRelationshipActionButton
    ) {
        delegate?.profileHeaderViewController(
            self,
            profileHeaderView: profileHeaderView,
            relationshipButtonDidPressed: button
        )
    }

    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, metaTextView: MetaTextView, metaDidPressed meta: Meta) {
        delegate?.profileHeaderViewController(
            self,
            profileHeaderView: profileHeaderView,
            metaTextView: metaTextView,
            metaDidPressed: meta
        )
    }

    func profileHeaderView(
        _ profileHeaderView: ProfileHeaderView,
        profileStatusDashboardView dashboardView: ProfileStatusDashboardView,
        dashboardMeterViewDidPressed dashboardMeterView: ProfileStatusDashboardMeterView,
        meter: ProfileStatusDashboardView.Meter
    ) {

        guard profileHeaderView.viewModel.isEditing == false else { return }

        switch meter {
        case .post:
            // do nothing
            break
        case .follower:
            guard let domain = viewModel.account.domain else { return }
            let userID = viewModel.account.id
            let followerListViewModel = FollowerListViewModel(
                context: context,
                authContext: viewModel.authContext,
                domain: domain,
                userID: userID
            )
            _ = coordinator.present(
                scene: .follower(viewModel: followerListViewModel),
                from: self,
                transition: .show
            )

        case .following:
            guard let domain = viewModel.account.domain else { return }

            let userID = viewModel.account.id
            let followingListViewModel = FollowingListViewModel(
                context: context,
                authContext: viewModel.authContext,
                domain: domain,
                userID: userID
            )
            _ = coordinator.present(
                scene: .following(viewModel: followingListViewModel),
                from: self,
                transition: .show
            )
        }
    }
}

// MARK: - MetaTextDelegate
extension ProfileHeaderViewController: MetaTextDelegate {
    func metaText(_ metaText: MetaText, processEditing textStorage: MetaTextStorage) -> MetaContent? {
        switch metaText {
        case profileHeaderView.bioMetaText:
            guard viewModel.isEditing else { break }
            defer {
                viewModel.profileInfoEditing.note = metaText.backedString                
            }
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
        }
    }
}

// MARK: - CropViewControllerDelegate
extension ProfileHeaderViewController: CropViewControllerDelegate {
    public func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        switch currentImageType {
        case .banner:
            viewModel.profileInfoEditing.header = image
        case .avatar:
            viewModel.profileInfoEditing.avatar = image
        }
        cropViewController.dismiss(animated: true, completion: nil)
    }
}

// MARK: - TabBarPagerHeader
extension ProfileHeaderViewController: TabBarPagerHeader { }
