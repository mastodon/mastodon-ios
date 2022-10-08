//
//  ReportReasonView.swift
//  Mastodon
//
//  Created by MainasuK on 2022-5-10.
//

import UIKit
import SwiftUI
import MastodonLocalization
import MastodonSDK
import MastodonAsset
import MastodonCore

struct ReportReasonView: View {
    
    @ObservedObject var viewModel: ReportReasonViewModel
    
    var body: some View {
        ScrollView(.vertical) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.Scene.Report.StepOne.step1Of4)
                        .foregroundColor(Color(Asset.Colors.Label.secondary.color))
                        .font(Font(UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .systemFont(ofSize: 17, weight: .regular)) as CTFont))
                    Text(viewModel.headline)
                        .foregroundColor(Color(Asset.Colors.Label.primary.color))
                        .font(Font(UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .systemFont(ofSize: 28, weight: .bold)) as CTFont))
                    Text(L10n.Scene.Report.StepOne.selectTheBestMatch)
                        .foregroundColor(Color(Asset.Colors.Label.secondary.color))
                        .font(Font(UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .systemFont(ofSize: 17, weight: .regular)) as CTFont))
                }
                Spacer()
            }
            .padding()
            
            VStack(spacing: 16) {
                if let serverRules = viewModel.serverRules {
                    ForEach(ReportReasonViewModel.Reason.allCases, id: \.self) { reason in
                        switch reason {
                        case .violateRule where serverRules.isEmpty:
                            EmptyView()
                        default:
                            ReportReasonRowView(reason: reason, isSelect: reason == viewModel.selectReason)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.selectReason = reason
                                }
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .padding()
            .transition(.opacity)
            .animation(.easeInOut)
            
            Spacer()
                .frame(minHeight: viewModel.bottomPaddingHeight)
        }
        .background(
            Color(viewModel.backgroundColor)
        )
    }

}

struct ReportReasonRowView: View {
    
    var reason: ReportReasonViewModel.Reason
    var isSelect: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: isSelect ? "checkmark.circle.fill" : "circle")
                .resizable()
                .frame(width: 28, height: 28, alignment: .center)
            VStack(alignment: .leading, spacing: 4) {
                Text(reason.title)
                    .foregroundColor(Color(Asset.Colors.Label.primary.color))
                    .font(.headline)
                Text(reason.subtitle)
                    .font(.subheadline)
                    .foregroundColor(Color(Asset.Colors.Label.secondary.color))
            }
            Spacer()
        }
    }

}

#if DEBUG
struct ReportReasonView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                ReportReasonView(viewModel: ReportReasonViewModel(context: .shared))
                    .navigationBarTitle(Text(""))
                    .navigationBarTitleDisplayMode(.inline)
            }
            NavigationView {
                ReportReasonView(viewModel: ReportReasonViewModel(context: .shared))
                    .navigationBarTitle(Text(""))
                    .navigationBarTitleDisplayMode(.inline)
            }
            .preferredColorScheme(.dark)
        }
    }
}
#endif
