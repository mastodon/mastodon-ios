// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import Foundation

extension HomeTimelineViewModel {
    enum DonationSource: String {
        case menu = "menu"
        case undefined = ""
    }
    
    func askForDonationIfPossible(source: DonationSource) {
        let userAuthentication = authContext.mastodonAuthenticationBox.authentication
        guard userAuthentication.isEligibleForDonations else { return }
        
        Task { @MainActor [weak self] in
            guard let self else { return }
            let seed = userAuthentication.donationSeed
            
            do {
                let campaign = try await self.context.apiService.getDonationCampaign(seed: seed, source: source.rawValue)
                
                print("camp", campaign)
            } catch {
                // no-op
            }
        }
    }
}
