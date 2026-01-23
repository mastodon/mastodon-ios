// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import PhotosUI
import SwiftUI
import MastodonUI
import MastodonLocalization
import MastodonAsset
import Kanna // for stripping the html from the account bio

class ProfileEditHostingViewController: UIHostingController<AnyView> {
    private let viewModel: ProfileViewModel

    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        super.init(rootView: AnyView(ProfileEditingView().environment(viewModel).environment(viewModel.editingViewModel)))
    }
    
    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ProfileEditingView: View {
    @Environment(ProfileViewModel.self) var profileViewModel
    @Environment(ProfileEditingViewModel.self) var editingViewModel
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                ProfileAvatarAndBannerView(width: geo.size.width)
                    .environment(profileViewModel)
                    .environment(editingViewModel)
                
                VStack(alignment: .leading, spacing: tinySpacing) {
                    inputLabel("Display name")
                    MetaTextInputField()
                        .environment(editingViewModel.displayNameFieldEditingViewModel)
                        .frame(height: 36)
                }
                .padding()
                
                VStack(alignment: .leading, spacing: tinySpacing) {
                    inputLabel("Bio")
                    MetaTextInputField()
                        .environment(editingViewModel.bioFieldEditingViewModel)
                        .frame(height: 56)
                }
                .padding()
                
                Spacer()
                    .frame(maxHeight: .infinity)
            }
            .overlay {
                if editingViewModel.bioFieldEditingViewModel.isEditing {
                    editingViewModel.bioFieldEditingViewModel.autoCompleteSuggestionView(pinToTopOfKeyboard: true)
                }
            }
            .sheet(isPresented: editingViewModel.showCroppingView) {
                if let image = editingViewModel.avatarImageToCrop {
                    PhotoCropperView(originalImage: image) { confirmedImage in
                        defer {
                            self.editingViewModel.avatarImageToCrop = nil
                        }
                        
                        guard let confirmedImage else {
                            self.editingViewModel.avatarConfirmedCroppedImage = nil
                            return
                        }
                        
                        self.editingViewModel.avatarConfirmedCroppedImage = confirmedImage
                    }
                }
            }
        }
        .navigationTitle(L10nLookup.Scene.EditProfile.title)
        .toolbar {
            if editingViewModel.hasUnsavedChanges {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.Common.Controls.Actions.save) {
                        assertionFailure("not implemented")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Asset.Colors.accent.swiftUIColor)
                }
            }
        }
    }
    
    @ViewBuilder func inputLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.semibold)
    }
}

@MainActor
@Observable
class ProfileEditingViewModel {
    var hasUnsavedChanges: Bool = false
    let displayNameFieldEditingViewModel = MetaTextInputFieldViewModel(stringContent: "", placeholder: "", characterLimit: .softLimit(100), autocompleteMastodonItems: false)
    let bioFieldEditingViewModel = MetaTextInputFieldViewModel(stringContent: "", placeholder: "Describe yourself and/or this account.", characterLimit: .softLimit(220), autocompleteMastodonItems: true)
    
    var selectedBannerImage: Binding<[PhotosPickerItem]>
    var bannerImagePhotosPickerItem: PhotosPickerItem?
    var confirmedBannerImage: UIImage?
    
    var selectedAvatar: Binding<[PhotosPickerItem]>
    var avatarPhotosPickerItem: PhotosPickerItem?
    var avatarImageToCrop: UIImage?
    var avatarConfirmedCroppedImage: UIImage?
    
    var showCroppingView: Binding<Bool>
    
    private(set) var initialInfo: MastodonAccount? = nil
    
    init() {
        selectedBannerImage = Binding<[PhotosPickerItem]>(get: {[]}, set: {_ in})
        selectedAvatar = Binding<[PhotosPickerItem]>(get: {[]}, set: {_ in})
        showCroppingView = Binding<Bool>(get: {false}, set: {_ in})
        
        showCroppingView = Binding<Bool>(
            get: { return self.avatarImageToCrop != nil },
            set: { newValue in }
        )
        
        selectedBannerImage = Binding<[PhotosPickerItem]>(
            get: { [self.bannerImagePhotosPickerItem].compactMap { $0 } },
            set: { newValue in
                self.bannerImagePhotosPickerItem = newValue.first
                if let item = self.bannerImagePhotosPickerItem {
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            self.confirmedBannerImage = image
                        } else {
                            print("Failed to load banner image")
                        }
                    }
                }
            }
        )
        
        selectedAvatar = Binding<[PhotosPickerItem]>(
            get: { [self.avatarPhotosPickerItem].compactMap { $0 } },
            set: { newValue in
                self.avatarPhotosPickerItem = newValue.first
                if let item = self.avatarPhotosPickerItem {
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            self.avatarImageToCrop = image
                        } else {
                            print("Failed to load avatar image")
                        }
                    }
                }
            }
        )
    }
    
    func setAccount(_ account: MastodonAccount) {
        initialInfo = account
        updateAccountTextFields(account: account)
    }
    
    func updateAccountTextFields(account: MastodonAccount) {
        let displayNameContent = account.displayInfo.displayName
        displayNameFieldEditingViewModel.stringContent = displayNameContent
        
        let bioContent = normalize(htmlString: account.bio)
        bioFieldEditingViewModel.stringContent = bioContent ?? ""
    }
}

func normalize(htmlString: String?) -> String? {
    let _note = htmlString?.replacingOccurrences(of: "<br>|<br />", with: "\u{2028}", options: .regularExpression, range: nil)
        .replacingOccurrences(of: "</p>", with: "</p>\u{2029}", range: nil)
        .trimmingCharacters(in: .whitespacesAndNewlines)
    guard let note = _note, !note.isEmpty else {
        return nil
    }
    
    let html = try? HTML(html: note, encoding: .utf8)
    return html?.text
}
