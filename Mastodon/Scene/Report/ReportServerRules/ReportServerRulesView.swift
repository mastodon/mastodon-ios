//
//  ReportServerRulesView.swift
//  Mastodon
//
//  Created by MainasuK on 2022-5-10.
//

import UIKit
import SwiftUI
import MastodonLocalization
import MastodonSDK
import MastodonAsset

struct ReportServerRulesView: View {
    
    @ObservedObject var viewModel: ReportServerRulesViewModel
    
    var body: some View {
        ScrollView(.vertical) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.Scene.Report.StepTwo.step2Of4)
                        .foregroundColor(Color(Asset.Colors.Label.secondary.color))
                        .font(Font(UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .systemFont(ofSize: 17, weight: .regular)) as CTFont))
                    Text(viewModel.headline)
                        .foregroundColor(Color(Asset.Colors.Label.primary.color))
                        .font(Font(UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .systemFont(ofSize: 28, weight: .bold)) as CTFont))
                    Text(L10n.Scene.Report.StepTwo.selectAllThatApply)
                        .foregroundColor(Color(Asset.Colors.Label.secondary.color))
                        .font(Font(UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .systemFont(ofSize: 17, weight: .regular)) as CTFont))
                }
                Spacer()
            }
            .padding()
            
            VStack(spacing: 32) {
                ForEach(viewModel.serverRules, id: \.self) { rule in
                    ReportServerRulesRowView(
                        title: rule.text,
                        isSelect: viewModel.selectRules.contains(rule)
                    )
                    .background(
                        Color(viewModel.backgroundColor)
                    )
                    .onTapGesture {
                        if viewModel.selectRules.contains(rule) {
                            viewModel.selectRules.remove(rule)
                        } else {
                            viewModel.selectRules.insert(rule)
                        }
                    }
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

struct ReportServerRulesRowView: View {
    
    var title: String
    var isSelect: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: isSelect ? "checkmark.square.fill" : "square")
                .resizable()
                .frame(width: 28, height: 28, alignment: .center)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundColor(Color(Asset.Colors.Label.primary.color))
                    .font(.headline)
            }
            Spacer()
        }
    }

}

#if DEBUG
struct ReportServerRulesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                ReportServerRulesView(viewModel: ReportServerRulesViewModel(context: .shared))
                    .navigationBarTitle(Text(""))
                    .navigationBarTitleDisplayMode(.inline)
            }
            NavigationView {
                ReportServerRulesView(viewModel: ReportServerRulesViewModel(context: .shared))
                    .navigationBarTitle(Text(""))
                    .navigationBarTitleDisplayMode(.inline)
            }
            .preferredColorScheme(.dark)
        }
    }
}
#endif
