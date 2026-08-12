import UIKit

enum LabelPrintSettings {
    static let widthKey = "labelWidthMM"
    static let heightKey = "labelHeightMM"
    static let gapKey = "labelGapMM"
    static let marginKey = "labelHorizontalMarginMM"

    static let defaultWidth = 50.0
    static let defaultHeight = 40.0
    static let defaultGap = 1.0
    static let defaultMargin = 1.5

    static var width: Double { saved(widthKey, default: defaultWidth) }
    static var height: Double { saved(heightKey, default: defaultHeight) }
    static var gap: Double { saved(gapKey, default: defaultGap) }
    static var margin: Double { saved(marginKey, default: defaultMargin) }

    static func save(width: Double, height: Double, gap: Double, margin: Double) {
        let defaults = UserDefaults.standard
        defaults.set(width, forKey: widthKey)
        defaults.set(height, forKey: heightKey)
        defaults.set(gap, forKey: gapKey)
        defaults.set(margin, forKey: marginKey)
    }

    static func reset() {
        save(width: defaultWidth, height: defaultHeight, gap: defaultGap, margin: defaultMargin)
    }

    private static func saved(_ key: String, default defaultValue: Double) -> Double {
        let value = UserDefaults.standard.double(forKey: key)
        return value > 0 || (key == gapKey && UserDefaults.standard.object(forKey: key) != nil)
            ? value : defaultValue
    }
}

enum TSPLRenderer {
    static let pixelSize = CGSize(width: 376, height: 304)

    static func labelImage(material: Material, startDate: Date, drawsGrid: Bool = true) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: pixelSize, format: format)

        return renderer.image { context in
            let cg = context.cgContext
            UIColor.white.setFill()
            cg.fill(CGRect(origin: .zero, size: pixelSize))
            UIColor.black.setStroke()
            UIColor.black.setFill()

            drawCentered(material.product, in: CGRect(x: 8, y: 4, width: 360, height: 48), font: .boldSystemFont(ofSize: 28))
            if drawsGrid {
                // Integer-aligned filled rectangles keep every separator at
                // exactly two printer dots; stroked fractional paths produced
                // uneven one/two/three-dot lines after rasterization.
                cg.fill(CGRect(x: 0, y: 53, width: 376, height: 2))
            }

            let storageY: CGFloat = 60
            for (index, type) in StorageType.allCases.enumerated() {
                let column = CGRect(x: CGFloat(index) * 125.3, y: storageY, width: 125.3, height: 48)
                drawRadio(selected: material.storage == type, text: type.title, rect: column)
            }

            if drawsGrid {
                cg.fill(CGRect(x: 0, y: 111, width: 376, height: 2))
            }

            let startText = dateFormatter.string(from: startDate)
            let endText = dateFormatter.string(from: material.expirationDate(from: startDate))
            let values = [startText, endText, material.curDay == 1 ? "当天废弃" : ""]
            for index in 0..<3 {
                let x = CGFloat(index == 0 ? 0 : (index == 1 ? 125 : 250))
                if drawsGrid, index > 0 {
                    cg.fill(CGRect(x: x - 1, y: 111, width: 2, height: 193))
                }
                let columnWidth: CGFloat = index == 2 ? 126 : 125
                drawCentered(values[index], in: CGRect(x: x + 4, y: 116, width: columnWidth - 8, height: 182), font: .systemFont(ofSize: 22, weight: .medium))
            }
        }
    }

    static func printCommand(for image: UIImage) -> Data {
        let prefix = "\r\nSIZE \(format(LabelPrintSettings.width)) mm,\(format(LabelPrintSettings.height)) mm\r\nGAP \(format(LabelPrintSettings.gap)) mm,0 mm\r\nDIRECTION 1\r\nREFERENCE 0,0\r\nDENSITY 1\r\nSET TEAR ON\r\nCLS\r\nBITMAP \(marginDots),8,47,304,0,"
        var data = Data(prefix.utf8)
        data.append(monochromeRaster(from: image))
        data.append(Data("\r\nPRINT 1,1\r\n".utf8))
        return data
    }

    static func fastPrintCommand(material: Material, startDate: Date) -> Data {
        let image = labelImage(material: material, startDate: startDate, drawsGrid: true)
        let prefix = "\r\nSIZE \(format(LabelPrintSettings.width)) mm,\(format(LabelPrintSettings.height)) mm\r\nGAP \(format(LabelPrintSettings.gap)) mm,0 mm\r\nDIRECTION 1\r\nREFERENCE 0,0\r\nDENSITY 1\r\nSET TEAR ON\r\nCLS\r\n"
        var data = Data(prefix.utf8)

        // Send every visual element, including separators, as sparse raster
        // tiles. GP-M322 applies a different coordinate transform to native
        // BAR commands, which moved the table lines through the title.
        appendSparseRaster(from: image, originX: marginDots, originY: 8, to: &data)
        data.append(Data("PRINT 1,1\r\n".utf8))
        return data
    }

    private static var marginDots: Int {
        max(0, Int((LabelPrintSettings.margin * 8).rounded()))
    }

    private static func format(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(format: "%.1f", value)
    }

    private static func appendSparseRaster(from image: UIImage, originX: Int, originY: Int, to data: inout Data) {
        let raster = monochromeRaster(from: image)
        let bytesPerRow = (Int(pixelSize.width) + 7) / 8
        let height = Int(pixelSize.height)
        let tileWidthBytes = 8
        let tileHeight = 24

        raster.withUnsafeBytes { raw in
            guard let source = raw.bindMemory(to: UInt8.self).baseAddress else { return }
            for tileY in stride(from: 0, to: height, by: tileHeight) {
                let endY = min(tileY + tileHeight, height)
                for tileX in stride(from: 0, to: bytesPerRow, by: tileWidthBytes) {
                    let endX = min(tileX + tileWidthBytes, bytesPerRow)
                    var minX = endX
                    var maxX = tileX - 1
                    var minY = endY
                    var maxY = tileY - 1

                    for y in tileY..<endY {
                        for x in tileX..<endX where source[y * bytesPerRow + x] != 0xFF {
                            minX = min(minX, x)
                            maxX = max(maxX, x)
                            minY = min(minY, y)
                            maxY = max(maxY, y)
                        }
                    }
                    guard maxX >= minX, maxY >= minY else { continue }

                    let widthBytes = maxX - minX + 1
                    let tileRows = maxY - minY + 1
                    data.append(Data("BITMAP \(originX + minX * 8),\(originY + minY),\(widthBytes),\(tileRows),0,".utf8))
                    for y in minY...maxY {
                        data.append(source + y * bytesPerRow + minX, count: widthBytes)
                    }
                    data.append(Data("\r\n".utf8))
                }
            }
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年\nMM月dd日\nHH:mm"
        return formatter
    }()

    private static func drawCentered(_ text: String, in rect: CGRect, font: UIFont) {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        style.lineBreakMode = .byWordWrapping
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black,
            .paragraphStyle: style,
        ]
        let size = (text as NSString).boundingRect(
            with: rect.size,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        ).size
        let drawRect = CGRect(x: rect.minX, y: rect.midY - size.height / 2, width: rect.width, height: size.height)
        (text as NSString).draw(in: drawRect, withAttributes: attributes)
    }

    private static func drawRadio(selected: Bool, text: String, rect: CGRect) {
        let circle = CGRect(x: rect.minX + 18, y: rect.midY - 10, width: 20, height: 20)
        let path = UIBezierPath(ovalIn: circle)
        path.lineWidth = 2
        UIColor.black.setStroke()
        path.stroke()
        if selected {
            UIBezierPath(ovalIn: circle.insetBy(dx: 5, dy: 5)).fill()
        }
        let textRect = CGRect(x: circle.maxX + 7, y: rect.minY, width: rect.width - 50, height: rect.height)
        drawCentered(text, in: textRect, font: .systemFont(ofSize: 23))
    }

    static func monochromeRaster(from image: UIImage) -> Data {
        guard let cgImage = image.cgImage else { return Data() }
        let width = Int(pixelSize.width)
        let height = Int(pixelSize.height)
        let bytesPerRow = width * 4
        var pixels = [UInt8](repeating: 255, count: height * bytesPerRow)
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return Data() }
        context.interpolationQuality = .none
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let packedWidth = (width + 7) / 8
        // GP-M322's BITMAP implementation uses 1 for an unheated (white) dot
        // and reads each row in the opposite horizontal direction from UIKit.
        // Start with a white label, clear bits for black ink, and mirror the
        // source X coordinate so the physical print reads left-to-right.
        var output = Data(repeating: 0xFF, count: packedWidth * height)
        output.withUnsafeMutableBytes { raw in
            guard let bytes = raw.bindMemory(to: UInt8.self).baseAddress else { return }
            for y in 0..<height {
                for x in 0..<width {
                    let sourceX = width - 1 - x
                    let offset = y * bytesPerRow + sourceX * 4
                    let luminance = (Int(pixels[offset]) * 30 + Int(pixels[offset + 1]) * 59 + Int(pixels[offset + 2]) * 11) / 100
                    if luminance < 170 {
                        bytes[y * packedWidth + x / 8] &= ~UInt8(0x80 >> (x % 8))
                    }
                }
            }
        }
        return output
    }
}
