// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonAsset

class ProfileEditingDestinationHostingViewController: UIHostingController<AnyView> {
    private let viewModel: ProfileViewModel
    
    init(_ type: ProfileEditDestinationType, navigator: MastodonNavigationRouter) {
        let viewModel = type.profileViewModel
        self.viewModel = viewModel
        super.init(rootView: AnyView(ProfileEditingDestinationView(destinationType: type).environment(viewModel).environment(viewModel.editingViewModel).environment(navigator)))
        
    }
    
    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ProfileEditingDestinationView: View {
    @Environment(ProfileViewModel.self) var profileViewModel
    @Environment(ProfileEditingViewModel.self) var editingViewModel
    
    @Environment(\.dismiss) var dismiss
    
    let destinationType: ProfileEditDestinationType
    
    var body: some View {
        if destinationType.expectsModalPresentation {
            NavigationStack() {
                rootContents
                    .navigationTitle(profileViewModel.navigationTitle(destinationType))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        if destinationType.expectsModalPresentation {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button {
                                    dismiss()
                                } label: {
                                    Image(systemName: "xmark")
                                }
                            }
                            
                            ToolbarItem(placement: .navigationBarTrailing) {
                                switch editingViewModel.editingStatus?.saveButton {
                                case .noButton, .none:
                                    EmptyView()
                                case .canSave:
                                    Button {
                                        Task {
                                            do {
                                                try await profileViewModel.commitEdits()
                                                dismiss()
                                            } catch {
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "checkmark")
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(Asset.Colors.accent.swiftUIColor)
                                case .saveInProgress:
                                    ProgressView().progressViewStyle(.circular)
                                }
                            }
                        }
                    }
            }
        } else {
                rootContents
                    .navigationTitle(profileViewModel.navigationTitle(destinationType))
                    .navigationBarTitleDisplayMode(.inline)
        }
      
    }
    
    @ViewBuilder var rootContents: some View {
        switch destinationType {
        case .displayName:
            EditDisplayNameView()
                .environment(editingViewModel)
                .environment(editingViewModel.displayNameFieldEditingViewModel)
        case .bio:
            EditBioView()
                .environment(editingViewModel)
        case .customFields:
            Text(destinationType.id)
        case .featuredHashtags:
            Text(destinationType.id)
        case .profileTabSettings:
            Text(destinationType.id)
        }
    }
}

extension ProfileViewModel {
    func navigationTitle(_ destination: ProfileEditDestinationType) -> String {
        // TODO: L10n
        switch destination {
        case .displayName:
            "Edit display name"
        case .bio:
            if bioIsEmpty {
                "Add bio"
            } else {
                "Edit bio"
            }
        case .customFields:
            "Custom fields"
        case .featuredHashtags:
            "Featured hashtags"
        case .profileTabSettings:
            "Profile tab settings"
        }
    }
}

struct EditDisplayNameView: View {
    @Environment(ProfileEditingViewModel.self) var editingViewModel
    @Environment(MetaTextInputFieldViewModel.self) var textInputModel
    
    @FocusState var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: tinySpacing) {
            MetaTextInputField(allowScroll: false, drawBackground: false, returnKeyType: .done)
                .frame(height: 36)
                .focused($isFocused)
            CharacterLimitTip()
                .padding(.leading)
            Spacer()
        }
        .padding(doublePadding)
        .onAppear() {
            isFocused = true
        }
        .onChange(of: textInputModel.stringContent) { oldValue, newValue in
            if newValue.last == "\n" {
                isFocused = false
                editingViewModel.checkForChanges()
            }
        }
    }
}

struct EditBioView: View {
    @Environment(ProfileEditingViewModel.self) var editingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: tinySpacing) {
            SubsectionHeading(title: "Bio", subtitle: "Introduce yourself. Recommended 220 character maximum.") // TODO: needs L10n
            MetaTextInputField(allowScroll: true, drawBackground: false, returnKeyType: .default)
                .environment(editingViewModel.bioFieldEditingViewModel)
                .frame(height: 56)
        }
    }
}

struct CharacterLimitTip: View {
    @Environment(MetaTextInputFieldViewModel.self) var inputModel
    
    var body: some View {
        Text(message(forCharacterCount: inputModel.characterCount))
            .font(.footnote)
            .foregroundStyle(characterLimit - inputModel.characterCount < 0 ? overLimitColor : .secondary)
    }
    
    func message(forCharacterCount usedCharacterCount: Int) -> String {
        // TODO: L10n
        switch inputModel.characterLimit {
        case .hardLimit(let limit):
            if inputModel.characterCount == 0 {
                "\(limit) character maximum"
            } else {
                "\(usedCharacterCount)/\(characterLimit) characters"
            }
        case .softLimit(let limit):
            "Tip: try to keep this short, under \(limit) characters is best"
        }
    }
    
    var characterLimit: Int {
        switch inputModel.characterLimit {
        case .hardLimit(let limit), .softLimit(let limit):
            return limit
        }
    }
    
    var overLimitColor: Color {
        switch inputModel.characterLimit {
        case .hardLimit:
                .red
        case .softLimit:
                .yellow
        }
    }
}
