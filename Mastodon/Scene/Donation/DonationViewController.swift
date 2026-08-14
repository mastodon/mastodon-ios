// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonAsset
import MastodonLocalization
import MastodonSDK
import SwiftUI

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

enum DonationFlowDestination {
    case submitDonation(URL)
    case donationCompleted(DonationResult)
}

struct DonationView: View {
    @Environment(DonationViewModel.self) var viewModel
    @Environment(MastodonNavigationRouter.self) var navigator

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
        .padding()
    }

    @ViewBuilder var topMessage: some View {
        GeometryReader { geom in
            Text(viewModel.campaign?.donationMessage ?? "")
                .frame(height: geom.size.height)
                .allowsTightening(true)
                .lineLimit(3)
                .scaledToFit()
                .minimumScaleFactor(0.7)
        }
    }

    @ViewBuilder var frequencyPicker: some View {
        if let campaign = viewModel.campaign {
            @Bindable var viewModel = viewModel
            Picker(selection: $viewModel.selectedFrequency) {
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
    }

    @ViewBuilder var amountEntry: some View {
        if let campaign = viewModel.campaign {
            @Bindable var viewModel = viewModel
            VStack {
                HStack {
                    Picker(selection: $viewModel.selectedCurrency) {
                        ForEach(
                            campaign.availableCurrencies(
                                frequency: viewModel.selectedFrequency ?? campaign.defaultFrequency) ?? [], id: \.self
                        ) {
                            Text($0)
                                .tag($0)
                        }
                    } label: {
                        Text(viewModel.selectedCurrency ?? campaign.defaultCurrency)
                    }
                    .frame(height: 52)
                    .background(Color.gray.opacity(0.25))
                    .clipShape(.rect(topLeadingRadius: 4, bottomLeadingRadius: 4))
                    
                    TextField(
                        value: $viewModel.selectedAmount,
                        format: .currency(code: viewModel.selectedCurrency ?? campaign.defaultCurrency)
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
                        frequency: viewModel.selectedFrequency ?? campaign.defaultFrequency, currency: viewModel.selectedCurrency ?? campaign.defaultCurrency, sorted: true)
                    {
                        ForEach(predefinedAmounts, id: \.unitAmount) { amount in
                            Button(action: {
                                viewModel.selectedAmount = amount.unitAmount
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
                                    filled: viewModel.selectedAmount == amount.unitAmount
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
    }

    @ViewBuilder var donationButton: some View {
        Button(action: {
            guard let urlForCurrentSelections = viewModel.urlForCurrentSelections else { return }
            navigator.push(.donations(.submitDonation(urlForCurrentSelections)))
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

