// Copyright © 2025 Mastodon gGmbH. All rights reserved.
import SwiftUI
import MastodonAsset
import MastodonLocalization
import UIKit // for the attributed string colors

struct ShowMoreLozenge: View {

    let buttonTextWhenHiding: String
    let buttonTextWhenShowing: String
    @ObservedObject var viewModel: ShowMoreViewModel
    
    var body: some View {
        Button {
            viewModel.showMore(!viewModel.isShowing)
        } label: {
            VStack(alignment: .leading) {
                ForEach(viewModel.reasons, id: \.id) { reasonMessage in
                    Text(reasonMessage)
                        .font(.subheadline)
                }
                HStack() {
                    Text(viewModel.isShowing ? buttonTextWhenShowing : buttonTextWhenHiding)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Asset.Colors.Brand.blurple.swiftUIColor)
                    
                    Spacer()
                        .frame(maxWidth: .infinity)
                }
            }
            .accessibilityElement(children: .combine)
            .frame(maxWidth: .infinity)
            .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            .background {
                MastodonSecondaryBackground(fillInDarkModeOnly: false)
            }
        }
    }
}

class ShowMoreViewModel: ObservableObject {
    var reasons: [AttributedString]
    @Published var isShowing: Bool
    private let _showMore: (Bool)->()
    
    init(isShowing: Bool, isFilter: Bool, reasons: [String],  showMore: @escaping (Bool) -> Void) {
        if isFilter {
            self.reasons = reasons.map({ filterTitle in
                var attributed = AttributedString(L10n.Common.Controls.Status.matchesFilter(filterTitle))
                attributed.font = .subheadline
                attributed.foregroundColor = .secondaryLabel
                
                if let rangeOfFilterName = attributed.range(of: filterTitle) {
                    attributed[rangeOfFilterName].foregroundColor = .label
                }
                
                return attributed
            })
        } else {
            assert(reasons.count == 1)
            self.reasons = reasons.map { spoilerText in
                var attributed = AttributedString(spoilerText)
                attributed.font = .subheadline
                return attributed
            }
        }
        self.isShowing = isShowing
        _showMore = showMore
    }
    
    func showMore(_ shouldShow: Bool) {
        isShowing = shouldShow
        _showMore(shouldShow)
    }
}

extension AttributedString: @retroactive Identifiable {
    public var id: String {
        return String(characters)
    }
}
