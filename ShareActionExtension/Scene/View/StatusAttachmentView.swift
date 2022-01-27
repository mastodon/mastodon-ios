//
//  StatusAttachmentView.swift
//  
//
//  Created by MainasuK Cirno on 2021-7-19.
//

import SwiftUI
import Introspect

struct StatusAttachmentView: View {

    let image: UIImage?
    let descriptionPlaceholder: String
    @Binding var description: String
    let errorPrompt: String?
    let errorPromptImage: UIImage
    let isUploading: Bool
    let progressViewTintColor: UIColor

    let removeButtonAction: () -> Void

    var body: some View {
        let image = image ?? UIImage.placeholder(color: .systemFill)
        ZStack(alignment: .bottom) {
            if let errorPrompt = errorPrompt {
                Color.clear
                    .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fill)
                    .overlay(
                        VStack(alignment: .center) {
                            Image(uiImage: errorPromptImage)
                            Text(errorPrompt)
                                .lineLimit(2)
                        }
                    )
                    .background(Color.gray)
            } else {
                Color.clear
                    .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fill)
                    .overlay(
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    )
                    .background(Color.gray)
                LinearGradient(gradient: Gradient(colors: [Color(white: 0, opacity: 0.69), Color.clear]), startPoint: .bottom, endPoint: .top)
                    .frame(maxHeight: 71)
                TextField("", text: $description)
                    .placeholder(when: description.isEmpty) {
                        Text(descriptionPlaceholder).foregroundColor(Color(white: 1, opacity: 0.6))
                            .lineLimit(1)
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 15, weight: .regular, design: .default))
                    .padding(EdgeInsets(top: 0, leading: 8, bottom: 7, trailing: 8))
            }
        }
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
        .overlay(
            Group {
                if isUploading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(progressViewTintColor)))
                }
            }
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

/// ref: https://stackoverflow.com/a/57715771/3797903
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}


//struct StatusAttachmentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ScrollView {
//            StatusAttachmentView(
//                image: UIImage(systemName: "photo"),
//                descriptionPlaceholder: "Describe photo",
//                description: .constant(""),
//                errorPrompt: nil,
//                errorPromptImage: StatusAttachmentViewModel.photoFillSplitImage,
//                isUploading: true,
//                progressViewTintColor: .systemFill,
//                removeButtonAction: {
//                    // do nothing
//                }
//            )
//            .padding(20)
//        }
//    }
//}
