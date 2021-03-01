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
    
    let username = CurrentValueSubject<String, Never>("")
    let displayName = CurrentValueSubject<String, Never>("")
    let email = CurrentValueSubject<String, Never>("")
    let password = CurrentValueSubject<String, Never>("")
    let reason = CurrentValueSubject<String, Never>("")
    
    // output
    let approvalRequired: Bool
    let applicationAuthorization: Mastodon.API.OAuth.Authorization
    let usernameValidateState = CurrentValueSubject<ValidateState, Never>(.empty)
    let displayNameValidateState = CurrentValueSubject<ValidateState, Never>(.empty)
    let emailValidateState = CurrentValueSubject<ValidateState, Never>(.empty)
    let passwordValidateState = CurrentValueSubject<ValidateState, Never>(.empty)
    let inviteValidateState = CurrentValueSubject<ValidateState, Never>(.empty)
    
    let isUsernameTaken = CurrentValueSubject<Bool, Never>(false)
    
    let isRegistering = CurrentValueSubject<Bool, Never>(false)
    let isAllValid = CurrentValueSubject<Bool, Never>(false)
    let error = CurrentValueSubject<Error?, Never>(nil)

    init(
        domain: String,
        authenticateInfo: AuthenticationViewModel.AuthenticateInfo,
        instance: Mastodon.Entity.Instance,
        applicationToken: Mastodon.Entity.Token
    ) {
        self.domain = domain
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
                .assign(to: \.value, on: inviteValidateState)
                .store(in: &disposeBag)
        }
        let publisherOne = Publishers.CombineLatest4(
            usernameValidateState.eraseToAnyPublisher(),
            displayNameValidateState.eraseToAnyPublisher(),
            emailValidateState.eraseToAnyPublisher(),
            passwordValidateState.eraseToAnyPublisher()
        ).map {
            $0.0 == .valid && $0.1 == .valid && $0.2 == .valid && $0.3 == .valid
        }
        
        Publishers.CombineLatest(
            publisherOne,
            approvalRequired ? inviteValidateState.map {$0 == .valid}.eraseToAnyPublisher() : Just(true).eraseToAnyPublisher()
        )
        .map {
            return $0 && $1
        }
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

    func attributeStringForUsername() -> NSAttributedString {
        let resultAttributeString = NSMutableAttributedString()
        let redImage = NSTextAttachment()
        let font = UIFont.preferredFont(forTextStyle: .caption1)
        let configuration = UIImage.SymbolConfiguration(font: font)
        redImage.image = UIImage(systemName: "xmark.octagon.fill", withConfiguration: configuration)?.withTintColor(Asset.Colors.lightDangerRed.color)
        let imageAttribute = NSAttributedString(attachment: redImage)
        let stringAttribute = NSAttributedString(string: "This username is taken.", attributes: [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: Asset.Colors.lightDangerRed.color])
        resultAttributeString.append(imageAttribute)
        resultAttributeString.append(stringAttribute)
        return resultAttributeString
    }

    func attributeStringForPassword(eightCharacters: Bool = false) -> NSAttributedString {
        let font = UIFont.preferredFont(forTextStyle: .caption1)
        let color = UIColor.black
        let falseColor = UIColor.clear
        let attributeString = NSMutableAttributedString()
        
        let start = NSAttributedString(string: "Your password needs at least:\n", attributes: [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: color])
        attributeString.append(start)
        
        attributeString.append(checkmarkImage(color: eightCharacters ? color : falseColor))
        let eightCharactersDescription = NSAttributedString(string: " Eight characters\n", attributes: [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: color])
        attributeString.append(eightCharactersDescription)
        
        return attributeString
    }

    func checkmarkImage(color: UIColor) -> NSAttributedString {
        let checkmarkImage = NSTextAttachment()
        let font = UIFont.preferredFont(forTextStyle: .caption1)
        let configuration = UIImage.SymbolConfiguration(font: font)
        checkmarkImage.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: configuration)?.withTintColor(color)
        return NSAttributedString(attachment: checkmarkImage)
    }
}
