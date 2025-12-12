// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation

private let maxCampaignsToRemember = 25
private let dismissedCampaignsKey = "dismissed_donation_campaigns"
private let contributedCampaignsKey = "contributed_donation_campaigns"

extension Mastodon.Entity {

    public enum DonationError: Swift.Error {
        case campaignInvalid
    }

    public struct DonationCampaign: Codable {
        
        public enum DonationCampaignRequestSource {
            case banner
            case menu
            
            public var queryValue: String? {
                switch self {
                case .banner:
                    return nil
                case .menu:
                    return "menu"
                }
            }
        }
        
        public enum DonationSource {
            case campaign(id: String)
            case menu

            public var queryValue: String {
                switch self {
                case .campaign:
                    return "campaign"
                case .menu:
                    return "menu"
                }
            }
        }
        private static let minDaysAccountAgeForDonations = 28
        static public func isEligibleForDonationsBanner(
            domain: String, accountCreationDate: Date
        ) -> Bool {
            guard
                let minDateForDonations = Calendar.current.date(
                    byAdding: .day, value: -minDaysAccountAgeForDonations,
                    to: Date())
            else {
                return false
            }
            let becauseOnOfficialServer =
                ["mastodon.social", "mastodon.online"].contains(domain)
                && accountCreationDate < minDateForDonations
            let becauseTesting = domain == "staging.mastodon.social"
            return becauseOnOfficialServer || becauseTesting
        }

        static public func isEligibleForDonationsSettingsSection(domain: String)
            -> Bool
        {
            let becauseOnOfficialServer = [
                "mastodon.social", "mastodon.online",
            ].contains(domain)
            let becauseTesting = domain == "staging.mastodon.social"
            return becauseOnOfficialServer || becauseTesting
        }

        static public func donationSeed(username: String, domain: String) -> Int
        {
            return abs("@\(username)@\(domain)".hashValue) % 100
        }

        public enum DonationFrequency {
            case oneTime, monthly, yearly

            public var queryValue: String {
                switch self {
                case .monthly:
                    return "monthly"
                case .oneTime:
                    return "one_time"
                case .yearly:
                    return "yearly"
                }
            }
        }

        public struct Amounts: Codable {
            public let oneTime: [String: [Int]]?
            public let monthly: [String: [Int]]?
            public let yearly: [String: [Int]]?

            enum CodingKeys: String, CodingKey {
                case oneTime = "one_time"
                case monthly
                case yearly
            }
        }

        public let id: String
        public let bannerMessage: String
        public let bannerButtonText: String
        public let donationMessage: String
        public let donationButtonText: String
        public let defaultCurrency: String
        public let donationUrl: String
        public let donationSuccessPost: String
        public let amounts: Amounts

        public var isValid: Bool {
            for options in [amounts.oneTime, amounts.monthly, amounts.yearly] {
                if let options, !options.isEmpty {
                    return true
                }
            }
            return false
        }

        enum CodingKeys: String, CodingKey {
            case id
            case bannerMessage = "banner_message"
            case bannerButtonText = "banner_button_text"
            case donationMessage = "donation_message"
            case donationButtonText = "donation_button_text"
            case defaultCurrency = "default_currency"
            case donationUrl = "donation_url"
            case donationSuccessPost = "donation_success_post"
            case amounts
        }
        
        static public func hasPreviouslyDismissed(_ campaign: String) -> Bool {
            let ids = UserDefaults.standard.array(forKey: dismissedCampaignsKey) as? [String]
            return ids?.contains(campaign) ?? false
        }
        static public func hasPreviouslyContributed(_ campaign: String) -> Bool {
            let ids = UserDefaults.standard.array(forKey: contributedCampaignsKey) as? [String]
            return ids?.contains(campaign) ?? false
        }
        static public func didDismiss(_ campaign: String) {
            var ids = UserDefaults.standard.array(forKey: dismissedCampaignsKey) as? [String] ?? []
            if ids.count == maxCampaignsToRemember {
                ids.removeFirst()
            }
            ids.append(campaign)
            UserDefaults.standard.setValue(ids, forKey: dismissedCampaignsKey)
        }
        static public func didContribute(_ campaign: String) {
            var ids = UserDefaults.standard.array(forKey: contributedCampaignsKey) as? [String] ?? []
            if ids.count == maxCampaignsToRemember {
                ids.removeFirst()
            }
            ids.append(campaign)
            UserDefaults.standard.setValue(ids, forKey: contributedCampaignsKey)
        }
        static public func forgetPreviousCampaigns() {
            UserDefaults.standard.removeObject(forKey: contributedCampaignsKey)
            UserDefaults.standard.removeObject(forKey: dismissedCampaignsKey)
        }
    }
}
