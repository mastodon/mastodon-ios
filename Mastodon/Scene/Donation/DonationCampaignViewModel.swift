// Copyright © 2024 Mastodon gGmbH. All rights reserved.
import Foundation
import MastodonSDK

struct SuggestedDonation {
    let unitAmount: Int
    let plainString: String
    let currencyFormattedString: String

    init(pennies: Int, currency: String) {
        unitAmount = pennies / 100
        plainString = unitAmount.formatted(
            .number.precision(.fractionLength(0)))
        currencyFormattedString = unitAmount.formatted(
            .currency(code: currency).precision(.fractionLength(0)))
    }
}

typealias DonationFrequency = Mastodon.Entity.DonationCampaign.DonationFrequency
typealias DonationSource = Mastodon.Entity.DonationCampaign.DonationSource

protocol DonationCampaignViewModel {
    var id: String { get }
    func paymentURL(
        currency: String, source: DonationSource,
        frequency: Mastodon.Entity.DonationCampaign.DonationFrequency,
        amount: Int
    ) -> URL?
    var paymentBaseURL: URL? { get }
    var callbackBaseURL: URL? { get }
    var source: DonationSource { get }
    var donationMessage: String { get }
    var defaultFrequency: DonationFrequency { get }
    var defaultCurrency: String { get }
    var defaultAmount: Int { get }
    var availableFrequencies: [DonationFrequency] { get }
    func suggestedDonations(frequency: DonationFrequency, currency: String, sorted: Bool)
        -> [SuggestedDonation]?
    func availableCurrencies(frequency: DonationFrequency) -> [String]?
    var donationSuccessPost: String { get }
}

extension DonationCampaignViewModel {

    public func paymentURL(
        currency: String, source: DonationSource,
        frequency: Mastodon.Entity.DonationCampaign.DonationFrequency,
        amount: Int
    ) -> URL? {
        guard let paymentBaseURL = paymentBaseURL,
            let callbackBaseURL = callbackBaseURL
        else { return nil }
        let successURL = callbackBaseURL.appendingPathComponent(
            "success", isDirectory: false)
        let cancelURL = callbackBaseURL.appendingPathComponent(
            "cancel", isDirectory: false)
        let failureURL = callbackBaseURL.appendingPathComponent(
            "failure", isDirectory: false)

        let locale = Locale.current.identifier
        var queryItems = [
            URLQueryItem(name: "platform", value: "ios"),
            URLQueryItem(name: "locale", value: locale),
            URLQueryItem(name: "currency", value: currency),
            URLQueryItem(name: "source", value: source.queryValue),
            URLQueryItem(name: "frequency", value: frequency.queryValue),
            URLQueryItem(name: "amount", value: "\(amount)"),
            URLQueryItem(
                name: "success_callback_url", value: successURL.absoluteString),
            /*must be one of
             https://sponsor.joinmastodon.org/donate/success
             https://sponsor.staging.joinmastodon.org/donate/success
             */
            URLQueryItem(
                name: "cancel_callback_url", value: cancelURL.absoluteString),
            /*must be one of
             https://sponsor.joinmastodon.org/donate/cancel
             https://sponsor.staging.joinmastodon.org/donate/cancel
             */
            URLQueryItem(
                name: "failure_callback_url", value: failureURL.absoluteString),
            /*must be one of
             https://sponsor.joinmastodon.org/donate/failure
             https://sponsor.staging.joinmastodon.org/donate/failure
             */
        ]
        switch source {
        case .campaign(let id):
            queryItems.append(URLQueryItem(name: "campaign_id", value: id))
        default:
            break
        }
        #if DEBUG
            queryItems.append(
                URLQueryItem(name: "environment", value: "staging"))
        #endif
        var components = URLComponents(string: paymentBaseURL.absoluteString)
        components?.queryItems = queryItems
        return components?.url
    }
}

extension Mastodon.Entity.DonationCampaign: DonationCampaignViewModel {

    private typealias MulticurrencySuggestedDonationAmounts = [String: [Int]]

    var paymentBaseURL: URL? {
        return URL(string: self.donationUrl)
    }
    var callbackBaseURL: URL? {
        return URL(string: self.donationUrl)?.deletingLastPathComponent()
    }
    var source: DonationSource {
        return .campaign(id: id)
    }
    var defaultFrequency: DonationFrequency {
        return availableFrequencies.last ?? .monthly
    }
    var defaultAmount: Int {
        let least =
            suggestedDonations(
                frequency: defaultFrequency, currency: defaultCurrency, sorted: false)?.first?
            .unitAmount ?? 1
        return least
    }

    var availableFrequencies: [DonationFrequency] {
        return [.oneTime, .monthly, .yearly].filter {
            suggestedAmounts($0)?.isNotEmpty ?? false
        }
    }

    private func suggestedAmounts(_ frequency: DonationFrequency)
        -> MulticurrencySuggestedDonationAmounts?
    {
        switch frequency {
        case .oneTime:
            return amounts.oneTime
        case .monthly:
            return amounts.monthly
        case .yearly:
            return amounts.yearly
        }
    }

    func suggestedDonations(frequency: DonationFrequency, currency: String, sorted: Bool)
        -> [SuggestedDonation]?
    {
        let multiCurrencySuggestions: MulticurrencySuggestedDonationAmounts?

        switch frequency {
        case .monthly:
            multiCurrencySuggestions = amounts.monthly
        case .oneTime:
            multiCurrencySuggestions = amounts.oneTime
        case .yearly:
            multiCurrencySuggestions = amounts.yearly
        }
        guard let rawAmounts = multiCurrencySuggestions?[currency] else {
            return nil
        }
        
        let inOrder = sorted ? rawAmounts.sorted().reversed() : rawAmounts
        return inOrder.map {
            SuggestedDonation(pennies: $0, currency: currency)
        }
    }

    func availableCurrencies(frequency: DonationFrequency) -> [String]? {
        let suggestions = suggestedAmounts(frequency)
        return suggestions?.keys.map { $0 } as? [String]
    }
}
