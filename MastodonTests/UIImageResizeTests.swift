import XCTest
import UIKit
@testable import MastodonUI

@MainActor
final class UIImageResizeTests: XCTestCase {
    func test_resizedUsesPixelDimensions() throws {
        let image = makeImage()
        let resized = image.resized(size: CGSize(width: 80, height: 40))
        let raster = try XCTUnwrap(resized.cgImage)

        XCTAssertEqual(raster.width, 80)
        XCTAssertEqual(raster.height, 40)
    }

    func test_repeatedJPEGResizeReducesPixelDimensions() throws {
        let first = makeImage().resized(size: CGSize(width: 80, height: 40))
        let data = try XCTUnwrap(first.jpegData(compressionQuality: 0.8))
        let decoded = try XCTUnwrap(UIImage(data: data))
        let nextSize = CGSize(width: decoded.size.width * 0.8, height: decoded.size.height * 0.8)
        let second = decoded.resized(size: nextSize)
        let raster = try XCTUnwrap(second.cgImage)

        XCTAssertEqual(raster.width, 64)
        XCTAssertEqual(raster.height, 32)
    }

    func test_resizedDrawsOrientedImageAtRequestedPixelSize() throws {
        let raster = try XCTUnwrap(makeImage().cgImage)
        let oriented = UIImage(cgImage: raster, scale: 1, orientation: .right)
        let resized = oriented.resized(size: CGSize(width: 40, height: 80))
        let result = try XCTUnwrap(resized.cgImage)

        XCTAssertEqual(result.width, 40)
        XCTAssertEqual(result.height, 80)
        XCTAssertEqual(resized.imageOrientation, .up)
    }

    private func makeImage() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 100, height: 50), format: format).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 100, height: 50))
        }
    }
}
