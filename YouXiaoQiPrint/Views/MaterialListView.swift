import SwiftUI

struct MaterialListView: View {
    @EnvironmentObject private var store: MaterialStore
    @State private var selectedType = "all"
    @State private var showingAdd = false
    @State private var pendingMaterialDelete: Material?
    @State private var pendingGroupDelete: MaterialGroup?

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
                        FilterChip(
                            title: shortName(group.name),
                            selected: selectedType == group.id,
                            canDelete: store.canDelete(group),
                            action: { selectedType = group.id },
                            deleteAction: { pendingGroupDelete = group }
                        )
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)

                LazyVStack(spacing: 14) {
                    ForEach(visibleMaterials) { material in
                        DeletableMaterialRow(
                            material: material,
                            canDelete: store.canDelete(material),
                            deleteAction: { pendingMaterialDelete = material }
                        )
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
        .alert("删除新增食材？", isPresented: materialDeleteAlert) {
            Button("删除", role: .destructive) {
                if let material = pendingMaterialDelete {
                    store.delete(material)
                    AppFeedback.success()
                }
                pendingMaterialDelete = nil
            }
            Button("取消", role: .cancel) { pendingMaterialDelete = nil }
        } message: {
            Text("删除后无法恢复“\(pendingMaterialDelete?.product ?? "")”。")
        }
        .alert("删除新增分类？", isPresented: groupDeleteAlert) {
            Button("删除分类", role: .destructive) {
                if let group = pendingGroupDelete {
                    store.delete(group)
                    selectedType = "all"
                    AppFeedback.success()
                }
                pendingGroupDelete = nil
            }
            Button("取消", role: .cancel) { pendingGroupDelete = nil }
        } message: {
            Text("“\(pendingGroupDelete?.name ?? "")”及其中新增的食材会一起删除，且无法恢复。")
        }
    }

    private func shortName(_ name: String) -> String {
        let shortened = name
            .replacingOccurrences(of: "后厨", with: "")
            .replacingOccurrences(of: "岗位", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return shortened.isEmpty ? name : shortened
    }

    private var materialDeleteAlert: Binding<Bool> {
        Binding(get: { pendingMaterialDelete != nil }, set: { if !$0 { pendingMaterialDelete = nil } })
    }

    private var groupDeleteAlert: Binding<Bool> {
        Binding(get: { pendingGroupDelete != nil }, set: { if !$0 { pendingGroupDelete = nil } })
    }
}

struct MaterialSearchView: View {
    @EnvironmentObject private var store: MaterialStore
    @State private var query = ""
    @State private var pendingDelete: Material?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(store.search(query)) { material in
                    DeletableMaterialRow(
                        material: material,
                        canDelete: store.canDelete(material),
                        deleteAction: { pendingDelete = material }
                    )
                }
            }
            .padding(18)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("搜索")
        .navigationDestination(for: Material.self) { MaterialDetailView(material: $0) }
        .searchable(text: $query, prompt: "产品、类别或岗位")
        .alert("删除新增食材？", isPresented: deleteAlert) {
            Button("删除", role: .destructive) {
                if let material = pendingDelete {
                    store.delete(material)
                    AppFeedback.success()
                }
                pendingDelete = nil
            }
            Button("取消", role: .cancel) { pendingDelete = nil }
        } message: {
            Text("删除后无法恢复“\(pendingDelete?.product ?? "")”。")
        }
    }

    private var deleteAlert: Binding<Bool> {
        Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })
    }
}

private struct DeletableMaterialRow: View {
    let material: Material
    let canDelete: Bool
    let deleteAction: () -> Void
    @State private var offset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .trailing) {
            if canDelete {
                Button(role: .destructive) {
                    AppFeedback.tap()
                    deleteAction()
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: "trash.fill")
                        Text("删除").font(.caption.bold())
                    }
                    .foregroundStyle(.white)
                    .frame(width: 82)
                    .frame(maxHeight: .infinity)
                    .background(Color.red, in: RoundedRectangle(cornerRadius: 20))
                }
            }

            NavigationLink(value: material) {
                MaterialCard(material: material)
            }
            .buttonStyle(ResponsiveButtonStyle())
            .offset(x: offset)
            .simultaneousGesture(
                DragGesture(minimumDistance: 18)
                    .onChanged { value in
                        guard canDelete, abs(value.translation.width) > abs(value.translation.height) else { return }
                        offset = min(0, max(-82, value.translation.width))
                    }
                    .onEnded { value in
                        guard canDelete else { return }
                        withAnimation(.easeOut(duration: 0.18)) {
                            offset = value.translation.width < -45 ? -82 : 0
                        }
                        if offset < 0 { AppFeedback.tap() }
                    }
            )
            .contextMenu {
                if canDelete {
                    Button(role: .destructive) {
                        AppFeedback.tap()
                        deleteAction()
                    } label: {
                        Label("删除新增食材", systemImage: "trash")
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
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
    var canDelete = false
    let action: () -> Void
    var deleteAction: () -> Void = {}

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
        .contextMenu {
            if canDelete {
                Button(role: .destructive) {
                    AppFeedback.tap()
                    deleteAction()
                } label: {
                    Label("删除新增分类", systemImage: "trash")
                }
            }
        }
    }
}
