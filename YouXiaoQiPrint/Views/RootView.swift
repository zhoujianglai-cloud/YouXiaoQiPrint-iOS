import SwiftUI
import UIKit

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
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.65 : 1)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

struct RootView: View {
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack { MaterialListView() }
                .tabItem { Label("模版", systemImage: "square.grid.2x2") }
                .tag(0)

            NavigationStack { MaterialSearchView() }
                .tabItem { Label("搜索", systemImage: "magnifyingglass") }
                .tag(1)

            NavigationStack { PrinterView() }
                .tabItem { Label("打印机", systemImage: "printer") }
                .tag(2)
        }
        .tint(.orange)
        .onChange(of: selection) { _ in AppFeedback.tap() }
    }
}
