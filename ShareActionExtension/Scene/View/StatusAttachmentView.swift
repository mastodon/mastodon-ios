//
//  StatusAttachmentView.swift
//  
//
//  Created by MainasuK Cirno on 2021-7-19.
//

import SwiftUI

struct StatusAttachmentView: View {

    let image: UIImage?
    let removeButtonAction: () -> Void

    var body: some View {
        let image = image ?? UIImage.placeholder(color: .systemFill)
        Color.clear
            .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fill)
            .overlay(
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            )
            .background(Color.gray)
            .cornerRadius(4)
            .badgeView(
                Button(action: {
                    removeButtonAction()
                }, label: {
                    Image(systemName: "minus.circle.fill")
                        .renderingMode(.original)
                        .font(.system(size: 22, weight: .bold, design: .default))
                })
                .buttonStyle(BorderlessButtonStyle())
            )
    }
}

extension View {
    func badgeView<Content>(_ content: Content) -> some View where Content: View {
        overlay(
            ZStack {
                content
            }
            .alignmentGuide(.top) { $0.height / 2 }
            .alignmentGuide(.trailing) { $0.width / 2 }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        )
    }
}


struct StatusAttachmentView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            StatusAttachmentView(
                image: UIImage(systemName: "photo"),
                removeButtonAction: {
                    // do nothing
                }
            )
            .padding(20)
        }
    }
}
