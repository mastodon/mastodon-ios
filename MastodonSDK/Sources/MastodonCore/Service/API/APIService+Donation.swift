import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService {

    public func getDonationCampaigns(
        seed: Int,
        source: String?
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.DonationCampaign]> {
        return try await Mastodon.API.getDonationCampaigns(session: session, seed: seed, source: source)
    }

}
