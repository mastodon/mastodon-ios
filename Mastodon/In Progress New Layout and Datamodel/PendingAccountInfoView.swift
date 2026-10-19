// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonAsset
import MastodonCore
import MastodonLocalization
import MastodonSDK

/// To be shown as a modal while the registration is pending email confirmation or admin approval.
/// Polls the server for a change in status while on-screen and self-dismisses/switches to the newly activated account as soon as it can be used.
struct PendingAccountInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    let registration: MastodonAuthenticationBox
    let allowsUserDismiss: Bool // if one or more working accounts are available, this should be dismissable.  Otherwise, the only way out of this model is to "Log Out", which will forget this registration.
    
    @State private var accountState: Mastodon.Entity.Account.AccountCreationState?
    @State private var isConfirmingLogout = false
    
    @State private var resendEmailAvailableAt: Date
    @State private var newEmail = ""
    @State private var newEmailSentTo: String? // there is no way to know the email that the account initially signed up with
    @State private var isResendingEmail = false
    @State private var isInputtingNewEmail = false
    @State private var justResentEmail = false
    @State private var registrationIsNoLongerValid = false
    @State private var resendError: String?
    
    init(pendingRegistration: MastodonAuthenticationBox, allowsUserDismiss: Bool) {
        self.registration = pendingRegistration
        self.allowsUserDismiss = allowsUserDismiss
        
        let cachedAccount = pendingRegistration.cachedAccount
        _accountState = State(initialValue: cachedAccount?.accountCreationState)
        _resendEmailAvailableAt = State(initialValue: pendingRegistration.authentication.createdAt.addingTimeInterval(60))
    }
    
    private enum PendingReason {
        case emailConfirmation
        case adminApproval(String?)
        case other(String?)
    }
    
    private var pendingReason: PendingReason {
        switch accountState?.errorCode {
        case nil, .pendingConfirmation: .emailConfirmation
        case .pendingApproval: .adminApproval(accountState?.localizedErrorDescription)
        default: .other(accountState?.localizedErrorDescription)
        }
    }
    
    private var title: String {
        switch pendingReason {
        case .emailConfirmation: L10n.Scene.ConfirmEmail.title
        case .adminApproval: L10nLookup.Scene.Onboarding.AccountNonfunctional.pendingApproval
        case .other: L10nLookup.Scene.Onboarding.AccountNonfunctional.needsAttention
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                switch pendingReason {
                case .emailConfirmation:
                    if let newEmailSentTo {
                        Text(L10n.Scene.ConfirmEmail.tapTheLinkWeEmailedToYouToVerifyYourAccount(newEmailSentTo))
                    } else {
                        Text(L10n.Scene.ConfirmEmail.tapTheLinkWeEmailedToYou)
                    }
                    Asset.Asset.email.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                    didntGetLinkButton
                    if let resendError {
                        Text(resendError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                    } else if justResentEmail {
                        Text(L10n.Scene.ConfirmEmail.OpenEmailApp.description)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                case .adminApproval(let message):
                    Text(message ?? "")
                case .other(let message):
                    Text(message ?? "")
                }
            }
            .padding()
            .frame(maxWidth: maxFeedContentWidth, maxHeight: .infinity, alignment: .top)
            .frame(maxWidth: .infinity)
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10nLookup.ConfirmationDialog.LogOut.ActiveAccount.buttonText, role: .destructive) {
                        isConfirmingLogout = true
                    }
                }
                if allowsUserDismiss {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(L10n.Common.Controls.Actions.done) {
                            dismiss()
                        }
                    }
                }
            }
            .confirmationDialog(L10nLookup.ConfirmationDialog.LogOut.ActiveAccount.title, isPresented: $isConfirmingLogout, titleVisibility: .visible) {
                Button(L10nLookup.ConfirmationDialog.LogOut.ActiveAccount.buttonText, role: .destructive) {
                    Task {
                        await AuthenticationServiceProvider.shared.signOutMastodonUser(authentication: registration.authentication)
                        closeAfterSignOut()
                    }
                }
                Button(L10n.Common.Controls.Actions.cancel, role: .cancel) {}
            } message: {
                Text(L10nLookup.ConfirmationDialog.LogOut.ActiveAccount.message)
            }
            .alert(L10n.Scene.ConfirmEmail.DontReceiveEmail.title, isPresented: $isInputtingNewEmail) {
                TextField(L10n.Scene.Register.Input.Email.placeholder, text: $newEmail)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                Button(L10n.Scene.ConfirmEmail.DontReceiveEmail.resendEmail) {
                    resendConfirmation(changingEmailTo: trimmedNewEmail)
                }.disabled(trimmedNewEmail.isEmpty)
                Button(L10n.Common.Controls.Actions.cancel, role: .cancel) {}
            } message: {
                Text(L10n.Scene.ConfirmEmail.DontReceiveEmail.description)
            }
            .alert(L10nLookup.Scene.Onboarding.AccountNonfunctional.registrationNoLongerValid, isPresented: $registrationIsNoLongerValid) {
                Button(L10n.Common.Controls.Actions.ok) {
                    closeAfterSignOut()
                    Task {
                        await AuthenticationServiceProvider.shared.signOutMastodonUser(authentication: registration.authentication)
                    }
                }
            } message: {
                Text(L10nLookup.Scene.Onboarding.AccountNonfunctional.youCanRegisterAgain)
            }
        }
        .interactiveDismissDisabled(!allowsUserDismiss)
        .task { await checkAccountUntilUsable() }
    }
    
    private var didntGetLinkButton: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let secondsLeft = Int(resendEmailAvailableAt.timeIntervalSince(context.date).rounded(.up))
            
            Menu {
                Button(L10n.Scene.ConfirmEmail.DontReceiveEmail.resendEmail) {
                    resendConfirmation(changingEmailTo: nil)
                }
                Button(L10n.Scene.ConfirmEmail.DontReceiveEmail.changeEmail, role: .destructive) {
                    isInputtingNewEmail = true
                }
            } label: {
                didntGetLinkLabel(secondsLeft: secondsLeft)
                    .font(.subheadline)
            }
            .disabled(secondsLeft > 0 || isResendingEmail)
            .tint(Asset.Colors.accent.swiftUIColor)
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder private func didntGetLinkLabel(secondsLeft: Int) -> some View {
        let didntGetLinkText = Text(L10n.Scene.ConfirmEmail.DidntGetLink.prefix)
        let actionText = Text(secondsLeft > 0
        ? L10n.Scene.ConfirmEmail.DidntGetLink.resendIn(secondsLeft)
        : L10n.Scene.ConfirmEmail.DidntGetLink.resendNow)
            .bold()
            .monospacedDigit()
        Text("\(didntGetLinkText) \(actionText)")
    }
    
    private var trimmedNewEmail: String {
        newEmail.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func resendConfirmation(changingEmailTo email: String?) {
        isResendingEmail = true
        resendError = nil
        justResentEmail = false
        Task {
            defer { isResendingEmail = false }
            do {
                try await APIService.shared.resendConfirmationEmail(domain: registration.domain, email: email, authorization: registration.userAuthorization)
                justResentEmail = true
                if let email {
                    newEmailSentTo = email
                }
                resendEmailAvailableAt = Date.now.addingTimeInterval(60)
            } catch {
                resendError = error.localizedDescription
            }
        }
    }
    
    private func checkAccountUntilUsable() async {
        let authentication = registration.authentication
        while !Task.isCancelled {
            do {
                let account = try await APIService.shared.verifyCredentials(domain: registration.domain, allowNonfunctional: true, authorization: registration.userAuthorization)
                if account.accountCreationState?.errorCode != nil {
                    if account.accountCreationState != accountState {
                        accountState = account.accountCreationState
                        PersistenceManager.shared.cacheAccount(account, forUserID: authentication.userIdentifier())
                    }
                } else {
                    // account is ready
                    _ = try await APIService.shared.verifyAndActivateUser(domain: registration.domain, clientID: authentication.clientID, clientSecret: authentication.clientSecret, authorization: registration.userAuthorization)
                    return
                }
            } catch let error as Mastodon.API.Error where error.httpResponseStatus == .unauthorized {
                // if the registration was left unconfirmed for too long, the server will have deleted it
                registrationIsNoLongerValid = true
                return
            } catch {
                // nothing to do. will retry at next timer tick
            }
            try? await Task.sleep(for: .seconds(4))
        }
    }
    
    private func closeAfterSignOut() {
        if allowsUserDismiss { dismiss() }
    }
}
