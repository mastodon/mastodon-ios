//
//  PollAddOptionRow.swift
//  
//
//  Created by MainasuK on 2022/10/26.
//

import SwiftUI
import MastodonAsset
import MastodonCore
import Combine

public struct PollAddOptionRow: View {
 
    @StateObject var viewModel = ViewModel()
    
    public var body: some View {
        HStack(alignment: .center, spacing: 16) {
            HStack(alignment: .center, spacing: .zero) {
                Image(systemName: "plus.circle")
                    .frame(width: 20, height: 20)
                    .padding(.leading, 16)
                    .padding(.trailing, 16 - 10)     // 8pt for TextField leading
                    .font(.system(size: 17))
                PollOptionTextField(
                    text: .constant(""),
                    index: 999,
                    delegate: nil
                ) { textField in
                    // do nothing
                }
                .hidden()
            }
            .background(Color(viewModel.backgroundColor))
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            Image(uiImage: Asset.Scene.Compose.reorderDot.image.withRenderingMode(.alwaysTemplate))
                .foregroundColor(Color(UIColor.label))
                .hidden()
        }
        .background(Color.clear)
    }
    
}

extension PollAddOptionRow {
    public class ViewModel: ObservableObject {
        // output
        public var backgroundColor = SystemTheme.composePollRowBackgroundColor
    }
}
