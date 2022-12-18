//
//  MastodonRegisterView.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-27.
//

import UIKit
import SwiftUI
import MastodonLocalization
import MastodonSDK
import MastodonAsset

struct MastodonRegisterView: View {
    
    @ObservedObject var viewModel: MastodonRegisterViewModel
    
    @State var usernameRightViewWidth: CGFloat = 300
    
    var body: some View {
        ScrollView(.vertical) {
            let margin: CGFloat = 16
            // Display Name & Username
            VStack(alignment: .leading, spacing: 11) {
                TextField(L10n.Scene.Register.Input.DisplayName.placeholder.localizedCapitalized, text: $viewModel.name)
                    .textContentType(.name)
                    .disableAutocorrection(true)
                    .modifier(FormTextFieldModifier(validateState: viewModel.displayNameValidateState))
                HStack {
                    TextField(L10n.Scene.Register.Input.Username.placeholder.localizedCapitalized, text: $viewModel.username)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.asciiCapable)
                    Text("@\(viewModel.domain)")
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .measureWidth { usernameRightViewWidth = $0 }
                        .frame(width: min(300.0, usernameRightViewWidth), alignment: .trailing)
                }
                .modifier(FormTextFieldModifier(validateState: viewModel.usernameValidateState))
                .environment(\.layoutDirection, .leftToRight)   // force LTR
                if let errorPrompt = viewModel.usernameErrorPrompt {
                    Text(errorPrompt)
                        .modifier(FormFootnoteModifier())
                }
            }
            .padding(.horizontal, margin)
            .padding(.bottom, 22)
            
            // Email & Password & Password hint
            VStack(alignment: .leading, spacing: 11) {
                TextField(L10n.Scene.Register.Input.Email.placeholder.localizedCapitalized, text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.emailAddress)
                    .modifier(FormTextFieldModifier(validateState: viewModel.emailValidateState))
                if let errorPrompt = viewModel.emailErrorPrompt {
                    Text(errorPrompt)
                        .modifier(FormFootnoteModifier())
                }
                SecureField(L10n.Scene.Register.Input.Password.placeholder.localizedCapitalized, text: $viewModel.password)
                    .textContentType(.newPassword)
                    .modifier(FormTextFieldModifier(validateState: viewModel.passwordValidateState))
                Text(L10n.Scene.Register.Input.Password.hint)
                    .modifier(FormFootnoteModifier(foregroundColor: .secondary))
                if let errorPrompt = viewModel.passwordErrorPrompt {
                    Text(errorPrompt)
                        .modifier(FormFootnoteModifier())
                }
            }
            .padding(.horizontal, margin)
            .padding(.bottom, 22)
            
            // Reason
            if viewModel.approvalRequired {
                VStack(alignment: .leading, spacing: 11) {
                    TextField(L10n.Scene.Register.Input.Invite.registrationUserInviteRequest.localizedCapitalized, text: $viewModel.reason)
                        .modifier(FormTextFieldModifier(validateState: viewModel.reasonValidateState))
                    if let errorPrompt = viewModel.reasonErrorPrompt {
                        Text(errorPrompt)
                            .modifier(FormFootnoteModifier())
                    }
                }
                .padding(.horizontal, margin)
            }
            
            Spacer()
                .frame(minHeight: viewModel.bottomPaddingHeight)
        }
        .background(
            Color(viewModel.backgroundColor)
                .onTapGesture {
                    viewModel.endEditing.send()
                }
        )
    }
    
    struct FormTextFieldModifier: ViewModifier {
        var validateState: MastodonRegisterViewModel.ValidateState

        func body(content: Content) -> some View {
            ZStack {
                let borderColor: Color = {
                    switch validateState {
                        case .empty:    return Color(Asset.Scene.Onboarding.textFieldBackground.color)
                        case .invalid:  return Color(Asset.Colors.TextField.invalid.color)
                        case .valid:    return Color(Asset.Scene.Onboarding.textFieldBackground.color)
                    }
                }()

                Color(Asset.Scene.Onboarding.textFieldBackground.color)
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.125), radius: 1, x: 0, y: 2)

                content
                    .padding()
                    .background(Color(Asset.Scene.Onboarding.textFieldBackground.color))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(borderColor, lineWidth: 1)
                            .animation(.easeInOut, value: validateState)
                    )
            }
        }
    }
    
    struct FormFootnoteModifier: ViewModifier {
        var foregroundColor = Color(Asset.Colors.TextField.invalid.color)
        func body(content: Content) -> some View {
            content
                .font(.footnote)
                .foregroundColor(foregroundColor)
                .padding(.horizontal)
        }
    }
    
}

struct WidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    func measureWidth(_ f: @escaping (CGFloat) -> ()) -> some View {
        overlay(GeometryReader { proxy in
            Color.clear.preference(key: WidthKey.self, value: proxy.size.width)
        }
        .onPreferenceChange(WidthKey.self, perform: f))
    }
}

#if DEBUG
struct MastodonRegisterView_Previews: PreviewProvider {
    static var viewMdoel: MastodonRegisterViewModel {
        let domain = "mstdn.jp"
        return MastodonRegisterViewModel(
            context: .shared,
            domain: domain,
            authenticateInfo: AuthenticationViewModel.AuthenticateInfo(
                domain: domain,
                application:  Mastodon.Entity.Application(
                    name: "Preview",
                    website: nil,
                    vapidKey: nil,
                    redirectURI: nil,
                    clientID: "",
                    clientSecret: ""
                ),
                redirectURI: ""
            )!,
            instance: Mastodon.Entity.Instance(domain: "mstdn.jp"),
            applicationToken: Mastodon.Entity.Token(
                accessToken: "",
                tokenType: "",
                scope: "",
                createdAt: Date()
            )
        )
    }
    
    static var viewMdoel2: MastodonRegisterViewModel {
        let domain = "mstdn.jp"
        return MastodonRegisterViewModel(
            context: .shared,
            domain: domain,
            authenticateInfo: AuthenticationViewModel.AuthenticateInfo(
                domain: domain,
                application:  Mastodon.Entity.Application(
                    name: "Preview",
                    website: nil,
                    vapidKey: nil,
                    redirectURI: nil,
                    clientID: "",
                    clientSecret: ""
                ),
                redirectURI: ""
            )!,
            instance: Mastodon.Entity.Instance(domain: "mstdn.jp", approvalRequired: true),
            applicationToken: Mastodon.Entity.Token(
                accessToken: "",
                tokenType: "",
                scope: "",
                createdAt: Date()
            )
        )
    }
            
    static var previews: some View {
        Group {
            NavigationView {
                MastodonRegisterView(viewModel: viewMdoel)
                    .navigationBarTitle(Text(""))
                    .navigationBarTitleDisplayMode(.inline)
            }
            NavigationView {
                MastodonRegisterView(viewModel: viewMdoel)
                    .navigationBarTitle(Text(""))
                    .navigationBarTitleDisplayMode(.inline)
            }
            .preferredColorScheme(.dark)
            NavigationView {
                MastodonRegisterView(viewModel: viewMdoel)
                    .navigationBarTitle(Text(""))
                    .navigationBarTitleDisplayMode(.inline)
            }
            .environment(\.sizeCategory, .accessibilityExtraLarge)
            NavigationView {
                MastodonRegisterView(viewModel: viewMdoel2)
                    .navigationBarTitle(Text(""))
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
#endif
