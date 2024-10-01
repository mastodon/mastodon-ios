// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import Foundation
import SwiftUI
import UIKit
import MastodonSDK
import MastodonLocalization

class DonationViewController: UIHostingController<DonationView> {
    init(campaign: Mastodon.Entity.DonationCampaign) {
        super.init(
            rootView: DonationView(
                campaign: campaign,
                interval: campaign.amounts.monthly,
                currency: campaign.amounts.monthly.first!.key,
                amount: {
                    if let amount = campaign.amounts.monthly.first?.value.last {
                        return String(amount.asReadableAmount)
                    }
                    return ""
                }()
            )
        )
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct DonationView: View {
    let campaign: Mastodon.Entity.DonationCampaign
    
    @State var interval: DonationAmount
    @State var currency: String
    @State var amount: String

    var body: some View {
        VStack {
            Text(campaign.donationMessage)
                .padding(.bottom, 16)
            
            Picker(selection: $interval) {
                if let oneTime = campaign.amounts.oneTime {
                    Text(L10n.Scene.Donation.Picker.onceTitle)
                        .tag(oneTime)
                }
                Text(L10n.Scene.Donation.Picker.monthlyTitle)
                    .tag(campaign.amounts.monthly)
                if let yearly = campaign.amounts.yearly {
                    Text(L10n.Scene.Donation.Picker.yearlyTitle)
                        .tag(yearly)
                }
            } label: {}
                .pickerStyle(.segmented)
                .padding(.bottom, 16)
            
            HStack {
                Picker(selection: $currency) {
                    ForEach(interval.map(\.key), id: \.self) {
                        Text($0)
                            .tag($0)
                    }
                } label: {
                    Text(currency)
                }
                .background(Color.gray.opacity(0.25))
                .clipShape(.rect(topLeadingRadius: 4, bottomLeadingRadius: 4))
                
                TextField(text: $amount) {}
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .padding(.trailing, 8)

            }
            .background(RoundedRectangle(cornerRadius: 4.0).stroke(Color.gray.opacity(0.25), lineWidth: 1))
            .padding(.bottom, 16)
            
            HStack {
                if let predefinedAmounts = interval[currency] {
                    ForEach(predefinedAmounts, id: \.self) { amount in
                        Button(String(amount.asReadableAmount)) {
                            
                        }
                        .frame(minWidth: 100, maxWidth: .infinity)
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding(.bottom, 16)

        }
        .padding(.horizontal, 16)
    }
}

fileprivate extension Int {
    var asReadableAmount: Int {
        self / 100
        }
    }
}
