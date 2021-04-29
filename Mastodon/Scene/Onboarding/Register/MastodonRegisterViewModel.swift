//
//  MastodonRegisterViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-5.
//

import Combine
import Foundation
import MastodonSDK
import UIKit

final class MastodonRegisterViewModel {
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let domain: String
    let authenticateInfo: AuthenticationViewModel.AuthenticateInfo
    let instance: Mastodon.Entity.Instance
    let applicationToken: Mastodon.Entity.Token
    let context: AppContext
    
    let username = CurrentValueSubject<String, Never>("")
    let displayName = CurrentValueSubject<String, Never>("")
    let email = CurrentValueSubject<String, Never>("")
    let password = CurrentValueSubject<String, Never>("")
    let reason = CurrentValueSubject<String, Never>("")
    let avatarImage = CurrentValueSubject<UIImage?, Never>(nil)
    
    let usernameErrorPrompt = CurrentValueSubject<NSAttributedString?, Never>(nil)
    let emailErrorPrompt = CurrentValueSubject<NSAttributedString?, Never>(nil)
    let passwordErrorPrompt = CurrentValueSubject<NSAttributedString?, Never>(nil)
    let reasonErrorPrompt = CurrentValueSubject<NSAttributedString?, Never>(nil)
    
    // output
    let approvalRequired: Bool
    let applicationAuthorization: Mastodon.API.OAuth.Authorization
    let usernameValidateState = CurrentValueSubject<ValidateState, Never>(.empty)
    let displayNameValidateState = CurrentValueSubject<ValidateState, Never>(.empty)
    let emailValidateState = CurrentValueSubject<ValidateState, Never>(.empty)
    let passwordValidateState = CurrentValueSubject<ValidateState, Never>(.empty)
    let reasonValidateState = CurrentValueSubject<ValidateState, Never>(.empty)
        
    let isRegistering = CurrentValueSubject<Bool, Never>(false)
    let isAllValid = CurrentValueSubject<Bool, Never>(false)
    let error = CurrentValueSubject<Error?, Never>(nil)

    init(
        domain: String,
        context: AppContext,
        authenticateInfo: AuthenticationViewModel.AuthenticateInfo,
        instance: Mastodon.Entity.Instance,
        applicationToken: Mastodon.Entity.Token
    ) {
        self.domain = domain
        self.context = context
        self.authenticateInfo = authenticateInfo
        self.instance = instance
        self.applicationToken = applicationToken
        self.approvalRequired = instance.approvalRequired ?? false
        self.applicationAuthorization = Mastodon.API.OAuth.Authorization(accessToken: applicationToken.accessToken)
        
        username
            .map { username in
                guard !username.isEmpty else { return .empty }
                var isValid = true
                
                // regex opt-out way to check validation
                // allowed:
                // a-z (isASCII && isLetter)
                // A-Z (isASCII && isLetter)
                // 0-9 (isASCII && isNumber)
                // _ ("_")
                for char in username {
                    guard char.isASCII, char.isLetter || char.isNumber || char == "_" else {
                        isValid = false
                        break
                    }
                }
                return isValid ? .valid : .invalid
            }
            .assign(to: \.value, on: usernameValidateState)
            .store(in: &disposeBag)
        
        username
            .filter { !$0.isEmpty }
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .compactMap { [weak self] text -> AnyPublisher<Result<Mastodon.Response.Content<Mastodon.Entity.Account>, Error>, Never>? in
                guard let self = self else { return nil }
                let query = Mastodon.API.Account.AccountLookupQuery(acct: text)
                return context.apiService.accountLookup(domain: domain, query: query, authorization: self.applicationAuthorization)
                    .map {
                        response -> Result<Mastodon.Response.Content<Mastodon.Entity.Account>, Error>in
                        Result.success(response)
                    }
                    .catch { error in
                        Just(Result.failure(error))
                    }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .sink(receiveCompletion: { _ in
                
            }, receiveValue: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    let text = L10n.Scene.Register.Error.Reason.taken(L10n.Scene.Register.Error.Item.username)
                    self.usernameErrorPrompt.value = MastodonRegisterViewModel.errorPromptAttributedString(for: text)
                case .failure:
                    break
                }
            })
            .store(in: &disposeBag)
        
        usernameValidateState
            .sink { [weak self] validateState in
                if validateState == .valid {
                    self?.usernameErrorPrompt.value = nil
                }
            }
            .store(in: &disposeBag)

        displayName
            .map { displayname in
                guard !displayname.isEmpty else { return .empty }
                return .valid
            }
            .assign(to: \.value, on: displayNameValidateState)
            .store(in: &disposeBag)
        email
            .map { email in
                guard !email.isEmpty else { return .empty }
                return MastodonRegisterViewModel.isValidEmail(email) ? .valid : .invalid
            }
            .assign(to: \.value, on: emailValidateState)
            .store(in: &disposeBag)
        password
            .map { password in
                guard !password.isEmpty else { return .empty }
                return password.count >= 8 ? .valid : .invalid
            }
            .assign(to: \.value, on: passwordValidateState)
            .store(in: &disposeBag)
        if approvalRequired {
            reason
                .map { invite in
                    guard !invite.isEmpty else { return .empty }
                    return .valid
                }
                .assign(to: \.value, on: reasonValidateState)
                .store(in: &disposeBag)
        }
        
        error
            .sink { [weak self] error in
                guard let self = self else { return }
                let error = error as? Mastodon.API.Error
                let mastodonError = error?.mastodonError
                if case let .generic(genericMastodonError) = mastodonError,
                   let details = genericMastodonError.details
                {
                    self.usernameErrorPrompt.value = details.usernameErrorDescriptions.first.flatMap { MastodonRegisterViewModel.errorPromptAttributedString(for: $0) }
                    self.emailErrorPrompt.value = details.emailErrorDescriptions.first.flatMap { MastodonRegisterViewModel.errorPromptAttributedString(for: $0) }
                    self.passwordErrorPrompt.value = details.passwordErrorDescriptions.first.flatMap { MastodonRegisterViewModel.errorPromptAttributedString(for: $0) }
                    self.reasonErrorPrompt.value = details.reasonErrorDescriptions.first.flatMap { MastodonRegisterViewModel.errorPromptAttributedString(for: $0) }
                } else {
                    self.usernameErrorPrompt.value = nil
                    self.emailErrorPrompt.value = nil
                    self.passwordErrorPrompt.value = nil
                    self.reasonErrorPrompt.value = nil
                }
            }
            .store(in: &disposeBag)
        
        let publisherOne = Publishers.CombineLatest4(
            usernameValidateState.eraseToAnyPublisher(),
            displayNameValidateState.eraseToAnyPublisher(),
            emailValidateState.eraseToAnyPublisher(),
            passwordValidateState.eraseToAnyPublisher()
        )
        .map { $0.0 == .valid && $0.1 == .valid && $0.2 == .valid && $0.3 == .valid }
        
        Publishers.CombineLatest(
            publisherOne,
            approvalRequired ? reasonValidateState.map { $0 == .valid }.eraseToAnyPublisher() : Just(true).eraseToAnyPublisher()
        )
        .map { $0 && $1 }
        .assign(to: \.value, on: isAllValid)
        .store(in: &disposeBag)
    }
}

extension MastodonRegisterViewModel {
    enum ValidateState {
        case empty
        case invalid
        case valid
    }
}

extension MastodonRegisterViewModel {
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    static func checkmarkImage(font: UIFont = .preferredFont(forTextStyle: .caption1)) -> UIImage {
        let configuration = UIImage.SymbolConfiguration(font: font)
        return UIImage(systemName: "checkmark.circle.fill", withConfiguration: configuration)!
    }
    
    static func xmarkImage(font: UIFont = .preferredFont(forTextStyle: .caption1)) -> UIImage {
        let configuration = UIImage.SymbolConfiguration(font: font)
        return UIImage(systemName: "xmark.octagon.fill", withConfiguration: configuration)!
    }

    static func attributedStringImage(with image: UIImage, tintColor: UIColor) -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = image.withTintColor(tintColor)
        return NSAttributedString(attachment: attachment)
    }
    
    static func attributeStringForPassword(validateState: ValidateState) -> NSAttributedString {
        let font = UIFont.preferredFont(forTextStyle: .caption1)
        let attributeString = NSMutableAttributedString()

        let image = MastodonRegisterViewModel.checkmarkImage(font: font)
        attributeString.append(attributedStringImage(with: image, tintColor: validateState == .valid ? Asset.Colors.Label.primary.color : .clear))
        attributeString.append(NSAttributedString(string: " "))
        let eightCharactersDescription = NSAttributedString(string: L10n.Scene.Register.Input.Password.hint, attributes: [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: Asset.Colors.Label.primary.color])
        attributeString.append(eightCharactersDescription)
        
        return attributeString
    }
    
    static func errorPromptAttributedString(for prompt: String) -> NSAttributedString {
        let font = UIFont.preferredFont(forTextStyle: .caption1)
        let attributeString = NSMutableAttributedString()

        let image = MastodonRegisterViewModel.xmarkImage(font: font)
        attributeString.append(attributedStringImage(with: image, tintColor: Asset.Colors.danger.color))
        attributeString.append(NSAttributedString(string: " "))
        
        let promptAttributedString = NSAttributedString(string: prompt, attributes: [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: Asset.Colors.danger.color])
        attributeString.append(promptAttributedString)
        
        return attributeString
    }
}
