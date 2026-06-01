import Combine
import Foundation
import MastodonSDK

extension APIService {

    public func getDonationCampaign(
        seed: Int,
        source: Mastodon.Entity.DonationCampaign.DonationCampaignRequestSource
    ) async throws
        -> Mastodon.Response.Content<Mastodon.Entity.DonationCampaign>
    {
        let campaign = try await Mastodon.API.getDonationCampaign(
            session: session, query: .init(seed: seed, source: source.queryValue))
        guard campaign.value.isValid else {
            throw Mastodon.Entity.DonationError.campaignInvalid
        }
        return campaign
    }

}
