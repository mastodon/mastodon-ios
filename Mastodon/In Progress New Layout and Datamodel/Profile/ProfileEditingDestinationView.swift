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
    
    @State var hasChanges = false
    
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
                                Button {
                                } label: {
                                    Image(systemName: "checkmark")
                                        .tint(hasChanges ? Asset.Colors.accent.swiftUIColor : nil)
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
            Text(destinationType.id)
        case .bio:
            Text(destinationType.id)
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
