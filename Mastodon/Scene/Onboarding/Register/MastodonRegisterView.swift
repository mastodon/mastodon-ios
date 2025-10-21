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
    
    @FocusState var focusedField: MastodonRegisterViewModel.RegistrationField?
    
    @ObservedObject var viewModel: MastodonRegisterViewModel
    
    @State var usernameRightViewWidth: CGFloat = 300
    
    @State var dateOfBirthLabel = L10n.Scene.Register.Input.BirthDate.label.localizedCapitalized
    
    var body: some View {
        ScrollView(.vertical) {
            let margin: CGFloat = 16
            VStack(alignment: .leading, spacing: 16) {
                Spacer()
                if let minAge = viewModel.minAge {
                    dateOfBirthEntry(minAge: minAge)
                }
                TextField(L10n.Scene.Register.Input.DisplayName.placeholder.localizedCapitalized, text: $viewModel.name)
                    .textContentType(.name)
                    .disableAutocorrection(true)
                    .modifier(FormTextFieldModifier(validateState: viewModel.displayNameValidateState))
                    .focused($focusedField, equals: .displayName)
                HStack {
                    Text("@")
                        .accessibilityHidden(true)
                    TextField(L10n.Scene.Register.Input.Username.placeholder.localizedCapitalized, text: $viewModel.username)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.asciiCapable)
                        .accessibilityLabel(viewModel.accessibilityLabelUsernameField)
                        .focused($focusedField, equals: .handle)
                    Text("@\(viewModel.domain)")
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .measureWidth { usernameRightViewWidth = $0 }
                        .frame(width: min(300.0, usernameRightViewWidth), alignment: .trailing)
                        .accessibilityHidden(true)
                }
                .modifier(FormTextFieldModifier(validateState: viewModel.usernameValidateState))
                .environment(\.layoutDirection, .leftToRight)   // force LTR
                if let errorPrompt = viewModel.usernameErrorPrompt {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(errorPrompt)
                            .font(Font(UIFontMetrics(forTextStyle: .caption1).scaledFont(for: .systemFont(ofSize: 13, weight: .regular))))
                        //FIXME: Better way than comparing strings
                        if errorPrompt == L10n.Scene.Register.Error.Reason.taken(L10n.Scene.Register.Error.Item.username) {
                            Button {
                                viewModel.usernameErrorPrompt = nil
                                viewModel.usernameValidateState = .empty
                                viewModel.username = L10n.Scene.Register.Input.Username.suggestion(viewModel.username)
                            } label: {
                                Text(L10n.Scene.Register.Input.Username.suggestion(viewModel.username))
                                    .foregroundColor(Asset.Colors.Brand.blurple.swiftUIColor)
                                    .font(Font(UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .bold))))

                            }
                        }
                    }
                }
                TextField(L10n.Scene.Register.Input.Email.placeholder.localizedCapitalized, text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.emailAddress)
                    .modifier(FormTextFieldModifier(validateState: viewModel.emailValidateState))
                    .focused($focusedField, equals: .email)
                if let errorPrompt = viewModel.emailErrorPrompt {
                    Text(errorPrompt)
                        .modifier(FormFootnoteModifier())
                }

            }
            .padding(.horizontal, margin)
            .padding(.bottom, 32)
            
            // Email & Password & Password hint
            VStack(alignment: .leading, spacing: margin) {
                SecureField(L10n.Scene.Register.Input.Password.placeholder.localizedCapitalized, text: $viewModel.password)
                    .textContentType(.newPassword)
                    .modifier(FormTextFieldModifier(validateState: viewModel.passwordBaseValidateState))
                    .focused($focusedField, equals: .password)
                SecureField(L10n.Scene.Register.Input.Password.confirmationPlaceholder.localizedCapitalized, text: $viewModel.passwordConfirmation)
                    .textContentType(.newPassword)
                    .modifier(FormTextFieldModifier(validateState: viewModel.passwordConfirmationValidateState))
                    .focused($focusedField, equals: .confirmPassword)
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
            if viewModel.reasonRequired {
                VStack(alignment: .leading, spacing: 11) {
                    TextField(L10n.Scene.Register.Input.Invite.registrationUserInviteRequest.localizedCapitalized, text: $viewModel.reason)
                        .modifier(FormTextFieldModifier(validateState: viewModel.reasonValidateState))
                        .focused($focusedField, equals: .proposedApprovalReason)
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
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: focusedField) { _, newValue in
            viewModel.editingField = newValue
        }
    }
    
    struct FormTextFieldModifier: ViewModifier {
        var validateState: MastodonRegisterViewModel.ValidateState

        func body(content: Content) -> some View {
            ZStack {
                let borderColor: Color = {
                    switch validateState {
                        case .empty, .filling:    return Color(Asset.Scene.Onboarding.textFieldBackground.color)
                        case .invalid:  return Color(Asset.Colors.TextField.invalid.color.withAlphaComponent(0.25))
                        case .valid:    return Color(Asset.Scene.Onboarding.textFieldBackground.color)
                    }
                }()

                borderColor
                    .cornerRadius(10)

                content
                    .padding()
                    .background(borderColor)
                    .cornerRadius(10)
            }
        }
    }
    
    struct FormFootnoteModifier: ViewModifier {
        var foregroundColor = Color(Asset.Colors.TextField.invalid.color)
        func body(content: Content) -> some View {
            content
                .font(.footnote)
                .foregroundColor(foregroundColor)
        }
    }
 
    @ViewBuilder func dateOfBirthEntry(minAge: Int) -> some View {
        VStack {
            ZStack {
                TextField(L10n.Scene.Register.Input.BirthDate.label.localizedCapitalized, text: $dateOfBirthLabel)
                    .disabled(true)
                    .modifier(FormTextFieldModifier(validateState: viewModel.dateOfBirthValidateState))
                HStack {
                    Spacer().frame(maxWidth: .infinity)
                    DatePicker(selection: $viewModel.dateOfBirth,  in: earliestPossibleBirthdate...Date.now, displayedComponents: .date) { }
                    Spacer()
                }
            }
            Text(L10n.Scene.Register.Input.BirthDate.explanationMessage(minAge, viewModel.domain)).font(.callout)
        }
    }
    
    var earliestPossibleBirthdate: Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        
        return formatter.date(from: "1900-01-01")!
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
    static var viewModel: MastodonRegisterViewModel {
        let domain = "mstdn.jp"
        return MastodonRegisterViewModel(
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
            ),
            submitValidatedUserRegistration: { (_,_) in return }
        )
    }
            
    static var previews: some View {
        Group {
            NavigationView {
                MastodonRegisterView(viewModel: viewModel)
                    .navigationBarTitle(Text(""))
                    .navigationBarTitleDisplayMode(.inline)
            }
            NavigationView {
                MastodonRegisterView(viewModel: viewModel)
                    .navigationBarTitle(Text(""))
                    .navigationBarTitleDisplayMode(.inline)
            }
            .preferredColorScheme(.dark)
            NavigationView {
                MastodonRegisterView(viewModel: viewModel)
                    .navigationBarTitle(Text(""))
                    .navigationBarTitleDisplayMode(.inline)
            }
            .environment(\.sizeCategory, .accessibilityExtraLarge)
            NavigationView {
                MastodonRegisterView(viewModel: viewModel)
                    .navigationBarTitle(Text(""))
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
#endif
