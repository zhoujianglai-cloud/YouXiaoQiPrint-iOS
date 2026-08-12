import SwiftUI

struct AddMaterialView: View {
    @EnvironmentObject private var store: MaterialStore
    @Environment(\.dismiss) private var dismiss

    @State private var typeName = "水吧"
    @State private var categoryName = "其他类"
    @State private var product = ""
    @State private var storage = StorageType.refrigerated
    @State private var hours = 24
    @State private var currentDay = false
    @State private var remarks = ""

    var body: some View {
        Form {
            Section("分类") {
                TextField("岗位名称", text: $typeName)
                TextField("类别名称", text: $categoryName)
                TextField("产品名称", text: $product)
            }
            Section("有效期") {
                Picker("储存方式", selection: $storage) {
                    ForEach(StorageType.allCases) { Text($0.title).tag($0) }
                }
                Toggle("当天废弃", isOn: $currentDay)
                if !currentDay {
                    Stepper("\(hours) 小时", value: $hours, in: 1...17_520)
                }
                TextField("备注", text: $remarks, axis: .vertical)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .navigationTitle("添加模版")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存", action: save).disabled(product.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func save() {
        let existingType = store.materials.first(where: { $0.typeName == typeName })
        let type = existingType?.type ?? ((store.materials.map(\.type).max() ?? 0) + 1)
        let existingCategory = store.materials.first(where: { $0.type == type && $0.cateName == categoryName })
        let category = existingCategory?.cateId ?? ((store.materials.map(\.cateId).max() ?? 0) + 1)
        let productId = (store.materials.map(\.productId).max() ?? 0) + 1
        var item = Material(
            id: 0,
            type: type,
            typeName: typeName,
            cateId: category,
            cateName: categoryName,
            productId: productId,
            product: product,
            storeType: storage.rawValue,
            refrigerationTime: 0,
            normalTemperatureTime: 0,
            freezingTime: 0,
            curDay: currentDay ? 1 : 0,
            remarks: remarks
        )
        switch storage {
        case .refrigerated: item.refrigerationTime = currentDay ? 24 : hours
        case .frozen: item.freezingTime = currentDay ? 24 : hours
        case .roomTemperature: item.normalTemperatureTime = currentDay ? 24 : hours
        }
        store.add(item)
        dismiss()
    }
}
