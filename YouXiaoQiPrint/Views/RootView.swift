import SwiftUI
import UIKit

enum AppTheme {
    static let accent = Color(red: 0.63, green: 0.10, blue: 0.12)
    static let accentBright = Color(red: 0.91, green: 0.28, blue: 0.20)
    static let background = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.07, green: 0.045, blue: 0.07, alpha: 1)
            : UIColor(red: 0.985, green: 0.965, blue: 0.96, alpha: 1)
    })
    static let surface = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.20, green: 0.13, blue: 0.12, alpha: 1)
            : UIColor.white
    })
    static let surfaceRaised = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.25, green: 0.16, blue: 0.14, alpha: 1)
            : UIColor(red: 1, green: 0.99, blue: 0.985, alpha: 1)
    })
    static let chip = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.31, green: 0.27, blue: 0.36, alpha: 1)
            : UIColor(red: 0.94, green: 0.91, blue: 0.94, alpha: 1)
    })
    static let secondaryText = Color(uiColor: .secondaryLabel)
}

enum AppFeedback {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

struct ResponsiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

struct RootView: View {
    @State private var selection = 0

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.16, green: 0.10, blue: 0.10, alpha: 1)
                : UIColor(red: 1, green: 0.97, blue: 0.965, alpha: 1)
        }
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack { MaterialListView() }
                .tabItem { Label("食材", systemImage: "square.grid.2x2.fill") }
                .tag(0)

            NavigationStack { MaterialSearchView() }
                .tabItem { Label("搜索", systemImage: "magnifyingglass") }
                .tag(1)

            NavigationStack { PrinterView() }
                .tabItem { Label("打印机", systemImage: "printer.fill") }
                .tag(2)

            NavigationStack { SettingsView() }
                .tabItem { Label("设置", systemImage: "slider.horizontal.3") }
                .tag(3)
        }
        .tint(AppTheme.accent)
        .onChange(of: selection) { _ in AppFeedback.tap() }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: MaterialStore
    @AppStorage("defaultOperator") private var defaultOperator = ""

    private var previewMaterial: Material? {
        store.materials.first(where: { $0.product == "茉莉茶叶" }) ?? store.materials.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("标签参数")
                        .font(.title2.bold())
                    Text("GP-M322 默认：203 DPI、50 × 40 mm。参数保存在本机。")
                        .foregroundStyle(AppTheme.secondaryText)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ParameterTile(title: "宽度 mm", value: "50")
                    ParameterTile(title: "高度 mm", value: "40")
                    ParameterTile(title: "间隙 mm", value: "1")
                    ParameterTile(title: "左右边距 mm", value: "1.5")
                }

                TextField("默认操作人（可留空）", text: $defaultOperator)
                    .font(.body)
                    .padding(18)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.secondaryText.opacity(0.35), lineWidth: 1)
                    }

                if let material = previewMaterial {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("标签预览")
                            .font(.title2.bold())
                        Image(uiImage: TSPLRenderer.labelImage(material: material, startDate: Date()))
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.08), radius: 12, y: 5)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("美优乐有效期打印", systemImage: "app.badge.fill")
                        .font(.headline)
                    Text("自动连接 GP-M322_BLE · 50 × 40 mm 标签")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18))
            }
            .padding(20)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("设置")
    }
}

private struct ParameterTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
            Text(value)
                .font(.title2.weight(.medium))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.secondaryText.opacity(0.3), lineWidth: 1)
        }
    }
}
