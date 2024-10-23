import Combine
import CoreData
import CoreDataStack
import Foundation
import MastodonSDK

extension APIService {

    public func getDonationCampaign(
        seed: Int,
        source: String?
    ) async throws
        -> Mastodon.Response.Content<Mastodon.Entity.DonationCampaign>
    {
        let campaign = try await Mastodon.API.getDonationCampaign(
            session: session, query: .init(seed: seed, source: source))
        guard campaign.value.isValid else {
            throw Mastodon.Entity.DonationError.campaignInvalid
        }
        return campaign
    }

}
