// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import Foundation

public var isDebugOrTestflightOrSimulator: Bool {
    #if DEBUG
        return true
    #else
        guard let path = Bundle.main.appStoreReceiptURL?.path else {
            return false
        }
        return path.contains("CoreSimulator") || path.contains("sandboxReceipt")
    #endif
}

extension Mastodon.API {
    public static var isTestingDonations: Bool {
        return isDebugOrTestflightOrSimulator && useStaging
    }
    public static func toggleTestingDonations() {
        useStaging = !useStaging
    }
    private static let stagingKey = "use_staging_for_donations_testing"
    private static var useStaging: Bool {
        get {
            if UserDefaults.standard.value(forKey: stagingKey) != nil {
                return UserDefaults.standard.bool(forKey: stagingKey)
            } else {
                return true
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: stagingKey)
        }
    }

    public static var donationsEndpoint: URL {
        URL(
            string: "https://api.joinmastodon.org/v1/donations/campaigns/active"
        )!
    }

    public struct GetDonationCampaignsQuery: GetQuery {
        let seed: Int
        let source: String?

        public init(seed: Int, source: String?) {
            self.seed = seed
            self.source = source
        }

        var queryItems: [URLQueryItem]? {
            let locale = Locale.current.identifier
            var queryItems = [
                URLQueryItem(name: "platform", value: "ios"),
                URLQueryItem(name: "locale", value: locale),
                URLQueryItem(name: "seed", value: "\(seed)"),
            ]
            if isTestingDonations {
                queryItems.append(
                    URLQueryItem(name: "environment", value: "staging"))
            }

            if let source, !source.isEmpty {
                queryItems.append(URLQueryItem(name: "source", value: source))
            }

            return queryItems
        }
    }

    public static func getDonationCampaign(
        session: URLSession,
        query: GetDonationCampaignsQuery
    ) async throws
        -> Mastodon.Response.Content<Mastodon.Entity.DonationCampaign>
    {
        let url = donationsEndpoint

        let request = Mastodon.API.get(url: url, query: query)
        let (data, response) = try await session.data(for: request)

        let value = try Mastodon.API.decode(
            type: Mastodon.Entity.DonationCampaign.self, from: data,
            response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
}
