import Foundation

enum StorageType: Int, Codable, CaseIterable, Identifiable {
    case refrigerated = 1
    case frozen = 2
    case roomTemperature = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .refrigerated: return "冷藏"
        case .frozen: return "冷冻"
        case .roomTemperature: return "常温"
        }
    }
}

struct Material: Codable, Identifiable, Hashable {
    var uuid = UUID()
    var sourceId: Int
    var id: UUID { uuid }
    var type: Int
    var typeName: String
    var cateId: Int
    var cateName: String
    var productId: Int
    var product: String
    var storeType: Int
    var refrigerationTime: Int
    var normalTemperatureTime: Int
    var freezingTime: Int
    var curDay: Int
    var remarks: String

    enum CodingKeys: String, CodingKey {
        case sourceId = "id"
        case type, typeName, cateId, cateName, productId, product, storeType
        case refrigerationTime, normalTemperatureTime, freezingTime, curDay, remarks
    }

    init(
        uuid: UUID = UUID(),
        id: Int,
        type: Int,
        typeName: String,
        cateId: Int,
        cateName: String,
        productId: Int,
        product: String,
        storeType: Int,
        refrigerationTime: Int,
        normalTemperatureTime: Int,
        freezingTime: Int,
        curDay: Int,
        remarks: String
    ) {
        self.uuid = uuid
        self.sourceId = id
        self.type = type
        self.typeName = typeName
        self.cateId = cateId
        self.cateName = cateName
        self.productId = productId
        self.product = product
        self.storeType = storeType
        self.refrigerationTime = refrigerationTime
        self.normalTemperatureTime = normalTemperatureTime
        self.freezingTime = freezingTime
        self.curDay = curDay
        self.remarks = remarks
    }

    var storage: StorageType {
        get { StorageType(rawValue: storeType) ?? .refrigerated }
        set { storeType = newValue.rawValue }
    }

    var durationHours: Int {
        if curDay == 1 { return 24 }
        switch storage {
        case .refrigerated: return refrigerationTime
        case .frozen: return freezingTime
        case .roomTemperature: return normalTemperatureTime
        }
    }

    func expirationDate(from start: Date) -> Date {
        Calendar.current.date(byAdding: .hour, value: durationHours, to: start) ?? start
    }
}

struct MaterialGroup: Identifiable {
    let id: String
    let name: String
    let categories: [CategoryGroup]
}

struct CategoryGroup: Identifiable {
    let id: String
    let name: String
    let materials: [Material]
}
