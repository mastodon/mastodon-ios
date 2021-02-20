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
    let applicationToken: Mastodon.Entity.Token
    let isRegistering = CurrentValueSubject<Bool, Never>(false)
    let username = CurrentValueSubject<String?, Never>(nil)
    
    // output
    let applicationAuthorization: Mastodon.API.OAuth.Authorization
    let isUsernameValid = CurrentValueSubject<Bool?, Never>(nil)
    let error = CurrentValueSubject<Error?, Never>(nil)

    init(domain: String, applicationToken: Mastodon.Entity.Token) {
        self.domain = domain
        self.applicationToken = applicationToken
        self.applicationAuthorization = Mastodon.API.OAuth.Authorization(accessToken: applicationToken.accessToken)
        
        username
            .map { username in
                guard let username = username else {
                    return nil
                }
                return !username.isEmpty
            }
            .assign(to: \.value, on: isUsernameValid)
            .store(in: &disposeBag)
    }
}

extension MastodonRegisterViewModel {
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    func validatePassword(text: String) -> (Bool, Bool, Bool) {
        let trimmedText = text.trimmingCharacters(in: .whitespaces)
        let isEightCharacters = trimmedText.count >= 8
        let isOneNumber = trimmedText.range(of: ".*[0-9]", options: .regularExpression) != nil
        let isOneSpecialCharacter = trimmedText.trimmingCharacters(in: .decimalDigits).trimmingCharacters(in: .letters).count > 0
        return (isEightCharacters, isOneNumber, isOneSpecialCharacter)
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

    func attributeStringForPassword(eightCharacters: Bool = false, oneNumber: Bool = false, oneSpecialCharacter: Bool = false) -> NSAttributedString {
        let font = UIFont.preferredFont(forTextStyle: .caption1)
        let color = UIColor.black
        let falseColor = UIColor.clear
        let attributeString = NSMutableAttributedString()
        
        let start = NSAttributedString(string: "Your password needs at least:\n", attributes: [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: color])
        attributeString.append(start)
        
        attributeString.append(checkImage(color: eightCharacters ? color : falseColor))
        let eightCharactersDescription = NSAttributedString(string: "Eight characters\n", attributes: [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: color])
        attributeString.append(eightCharactersDescription)
        
        attributeString.append(checkImage(color: oneNumber ? color : falseColor))
        let oneNumberDescription = NSAttributedString(string: "One number\n", attributes: [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: color])
        attributeString.append(oneNumberDescription)
        
        attributeString.append(checkImage(color: oneSpecialCharacter ? color : falseColor))
        let oneSpecialCharacterDescription = NSAttributedString(string: "One special character\n", attributes: [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: color])
        attributeString.append(oneSpecialCharacterDescription)
        
        return attributeString
    }

    func checkImage(color: UIColor) -> NSAttributedString {
        let checkImage = NSTextAttachment()
        let font = UIFont.preferredFont(forTextStyle: .caption1)
        let configuration = UIImage.SymbolConfiguration(font: font)
        checkImage.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: configuration)?.withTintColor(color)
        return NSAttributedString(attachment: checkImage)
    }
}
