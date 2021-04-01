//
//  CGImage.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-31.
//

import CoreImage

extension CGImage {
    // Reference
    // https://www.itu.int/dms_pubrec/itu-r/rec/bt/R-REC-BT.709-6-201506-I!!PDF-E.pdf
    // Luma Y = 0.2126R + 0.7152G + 0.0722B
    var brightness: CGFloat? {
        let context = CIContext()   // default with metal accelerate
        let ciImage = CIImage(cgImage: self)
        let rec709Image = context.createCGImage(
            ciImage,
            from: ciImage.extent,
            format: .RGBA8,
            colorSpace: CGColorSpace(name: CGColorSpace.itur_709)   // BT.709 a.k.a Rec.709
        )
        guard let image = rec709Image,
              image.bitsPerPixel == 32,
              let data = rec709Image?.dataProvider?.data,
              let pointer = CFDataGetBytePtr(data) else { return nil }
        
        let length = CFDataGetLength(data)
        guard length > 0 else { return nil}
        
        var luma: CGFloat = 0.0
        for i in stride(from: 0, to: length, by: 4) {
            let r = pointer[i]
            let g = pointer[i + 1]
            let b = pointer[i + 2]
            let Y = 0.2126 * CGFloat(r) + 0.7152 * CGFloat(g) + 0.0722 * CGFloat(b)
            luma += Y
        }
        luma /= CGFloat(width * height)
        return luma
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI
import UIKit

class BrightnessView: UIView {
    let label = UILabel()
    let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        stackView.distribution = .fillEqually
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(label)
        
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        label.textAlignment = .center
        label.numberOfLines = 0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setImage(_ image: UIImage) {
        imageView.image = image
        
        guard let brightness = image.cgImage?.brightness,
              let style = image.domainLumaCoefficientsStyle else {
            label.text = "<nil>"
            return
        }
        let styleDescription: String = {
            switch style {
            case .light:        return "Light"
            case .dark:         return "Dark"
            case .unspecified:  fallthrough
            @unknown default:
                return "Unknown"
            }
        }()
        
        label.text = styleDescription + "\n" + "\(brightness)"
    }
}

struct CGImage_Brightness_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            UIViewPreview(width: 375) {
                let view = BrightnessView()
                view.setImage(.placeholder(color: .black))
                return view
            }
            .previewLayout(.fixed(width: 375, height: 44))
            UIViewPreview(width: 375) {
                let view = BrightnessView()
                view.setImage(.placeholder(color: .gray))
                return view
            }
            .previewLayout(.fixed(width: 375, height: 44))
            UIViewPreview(width: 375) {
                let view = BrightnessView()
                view.setImage(.placeholder(color: .separator))
                return view
            }
            .previewLayout(.fixed(width: 375, height: 44))
            UIViewPreview(width: 375) {
                let view = BrightnessView()
                view.setImage(.placeholder(color: .red))
                return view
            }
            .previewLayout(.fixed(width: 375, height: 44))
            UIViewPreview(width: 375) {
                let view = BrightnessView()
                view.setImage(.placeholder(color: .green))
                return view
            }
            .previewLayout(.fixed(width: 375, height: 44))
            UIViewPreview(width: 375) {
                let view = BrightnessView()
                view.setImage(.placeholder(color: .blue))
                return view
            }
            .previewLayout(.fixed(width: 375, height: 44))
            UIViewPreview(width: 375) {
                let view = BrightnessView()
                view.setImage(.placeholder(color: .secondarySystemGroupedBackground))
                return view
            }
            .previewLayout(.fixed(width: 375, height: 44))
        }
    }
    
}

#endif


