import Combine
import Foundation

final class MaterialStore: ObservableObject {
    @Published private(set) var materials: [Material] = []
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let seedSchemaVersion = 2
    private let seedSchemaVersionKey = "materialSeedSchemaVersion"

    init() {
        load()
    }

    var groups: [MaterialGroup] {
        Dictionary(grouping: materials, by: \.type)
            .map { type, typeMaterials in
                let categories = Dictionary(grouping: typeMaterials, by: \.cateId)
                    .map { category, values in
                        CategoryGroup(
                            id: "\(type)-\(category)",
                            name: values.first?.cateName ?? "未分类",
                            materials: values.sorted { $0.productId < $1.productId }
                        )
                    }
                    .sorted { $0.id.localizedStandardCompare($1.id) == .orderedAscending }
                return MaterialGroup(id: "\(type)", name: typeMaterials.first?.typeName ?? "其他", categories: categories)
            }
            .sorted { (Int($0.id) ?? 0) < (Int($1.id) ?? 0) }
    }

    func search(_ query: String) -> [Material] {
        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return materials }
        return materials.filter {
            $0.typeName.localizedCaseInsensitiveContains(keyword)
                || $0.cateName.localizedCaseInsensitiveContains(keyword)
                || $0.product.localizedCaseInsensitiveContains(keyword)
        }
    }

    func update(_ material: Material) {
        guard let index = materials.firstIndex(where: { $0.uuid == material.uuid }) else { return }
        materials[index] = material
        save()
    }

    func add(_ material: Material) {
        materials.append(material)
        save()
    }

    func delete(_ material: Material) {
        materials.removeAll { $0.uuid == material.uuid }
        save()
    }

    func resetToDefaults() {
        try? FileManager.default.removeItem(at: savedURL)
        loadSeed()
    }

    private var savedURL: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent("materials.json")
    }

    private func load() {
        if UserDefaults.standard.integer(forKey: seedSchemaVersionKey) < seedSchemaVersion {
            loadSeed()
            return
        }
        if let data = try? Data(contentsOf: savedURL),
           let decoded = try? decoder.decode([Material].self, from: data) {
            materials = decoded
        } else {
            loadSeed()
        }
    }

    private func loadSeed() {
        guard let url = Bundle.main.url(forResource: "SeedMaterials", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? decoder.decode([Material].self, from: data) else {
            materials = []
            return
        }
        materials = decoded
        save()
        UserDefaults.standard.set(seedSchemaVersion, forKey: seedSchemaVersionKey)
    }

    private func save() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(materials) else { return }
        try? data.write(to: savedURL, options: .atomic)
    }
}
