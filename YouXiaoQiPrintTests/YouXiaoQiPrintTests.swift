import XCTest
import UIKit
@testable import YouXiaoQiPrint

final class YouXiaoQiPrintTests: XCTestCase {
    func testExpirationUsesSelectedStorageHours() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let material = Material(
            id: 0,
            type: 1,
            typeName: "水吧",
            cateId: 1,
            cateName: "茶叶类",
            productId: 1,
            product: "测试",
            storeType: StorageType.refrigerated.rawValue,
            refrigerationTime: 48,
            normalTemperatureTime: 0,
            freezingTime: 0,
            curDay: 0,
            remarks: ""
        )
        XCTAssertEqual(material.expirationDate(from: start).timeIntervalSince(start), 48 * 3600, accuracy: 0.1)
    }

    func testMaterialsUseIndependentUIIdentityWhenAndroidIDsMatch() {
        let first = makeMaterial(productId: 48, product: "炸鸡裹粉")
        let second = makeMaterial(productId: 49, product: "童子鸡裹粉")
        XCTAssertNotEqual(first.id, second.id)
        XCTAssertEqual(first.sourceId, 0)
        XCTAssertEqual(second.sourceId, 0)
    }

    func testTSPLCommandMatchesRecoveredLabelGeometry() {
        let image = UIGraphicsImageRenderer(size: TSPLRenderer.pixelSize).image { _ in }
        let command = TSPLRenderer.printCommand(for: image)
        let prefix = String(decoding: command.prefix(140), as: UTF8.self)
        XCTAssertTrue(prefix.contains("SIZE 50 mm,40 mm"))
        XCTAssertTrue(prefix.contains("BITMAP 12,8,47,304,0,"))
        XCTAssertTrue(command.count > 14_000)
    }

    func testGPPrinterRasterUsesWhiteBackgroundAndCorrectsHorizontalMirror() {
        let image = UIGraphicsImageRenderer(size: TSPLRenderer.pixelSize).image { context in
            UIColor.white.setFill()
            context.cgContext.fill(CGRect(origin: .zero, size: TSPLRenderer.pixelSize))
            UIColor.black.setFill()
            context.cgContext.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        let raster = TSPLRenderer.monochromeRaster(from: image)
        XCTAssertEqual(raster.count, 47 * 304)
        XCTAssertTrue(raster.prefix(46).allSatisfy { $0 == 0xFF })
        XCTAssertEqual(raster[46], 0xFE)
        XCTAssertTrue(raster.dropFirst(47).allSatisfy { $0 == 0xFF })
    }


    private func makeMaterial(productId: Int, product: String) -> Material {
        Material(
            id: 0,
            type: 2,
            typeName: "后厨总配岗位",
            cateId: 10,
            cateName: "干粉类",
            productId: productId,
            product: product,
            storeType: StorageType.roomTemperature.rawValue,
            refrigerationTime: 0,
            normalTemperatureTime: 168,
            freezingTime: 0,
            curDay: 0,
            remarks: ""
        )
    }
}
