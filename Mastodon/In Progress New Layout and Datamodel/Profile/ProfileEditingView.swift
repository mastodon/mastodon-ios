// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonUI
import MastodonLocalization
import MastodonAsset

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
    
    @State var fieldEditingViewModel = MetaTextInputFieldViewModel(stringContent: "", placeholder: "Placeholder", characterLimit: .softLimit(200))
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                ProfileAvatarAndBannerView(width: geo.size.width)
                    .environment(profileViewModel)
                    .environment(editingViewModel)
                MetaTextInputField()
                    .environment(fieldEditingViewModel)
                    .padding()
                Spacer()
                    .frame(maxHeight: .infinity)
            }
            .overlay {
                fieldEditingViewModel.autoCompleteSuggestionView(pinToTopOfKeyboard: true)
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
}

@MainActor
@Observable
class ProfileEditingViewModel {
    var hasUnsavedChanges: Bool = false
}
