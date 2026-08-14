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

private struct AppGlassRoundedModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color?
    let interactive: Bool
    let fallback: Color

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if let tint {
                content.glassEffect(
                    .regular.tint(tint).interactive(interactive),
                    in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
            } else {
                content.glassEffect(
                    .regular.interactive(interactive),
                    in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
            }
        } else {
            content.background(fallback, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}

private struct AppGlassCapsuleModifier: ViewModifier {
    let tint: Color?
    let interactive: Bool
    let fallback: Color

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if let tint {
                content.glassEffect(.regular.tint(tint).interactive(interactive), in: Capsule())
            } else {
                content.glassEffect(.regular.interactive(interactive), in: Capsule())
            }
        } else {
            content.background(fallback, in: Capsule())
        }
    }
}

private struct AppGlassCircleModifier: ViewModifier {
    let tint: Color?
    let interactive: Bool
    let fallback: Color

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if let tint {
                content.glassEffect(.regular.tint(tint).interactive(interactive), in: Circle())
            } else {
                content.glassEffect(.regular.interactive(interactive), in: Circle())
            }
        } else {
            content.background(fallback, in: Circle())
        }
    }
}

extension View {
    func appGlassRounded(
        cornerRadius: CGFloat,
        tint: Color? = nil,
        interactive: Bool = false,
        fallback: Color = AppTheme.surface
    ) -> some View {
        modifier(AppGlassRoundedModifier(
            cornerRadius: cornerRadius,
            tint: tint,
            interactive: interactive,
            fallback: fallback
        ))
    }

    func appGlassCapsule(
        tint: Color? = nil,
        interactive: Bool = false,
        fallback: Color = AppTheme.surface
    ) -> some View {
        modifier(AppGlassCapsuleModifier(tint: tint, interactive: interactive, fallback: fallback))
    }

    func appGlassCircle(
        tint: Color? = nil,
        interactive: Bool = false,
        fallback: Color = AppTheme.surface
    ) -> some View {
        modifier(AppGlassCircleModifier(tint: tint, interactive: interactive, fallback: fallback))
    }
}

struct RootView: View {
    @State private var selection = 0

    init() {
        if #unavailable(iOS 26.0) {
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
    @State private var width = "50"
    @State private var height = "40"
    @State private var gap = "1"
    @State private var margin = "1.5"
    @State private var statusMessage: String?
    @State private var showingResetConfirmation = false

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
                    ParameterEditor(title: "宽度 mm", value: $width)
                    ParameterEditor(title: "高度 mm", value: $height)
                    ParameterEditor(title: "间隙 mm", value: $gap)
                    ParameterEditor(title: "左右边距 mm", value: $margin)
                }

                TextField("默认操作人（可留空）", text: $defaultOperator)
                    .font(.body)
                    .padding(18)
                    .appGlassRounded(cornerRadius: 16, interactive: true)
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
                .appGlassRounded(cornerRadius: 18, fallback: AppTheme.surface)

                VStack(spacing: 12) {
                    Button(action: saveParameters) {
                        Label("保存参数", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .appGlassRounded(cornerRadius: 16, tint: AppTheme.accent, interactive: true, fallback: AppTheme.accent)
                    }
                    .buttonStyle(ResponsiveButtonStyle())

                    Button(role: .destructive) {
                        AppFeedback.tap()
                        showingResetConfirmation = true
                    } label: {
                        Label("恢复默认", systemImage: "arrow.counterclockwise")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .appGlassRounded(cornerRadius: 16, tint: Color.red.opacity(0.16), interactive: true, fallback: Color.red.opacity(0.10))
                    }
                    .buttonStyle(ResponsiveButtonStyle())

                    if let statusMessage {
                        Label(statusMessage, systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding(20)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("设置")
        .onAppear(perform: loadParameters)
        .alert("恢复默认参数？", isPresented: $showingResetConfirmation) {
            Button("恢复默认", role: .destructive, action: resetParameters)
            Button("取消", role: .cancel) {}
        } message: {
            Text("宽度50 mm、高度40 mm、间隙1 mm、左右边距1.5 mm。")
        }
    }

    private func loadParameters() {
        width = display(LabelPrintSettings.width)
        height = display(LabelPrintSettings.height)
        gap = display(LabelPrintSettings.gap)
        margin = display(LabelPrintSettings.margin)
    }

    private func saveParameters() {
        guard let widthValue = number(width), (20...100).contains(widthValue),
              let heightValue = number(height), (20...100).contains(heightValue),
              let gapValue = number(gap), (0...10).contains(gapValue),
              let marginValue = number(margin), (0...10).contains(marginValue) else {
            statusMessage = "参数格式或范围不正确"
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        LabelPrintSettings.save(width: widthValue, height: heightValue, gap: gapValue, margin: marginValue)
        loadParameters()
        statusMessage = "参数已保存，下一次打印生效"
        AppFeedback.success()
    }

    private func resetParameters() {
        LabelPrintSettings.reset()
        loadParameters()
        statusMessage = "已恢复默认参数"
        AppFeedback.success()
    }

    private func number(_ text: String) -> Double? {
        Double(text.replacingOccurrences(of: ",", with: "."))
    }

    private func display(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(format: "%.1f", value)
    }
}

private struct ParameterEditor: View {
    let title: String
    @Binding var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
            TextField("0", text: $value)
                .font(.title2.weight(.medium))
                .keyboardType(.decimalPad)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .appGlassRounded(cornerRadius: 16, interactive: true)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.secondaryText.opacity(0.3), lineWidth: 1)
        }
    }
}
