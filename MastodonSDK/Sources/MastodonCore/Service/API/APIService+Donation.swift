import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService {

    public func getDonationCampaign(
        seed: Int,
        source: String?
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.DonationCampaign> {
        return try await Mastodon.API.getDonationCampaign(session: session, query: .init(seed: seed, source: source))
    }

}
