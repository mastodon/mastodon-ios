//
//  ComposeStatusPollItem.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-6-29.
//

import Foundation
import Combine
import MastodonAsset
import MastodonLocalization

enum ComposeStatusPollItem {
    case pollOption(attribute: PollOptionAttribute)
    case pollOptionAppendEntry
    case pollExpiresOption(attribute: PollExpiresOptionAttribute)
}

extension ComposeStatusPollItem: Hashable { }

extension ComposeStatusPollItem {

    final class PollOptionAttribute: Equatable, Hashable {
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

        static func == (lhs: PollOptionAttribute, rhs: PollOptionAttribute) -> Bool {
            return lhs.id == rhs.id &&
                lhs.option.value == rhs.option.value
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

}

protocol ComposePollAttributeDelegate: AnyObject {
    func composePollAttribute(_ attribute: ComposeStatusPollItem.PollOptionAttribute, pollOptionDidChange: String?)
}

extension ComposeStatusPollItem {
    final class PollExpiresOptionAttribute: Equatable, Hashable {
        private let id = UUID()

        let expiresOption = CurrentValueSubject<ExpiresOption, Never>(.oneDay)

        static func == (lhs: PollExpiresOptionAttribute, rhs: PollExpiresOptionAttribute) -> Bool {
            return lhs.id == rhs.id &&
                lhs.expiresOption.value == rhs.expiresOption.value
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        enum ExpiresOption: String, Equatable, Hashable, CaseIterable {
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
