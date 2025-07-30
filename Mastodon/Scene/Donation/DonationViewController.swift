// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonAsset
import MastodonLocalization
import MastodonSDK
import SwiftUI
import UIKit

class DonationViewController: UIHostingController<DonationView> {

    init(
        campaign: DonationCampaignViewModel,
        completion: @escaping (URL?) -> Void
    ) {
        super.init(
            rootView: DonationView(
                campaign, completion: completion))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .done, primaryAction: UIAction(handler: { _ in
            completion(nil)
        }))
        self.navigationItem.title = L10n.Scene.Settings.Donation.title
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension DonationFrequency {
    var pickerLabel: String {
        switch self {
        case .monthly:
            return L10n.Scene.Donation.Picker.monthlyTitle
        case .yearly:
            return L10n.Scene.Donation.Picker.yearlyTitle
        case .oneTime:
            return L10n.Scene.Donation.Picker.onceTitle
        }
    }
}

struct DonationView: View {
    let campaign: DonationCampaignViewModel
    let completion: (URL?) -> Void

    @State private var selectedFrequency: DonationFrequency
    @State private var selectedCurrency: String
    @State private var selectedAmount: Int

    var urlForCurrentSelections: URL? {
        campaign.paymentURL(
            currency: selectedCurrency, source: campaign.source,
            frequency: selectedFrequency, amount: selectedAmount * 100)  // amount needs to be sent in pennies
    }

    init(
        _ campaign: DonationCampaignViewModel,
        completion: @escaping (URL?) -> Void
    ) {
        self.completion = completion
        self.campaign = campaign
        _selectedFrequency = State(initialValue: campaign.defaultFrequency)
        _selectedCurrency = State(initialValue: campaign.defaultCurrency)
        _selectedAmount = State(initialValue: campaign.defaultAmount)
    }

    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 25) {
                topMessage
                frequencyPicker
                amountEntry
                donationButton
            }
            .frame(maxWidth: 328)
            Spacer()
        }
        .padding(.top)
    }

    @ViewBuilder var topMessage: some View {
        GeometryReader { geom in
            Text(campaign.donationMessage)
                .frame(height: geom.size.height)
                .allowsTightening(true)
                .lineLimit(3)
                .scaledToFit()
                .minimumScaleFactor(0.7)
        }
    }

    @ViewBuilder var frequencyPicker: some View {
        Picker(selection: $selectedFrequency) {
            // TODO: if there is only one available frequency, display a message instead of a single-segment picker
            ForEach(
                [DonationFrequency.oneTime, .monthly, .yearly].filter {
                    campaign.availableFrequencies.contains($0)
                }, id: \.self
            ) {
                Text($0.pickerLabel)
                    .tag($0)
            }
        } label: {
        }
        .pickerStyle(.segmented)
        //            .onAppear {
        //                UISegmentedControl.appearance().selectedSegmentTintColor = Asset.Colors.Secondary.container.color
        //            }
    }

    @ViewBuilder var amountEntry: some View {
        VStack {
            HStack {
                Picker(selection: $selectedCurrency) {
                    ForEach(
                        campaign.availableCurrencies(
                            frequency: selectedFrequency) ?? [], id: \.self
                    ) {
                        Text($0)
                            .tag($0)
                    }
                } label: {
                    Text(selectedCurrency)
                }
                .frame(height: 52)
                .background(Color.gray.opacity(0.25))
                .clipShape(.rect(topLeadingRadius: 4, bottomLeadingRadius: 4))

                TextField(
                    value: $selectedAmount,
                    format: .currency(code: selectedCurrency)
                ) {}
                    .font(.title3)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .padding(.trailing, 8)

            }
            .background(
                RoundedRectangle(cornerRadius: 4.0).stroke(
                    Color.gray.opacity(0.25), lineWidth: 1))

            HStack {
                if let predefinedAmounts = campaign.suggestedDonations(
                    frequency: selectedFrequency, currency: selectedCurrency, sorted: true)
                {
                    ForEach(predefinedAmounts, id: \.unitAmount) { amount in
                        Button(action: {
                            self.selectedAmount = amount.unitAmount
                        }) {
                            Text(amount.currencyFormattedString)
                                .lineLimit(1)
                                .minimumScaleFactor(0.25)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(minWidth: 45)
                        }
                        .buttonStyle(
                            DonationButtonStyle(
                                type: .amount,
                                filled: self.selectedAmount == amount.unitAmount
                            ))
                        if amount.unitAmount
                            != predefinedAmounts.last!.unitAmount
                        {
                            Spacer()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder var donationButton: some View {
        Button(action: {
            if let urlForCurrentSelections = urlForCurrentSelections {
                completion(urlForCurrentSelections)
            }
        }) {
            HStack {
                Spacer()
                Text(L10n.Scene.Donation.donatebuttontitle)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(DonationButtonStyle(type: .action, filled: true))
    }
}

enum DonationButtonStyleType {
    case amount
    case action
}

struct DonationButtonStyle: ButtonStyle {

    let type: DonationButtonStyleType
    let filled: Bool
    let cornerRadius: CGFloat = 8

    func makeBody(configuration: Configuration) -> some View {
        switch (type, filled) {
        case (.amount, true):
            configuration.label
                .bold()
                .padding()
                .foregroundStyle(Color.white)
                .background(Color.indigo)
                .cornerRadius(cornerRadius)
        case (.amount, false):
            configuration.label
                .padding()
                .background(Color.indigo.opacity(0.15))
                .cornerRadius(cornerRadius)
        case (.action, true):
            configuration.label
                .bold()
                .foregroundStyle(.white)
                .padding()
                .background(Color.indigo)
                .cornerRadius(cornerRadius)
        case (.action, false):
            configuration.label
                .foregroundStyle(Color.indigo)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius).stroke(
                        Color.indigo, lineWidth: 1))
        }
    }
}

struct DefaultDonationViewModel: DonationCampaignViewModel {
    var id: String = "default"
    var paymentBaseURL: URL? {
        if UserDefaults.standard.useStagingForDonations {
            URL(string: "https://sponsor.staging.joinmastodon.org/donation/new")
        } else {
            URL(string: "https://sponsor.joinmastodon.org/donation/new")
        }
    }

    var callbackBaseURL: URL? {
        return paymentBaseURL?.deletingLastPathComponent()
    }

    var source = DonationSource.menu

    var donationMessage =
        "By supporting Mastodon, you help sustain a global network that values people over profit. Will you join us today?"  // TODO: L10 string if this is going to remain hardcoded

    var defaultFrequency = DonationFrequency.monthly

    var defaultCurrency = "EUR"

    var defaultAmount = 5

    var availableFrequencies = [DonationFrequency.monthly, .yearly, .oneTime]

    func suggestedDonations(frequency: DonationFrequency, currency: String, sorted: Bool)
        -> [SuggestedDonation]?
    {
        return [300, 500, 1000, 2000].map {
            SuggestedDonation(pennies: $0, currency: currency)
        }
    }

    func availableCurrencies(frequency: DonationFrequency) -> [String]? {
        return ["EUR", "USD"]
    }

    var donationSuccessPost = "Need default success post text and localized"  // TODO: needs L10 string if remaining hardcoded
}
