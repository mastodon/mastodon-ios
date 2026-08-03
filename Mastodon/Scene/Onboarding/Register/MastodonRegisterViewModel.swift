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
import MastodonAsset
import MastodonCore
import MastodonLocalization
import SwiftUI

@MainActor
final class MastodonRegisterViewModel: ObservableObject {
    
    enum RegistrationField: Hashable {
        case displayName
        case handle
        case email
        case password
        case confirmPassword
        case dateOfBirth
        case proposedApprovalReason
    }
    
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let domain: String
    let authenticateInfo: AuthenticationViewModel.AuthenticateInfo
    let instance: RegistrationInstance
    let applicationToken: Mastodon.Entity.Token
    let viewDidAppear = CurrentValueSubject<Void, Never>(Void())
    let submitValidatedUserRegistration: (MastodonRegisterViewModel, Bool) async -> ()

    @Published var backgroundColor: UIColor = Asset.Scene.Onboarding.background.color
    @Published var dateOfBirth = Date.now
    @Published var name = ""
    @Published var username = ""
    @Published var email = ""
    @Published var password = ""
    @Published var passwordConfirmation = ""
    @Published var reason = ""
    
    @Published var usernameErrorPrompt: String? = nil
    @Published var emailErrorPrompt: String? = nil
    @Published var passwordErrorPrompt: String? = nil
    @Published var reasonErrorPrompt: String? = nil
    
    @Published var bottomPaddingHeight: CGFloat = .zero
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<RegisterSection, RegisterItem>?
    let approvalRequired: Bool
    let reasonRequired: Bool
    let minAge: Int?
    let applicationAuthorization: Mastodon.API.OAuth.Authorization
    
    @Published var dateOfBirthValidateState: ValidateState = .empty
    @Published var usernameValidateState: ValidateState = .empty
    @Published var displayNameValidateState: ValidateState = .empty
    @Published var emailValidateState: ValidateState = .empty
    @Published var passwordBaseValidateState: ValidateState = .empty
    @Published var passwordConfirmationValidateState: ValidateState = .empty
    @Published var reasonValidateState: ValidateState = .empty
    
    public var editingField: RegistrationField? {
        didSet {
            if let oldValue {
                validate(oldValue)
            }
        }
    }
        
    @Published var isRegistering = false
    @Published var isAllValid = false
    @Published var error: Error? = nil
    
    let endEditing = PassthroughSubject<Void, Never>()

    init(
        domain: String,
        authenticateInfo: AuthenticationViewModel.AuthenticateInfo,
        instance: RegistrationInstance,
        applicationToken: Mastodon.Entity.Token,
        submitValidatedUserRegistration: @escaping (MastodonRegisterViewModel, Bool) async ->()
    ) {
        self.domain = domain
        self.authenticateInfo = authenticateInfo
        self.instance = instance
        self.applicationToken = applicationToken
        self.approvalRequired = instance.approvalRequired ?? false
        self.reasonRequired = instance.reasonRequired
        self.minAge = instance.minAge
        self.applicationAuthorization = Mastodon.API.OAuth.Authorization(accessToken: applicationToken.accessToken, domain: domain)
        self.submitValidatedUserRegistration = submitValidatedUserRegistration
        
        $dateOfBirth
            .map { [weak self] dob in
                guard let self else { return .invalid }
                switch dateOfBirthValidateState {
                case .empty:
                    return .filling
                case .filling:
                    if self.validate(dateOfBirth: dob) == .valid {
                        return .valid
                    } else {
                        return .filling
                    }
                case .invalid, .valid:
                    return self.validate(dateOfBirth: dob)
                }
            }
            .assign(to: \.dateOfBirthValidateState, on: self)
            .store(in: &disposeBag)
        
        $name
            .map { [weak self] name in
                guard !name.isEmpty else { return .empty }
                guard let self else { return .invalid }
                switch self.displayNameValidateState {
                case .empty:
                    return .filling
                case .filling:
                    if self.validate(displayName: name) == .valid {
                        return .valid
                    } else {
                        return .filling
                    }
                case .invalid, .valid:
                    return self.validate(displayName: name)
                }
            }
            .assign(to: \.displayNameValidateState, on: self)
            .store(in: &disposeBag)
        
        $username
            .removeDuplicates()
            .map { [weak self] username in
                guard !username.isEmpty else { return .empty }
                guard let self else { return .invalid }
                switch self.usernameValidateState {
                case .empty:
                    return .filling
                case .filling:
                    if self.validate(handle: username) == .valid {
                        return .valid
                    } else {
                        return .filling
                    }
                case .invalid, .valid:
                    return self.validate(handle: username)
                }
            }
            .assign(to: \.usernameValidateState, on: self)
            .store(in: &disposeBag)
        
        // check username available
        $username
            .filter { !$0.isEmpty }
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .compactMap { [weak self] text -> AnyPublisher<Result<Mastodon.Response.Content<Mastodon.Entity.Account>, Error>, Never>? in
                guard let self = self else { return nil }
                let query = Mastodon.API.Account.AccountLookupQuery(acct: text)
                return APIService.shared.accountLookup(domain: domain, query: query, authorization: self.applicationAuthorization)
                    .map {
                        response -> Result<Mastodon.Response.Content<Mastodon.Entity.Account>, Error> in
                        Result.success(response)
                    }
                    .catch { error in
                        Just(Result.failure(error))
                    }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    let text = L10n.Scene.Register.Error.Reason.taken(L10n.Scene.Register.Error.Item.username)
                    self.usernameErrorPrompt = text
                    self.usernameValidateState = .invalid
                case .failure:
                    break
                }
            }
            .store(in: &disposeBag)
       
        $usernameValidateState
            .sink { [weak self] validateState in
                if validateState == .valid {
                    self?.usernameErrorPrompt = nil
                }
            }
            .store(in: &disposeBag)

        $email
            .map { [weak self] email in
                guard !email.isEmpty else { return .empty }
                guard let self else { return .invalid }
                switch self.emailValidateState {
                case .empty:
                    return .filling
                case .filling:
                    if self.validate(email: email) == .valid {
                        return .valid
                    } else {
                        return .filling
                    }
                case .invalid, .valid:
                    return self.validate(email: email)
                }
            }
            .assign(to: \.emailValidateState, on: self)
            .store(in: &disposeBag)
        
        $password
            .map { [weak self] password in
                guard !password.isEmpty else { return .empty }
                guard let self else { return .invalid }
                switch self.passwordBaseValidateState {
                case .empty:
                    return .filling
                case .filling:
                    if self.validate(password: password) == .valid {
                        return .valid
                    } else {
                        return .filling
                    }
                case .invalid, .valid:
                    return self.validate(password: password)
                }
            }
            .assign(to: \.passwordBaseValidateState, on: self)
            .store(in: &disposeBag)
        
        Publishers.CombineLatest($password, $passwordConfirmation)
            .map { [weak self] password, confirmation in
                guard !password.isEmpty && !confirmation.isEmpty else { return .empty }
                guard let self else { return .invalid }
                switch self.passwordConfirmationValidateState {
                case .empty, .filling:
                    if self.validate(password: password, confirmation: confirmation) == .valid {
                        return .valid
                    } else {
                        return .filling
                    }
                case .invalid, .valid:
                    return self.validate(password: password, confirmation: confirmation)
                }
            }
            .assign(to: \.passwordConfirmationValidateState, on: self)
            .store(in: &disposeBag)
        
        if approvalRequired {
            $reason
                .map { joinReason in
                    guard !joinReason.isEmpty else { return .empty }
                    switch self.reasonValidateState {
                    case .empty:
                        return .filling
                    case .filling:
                        if self.validate(reason: joinReason) == .valid {
                            return .valid
                        } else {
                            return .filling
                        }
                    case .invalid, .valid:
                        return self.validate(reason: joinReason)
                    }
                }
                .assign(to: \.reasonValidateState, on: self)
                .store(in: &disposeBag)
        }
        
        $error
            .sink { [weak self] error in
                guard let self = self else { return }
                let error = error as? Mastodon.API.Error
                let mastodonError = error?.mastodonError
                if case let .generic(genericMastodonError) = mastodonError,
                   let details = genericMastodonError.details
                {
                    self.usernameErrorPrompt = details.usernameErrorDescriptions.first
                    details.usernameErrorDescriptions.first.flatMap { _ in self.usernameValidateState = .invalid }
                    self.emailErrorPrompt = details.emailErrorDescriptions.first
                    details.emailErrorDescriptions.first.flatMap { _ in self.emailValidateState = .invalid }
                    self.passwordErrorPrompt = details.passwordErrorDescriptions.first
                    details.passwordErrorDescriptions.first.flatMap { _ in self.passwordBaseValidateState = .invalid }
                    self.reasonErrorPrompt = details.reasonErrorDescriptions.first
                    details.reasonErrorDescriptions.first.flatMap { _ in self.reasonValidateState = .invalid }
                } else {
                    self.usernameErrorPrompt = nil
                    self.emailErrorPrompt = nil
                    self.passwordErrorPrompt = nil
                    self.reasonErrorPrompt = nil
                }
            }
            .store(in: &disposeBag)
        
        let publisherOne = Publishers.CombineLatest4(
            $usernameValidateState,
            $displayNameValidateState,
            $emailValidateState,
            $passwordBaseValidateState
        )
        .map {
            $0.0 == .valid &&
            $0.1 == .valid &&
            $0.2 == .valid &&
            $0.3 == .valid
        }
        
        let publisherTwo = Publishers.CombineLatest3(
            $reasonValidateState,
            $dateOfBirthValidateState,
            $passwordConfirmationValidateState
        )
            .map { [weak self] reasonValidateState, dobValidateState, passwordConfirmationValidateState -> Bool in
                guard let self else { return false }
                let reasonOK = !self.reasonRequired || reasonValidateState == .valid
                let dobOK = (self.minAge == nil) || dobValidateState == .valid
                let passwordConfirmationCorrect = passwordConfirmationValidateState == .valid
                return reasonOK && dobOK && passwordConfirmationCorrect
        }
        
        Publishers.CombineLatest(
            publisherOne,
            publisherTwo
        )
        .map { $0 && $1 }
        .assign(to: \.isAllValid, on: self)
        .store(in: &disposeBag)
        
        Publishers.CombineLatest4(
            publisherOne,
            $reasonValidateState,
            $passwordConfirmationValidateState,
            $dateOfBirthValidateState
        )
        .sink { [weak self] publisherOne, reasonValidState, passwordConfirmValidState, dobValidState in
            if publisherOne == false { return }
            if reasonValidState == .valid && passwordConfirmValidState == .valid && dobValidState != .valid {
                self?.dateOfBirthValidateState = .invalid // this will highlight the DOB field if everything else has been filled in
            }
        }
        .store(in: &disposeBag)
    }
}

extension MastodonRegisterViewModel {
    enum ValidateState: Hashable {
        case empty
        case filling
        case invalid
        case valid
    }
    
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    func validate(_ field: RegistrationField) {
        let state = validationState(forCurrentContentsOf: field)
        switch field {
        case .displayName:
            displayNameValidateState = state
        case .handle:
            usernameValidateState = state
        case .email:
            emailValidateState = state
        case .password:
            passwordBaseValidateState = state
        case .confirmPassword:
            passwordConfirmationValidateState = state
        case .dateOfBirth:
            dateOfBirthValidateState = state
        case .proposedApprovalReason:
            reasonValidateState = state
        }
    }
    
    private func validate(dateOfBirth: Date) -> ValidateState {
        guard let minAge else { return .valid }
        let years = Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date.now).year ?? 0
        print("looks to be \(years) old")
        return years < minAge ? .invalid : .valid
    }
    
    private func validate(displayName: String) -> ValidateState {
        return displayName.isEmpty ? .empty : .valid
    }
    
    private func validate(handle: String) -> ValidateState {
        var isValid = true
        // regex opt-out way to check validation
        // allowed:
        // a-z (isASCII && isLetter)
        // A-Z (isASCII && isLetter)
        // 0-9 (isASCII && isNumber)
        // _ ("_")
        for char in handle {
            guard char.isASCII, char.isLetter || char.isNumber || char == "_" else {
                isValid = false
                break
            }
        }
        return isValid ? .valid : .invalid
    }
    
    private func validate(email: String) -> ValidateState {
        return MastodonRegisterViewModel.isValidEmail(email) ? .valid : .invalid
    }
   
    private func validate(password: String) -> ValidateState {
        return password.count >= 8 ? .valid : .invalid
    }
    
    private func validate(password: String, confirmation: String) -> ValidateState {
        return password == passwordConfirmation ? .valid : .invalid
    }
    
    private func validate(reason: String) -> ValidateState {
        return reason.isEmpty ? .invalid : .valid
    }
    
    private func validationState(forCurrentContentsOf field: RegistrationField) -> ValidateState {
        switch field {
        case .displayName:
            return validate(displayName: name)
        case .handle:
            return validate(handle: username)
        case .email:
            return validate(email: email)
        case .password:
            return validate(password: password)
        case .confirmPassword:
            return validate(password: password, confirmation: passwordConfirmation)
        case .dateOfBirth:
            return validate(dateOfBirth: dateOfBirth)
        case .proposedApprovalReason:
            return validate(reason: reason)
        }
    }
}

extension MastodonRegisterViewModel {
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
        let font = UIFontMetrics(forTextStyle: .caption1).scaledFont(for: .systemFont(ofSize: 13, weight: .regular), maximumPointSize: 18)
        let attributeString = NSMutableAttributedString()

        let image = MastodonRegisterViewModel.checkmarkImage(font: font)
        attributeString.append(attributedStringImage(with: image, tintColor: validateState == .valid ? Asset.Colors.Label.primary.color : .clear))
        attributeString.append(NSAttributedString(string: " "))
        let eightCharactersDescription = NSAttributedString(string: L10n.Scene.Register.Input.Password.hint, attributes: [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: Asset.Colors.Label.primary.color])
        attributeString.append(eightCharactersDescription)
        
        return attributeString
    }
    
    static func errorPromptAttributedString(for prompt: String) -> NSAttributedString {
        let font = UIFontMetrics(forTextStyle: .caption1).scaledFont(for: .systemFont(ofSize: 13, weight: .regular), maximumPointSize: 18)
        let attributeString = NSMutableAttributedString()

        let image = MastodonRegisterViewModel.xmarkImage(font: font)
        attributeString.append(attributedStringImage(with: image, tintColor: Asset.Colors.danger.color))
        attributeString.append(NSAttributedString(string: " "))
        
        let promptAttributedString = NSAttributedString(string: prompt, attributes: [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: Asset.Colors.danger.color])
        attributeString.append(promptAttributedString)
        
        return attributeString
    }
}

extension MastodonRegisterViewModel {
    var accessibilityLabelUsernameField: String {
        let username = username.isEmpty ? L10n.Scene.Register.Input.Username.placeholder : username
        return "@\(username)@\(domain)"
    }
}

protocol RegistrationInstance {
    var approvalRequired: Bool? { get }
    var reasonRequired: Bool { get }
    var minAge: Int? { get }
    var isBeyondVersion1: Bool { get }
    var isOpenToNewRegistrations: Bool? { get }
    var rules: [Mastodon.Entity.Instance.Rule]? { get }
    var termsOfService: URL? { get }
    var privacyPolicy: URL? { get }
}

extension Mastodon.Entity.Instance: RegistrationInstance {
    var minAge: Int? { return nil }
    var isBeyondVersion1: Bool {
        return version?.majorServerVersion(greaterThanOrEquals: 4) ?? false
    }
    var isOpenToNewRegistrations: Bool? { return registrations }
    var reasonRequired: Bool {
        return approvalRequired ?? false
    }
    
    var termsOfService: URL? {
        return nil
    }
    
    var privacyPolicy: URL? {
        return URL(string: "https://\(uri)/privacy-policy")
    }
}

extension Mastodon.Entity.V2.Instance: RegistrationInstance {
    var minAge: Int? { return registrations?.minAge }
    var isBeyondVersion1: Bool { return true }
    var isOpenToNewRegistrations: Bool? { return registrations?.enabled }
    var approvalRequired: Bool? { return registrations?.approvalRequired }
    var reasonRequired: Bool {
        return registrations?.reasonRequired ?? approvalRequired ?? false
    }
    
    var termsOfService: URL? {
        if let string = configuration?.urls?.termsOfService {
            return URL(string: string)
        } else {
            return nil
        }
    }
    
    var privacyPolicy: URL? {
        if let string = configuration?.urls?.privacyPolicy {
            return URL(string: string)
        } else {
            guard let domain else { return nil }
            return URL(string: "https://\(domain)/privacy-policy")
        }
    }
}
