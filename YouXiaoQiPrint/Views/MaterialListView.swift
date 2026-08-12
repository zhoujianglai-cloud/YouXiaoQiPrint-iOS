import SwiftUI

struct MaterialListView: View {
    @EnvironmentObject private var store: MaterialStore
    @State private var selectedType = "all"
    @State private var showingAdd = false

    private var visibleMaterials: [Material] {
        if selectedType == "all" { return store.materials }
        return store.materials.filter { String($0.type) == selectedType }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: []) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 94), spacing: 10)], spacing: 10) {
                    FilterChip(title: "全部", selected: selectedType == "all") {
                        selectedType = "all"
                    }
                    ForEach(store.groups) { group in
                        FilterChip(title: shortName(group.name), selected: selectedType == group.id) {
                            selectedType = group.id
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)

                LazyVStack(spacing: 14) {
                    ForEach(visibleMaterials) { material in
                        NavigationLink(value: material) {
                            MaterialCard(material: material)
                        }
                        .buttonStyle(ResponsiveButtonStyle())
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("食材")
        .navigationDestination(for: Material.self) { MaterialDetailView(material: $0) }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    AppFeedback.tap()
                    showingAdd = true
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(AppTheme.accent, in: Circle())
                }
            }
        }
        .sheet(isPresented: $showingAdd) { NavigationStack { AddMaterialView() } }
    }

    private func shortName(_ name: String) -> String {
        name
            .replacingOccurrences(of: "后厨", with: "")
            .replacingOccurrences(of: "岗位", with: "")
    }
}

struct MaterialSearchView: View {
    @EnvironmentObject private var store: MaterialStore
    @State private var query = ""

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(store.search(query)) { material in
                    NavigationLink(value: material) {
                        MaterialCard(material: material)
                    }
                    .buttonStyle(ResponsiveButtonStyle())
                }
            }
            .padding(18)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("搜索")
        .navigationDestination(for: Material.self) { MaterialDetailView(material: $0) }
        .searchable(text: $query, prompt: "产品、类别或岗位")
    }
}

private struct MaterialCard: View {
    let material: Material

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(material.product)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text("\(material.typeName) · \(material.cateName)")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(durationText(material.durationHours, currentDay: material.curDay == 1))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 13)
                .padding(.vertical, 10)
                .background(AppTheme.accent, in: Capsule())
        }
        .padding(18)
        .background(AppTheme.surfaceRaised, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }

    private func durationText(_ hours: Int, currentDay: Bool) -> String {
        if currentDay { return "当天" }
        if hours >= 24, hours % 24 == 0 { return "\(hours / 24)天" }
        return "\(hours)小时"
    }
}

private struct FilterChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            AppFeedback.tap()
            action()
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(selected ? AppTheme.accent : AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    if !selected {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.accent.opacity(0.45), lineWidth: 1)
                    }
                }
        }
        .buttonStyle(ResponsiveButtonStyle())
    }
}
