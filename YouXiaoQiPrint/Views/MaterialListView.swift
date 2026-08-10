import SwiftUI

struct MaterialListView: View {
    @EnvironmentObject private var store: MaterialStore
    @State private var selectedType = "1"
    @State private var showingAdd = false

    private var selectedGroup: MaterialGroup? {
        store.groups.first(where: { $0.id == selectedType }) ?? store.groups.first
    }

    var body: some View {
        VStack(spacing: 0) {
            if !store.groups.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(store.groups) { group in
                            Button(group.name) {
                                AppFeedback.tap()
                                selectedType = group.id
                            }
                                .buttonStyle(TypeChipStyle(selected: selectedGroup?.id == group.id))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                Divider()
            }

            List {
                ForEach(selectedGroup?.categories ?? []) { category in
                    Section(category.name) {
                        ForEach(category.materials) { material in
                            NavigationLink(value: material) {
                                MaterialRow(material: material)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("模版")
        .navigationDestination(for: Material.self) { MaterialDetailView(material: $0) }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    AppFeedback.tap()
                    showingAdd = true
                } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAdd) { NavigationStack { AddMaterialView() } }
        .onAppear {
            if !store.groups.contains(where: { $0.id == selectedType }) {
                selectedType = store.groups.first?.id ?? "1"
            }
        }
    }
}

struct MaterialSearchView: View {
    @EnvironmentObject private var store: MaterialStore
    @State private var query = ""

    var body: some View {
        List(store.search(query)) { material in
            NavigationLink(value: material) { MaterialRow(material: material, showPath: true) }
        }
        .navigationTitle("搜索")
        .navigationDestination(for: Material.self) { MaterialDetailView(material: $0) }
        .searchable(text: $query, prompt: "产品、类别或岗位")
    }
}

private struct MaterialRow: View {
    let material: Material
    var showPath = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(material.product).font(.body.weight(.medium))
            if showPath {
                Text("\(material.typeName) · \(material.cateName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 5) {
                Text(material.storage.title)
                Text(material.curDay == 1 ? "当天废弃" : durationText(material.durationHours))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 3)
    }

    private func durationText(_ hours: Int) -> String {
        if hours >= 24, hours % 24 == 0 { return "\(hours / 24) 天" }
        return "\(hours) 小时"
    }
}

private struct TypeChipStyle: ButtonStyle {
    let selected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(selected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(selected ? Color.orange : Color(.secondarySystemBackground), in: Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
