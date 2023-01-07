//
//  UIImageExtensionTests.swift
//  MastodonUITests
//
//  Created by woxtu on 2023/01/07.
//

@testable import MastodonUI
import XCTest

final class UIImageExtensionTests: XCTestCase {
    func testNormalizeImage() {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 100)).image { _ in }
        XCTAssertEqual(image.imageOrientation, .up)
        XCTAssertEqual(image.size, CGSize(width: 200, height: 100))
        
        let rotatedImage = UIImage(cgImage: image.cgImage!, scale: image.scale, orientation: .right)
        XCTAssertEqual(rotatedImage.imageOrientation, .right)
        XCTAssertEqual(rotatedImage.size, CGSize(width: 100, height: 200))
        
        let normalizedImage = rotatedImage.normalized()
        XCTAssertEqual(normalizedImage.imageOrientation, .up)
        XCTAssertEqual(normalizedImage.size, CGSize(width: 200, height: 100))
    }
}
