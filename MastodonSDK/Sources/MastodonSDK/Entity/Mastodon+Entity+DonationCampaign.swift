// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation

public typealias DonationAmount = [String: [Int]]

extension Mastodon.Entity {
    public struct DonationCampaign: Codable {
        public struct Amounts: Codable {
            public let oneTime: DonationAmount?
            public let monthly: DonationAmount
            public let yearly: DonationAmount?
            
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
        
        enum CodingKeys: String, CodingKey {
            case id
            case bannerMessage = "banner_message"
            case bannerButtonText = "banner_button_text"
            case donationMessage = "notification_type"
            case donationButtonText = "preferred_locale"
            case defaultCurrency = "default_currency"
            case donationUrl = "donation_url"
            case donationSuccessPost = "donation_success_post"
            case amounts
        }
    }
}
