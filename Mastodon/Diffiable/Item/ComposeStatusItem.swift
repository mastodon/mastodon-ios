//
//  ComposeStatusItem.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

import Foundation
import Combine
import CoreData

/// Note: update Equatable when change case
enum ComposeStatusItem {
    case replyTo(statusObjectID: NSManagedObjectID)
    case input(replyToStatusObjectID: NSManagedObjectID?, attribute: ComposeStatusAttribute)
    case attachment(attachmentService: MastodonAttachmentService)
    case pollOption(attribute: ComposePollOptionAttribute)
    case pollOptionAppendEntry
    case pollExpiresOption(attribute: ComposePollExpiresOptionAttribute)
}

extension ComposeStatusItem: Equatable { }

extension ComposeStatusItem: Hashable { }

extension ComposeStatusItem {
    final class ComposeStatusAttribute: Equatable, Hashable {
        private let id = UUID()
                
        let avatarURL = CurrentValueSubject<URL?, Never>(nil)
        let displayName = CurrentValueSubject<String?, Never>(nil)
        let username = CurrentValueSubject<String?, Never>(nil)
        let composeContent = CurrentValueSubject<String?, Never>(nil)
        
        static func == (lhs: ComposeStatusAttribute, rhs: ComposeStatusAttribute) -> Bool {
            return lhs.avatarURL.value == rhs.avatarURL.value &&
                lhs.displayName.value == rhs.displayName.value &&
                lhs.username.value  == rhs.username.value &&
                lhs.composeContent.value == rhs.composeContent.value
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}

protocol ComposePollAttributeDelegate: class {
    func composePollAttribute(_ attribute: ComposeStatusItem.ComposePollOptionAttribute, pollOptionDidChange: String?)
}

extension ComposeStatusItem {
    final class ComposePollOptionAttribute: Equatable, Hashable {
        private let id = UUID()
        
        var disposeBag = Set<AnyCancellable>()
        weak var delegate: ComposePollAttributeDelegate?

        let option = CurrentValueSubject<String, Never>("")
        
        init() {
            option
                .sink { [weak self] option in
                    guard let self = self else { return }
                    self.delegate?.composePollAttribute(self, pollOptionDidChange: option)
                }
                .store(in: &disposeBag)
        }
        
        deinit {
            disposeBag.removeAll()
        }
        
        static func == (lhs: ComposePollOptionAttribute, rhs: ComposePollOptionAttribute) -> Bool {
            return lhs.id == rhs.id &&
                lhs.option.value == rhs.option.value
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}

extension ComposeStatusItem {
    final class ComposePollExpiresOptionAttribute: Equatable, Hashable {
        private let id = UUID()

        let expiresOption = CurrentValueSubject<ExpiresOption, Never>(.thirtyMinutes)
        
        
        static func == (lhs: ComposePollExpiresOptionAttribute, rhs: ComposePollExpiresOptionAttribute) -> Bool {
            return lhs.id == rhs.id &&
                lhs.expiresOption.value == rhs.expiresOption.value
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        enum ExpiresOption: Equatable, Hashable, CaseIterable {
            case thirtyMinutes
            case oneHour
            case sixHours
            case oneDay
            case threeDays
            case sevenDays
            
            var title: String {
                switch self {
                case .thirtyMinutes: return L10n.Scene.Compose.Poll.thirtyMinutes
                case .oneHour: return L10n.Scene.Compose.Poll.oneHour
                case .sixHours: return L10n.Scene.Compose.Poll.sixHours
                case .oneDay: return L10n.Scene.Compose.Poll.oneDay
                case .threeDays: return L10n.Scene.Compose.Poll.threeDays
                case .sevenDays: return L10n.Scene.Compose.Poll.sevenDays
                }
            }
            
            var seconds: Int {
                switch self {
                case .thirtyMinutes: return 60 * 30
                case .oneHour: return 60 * 60 * 1
                case .sixHours: return 60 * 60 * 6
                case .oneDay: return 60 * 60 * 24
                case .threeDays: return 60 * 60 * 24 * 3
                case .sevenDays: return 60 * 60 * 24 * 7
                }
            }
        }
    }
}
