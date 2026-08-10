import SwiftUI

@main
struct YouXiaoQiPrintApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = MaterialStore()
    @StateObject private var printer = BluetoothPrinterManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(printer)
                .onChange(of: scenePhase) { phase in
                    if phase == .active {
                        printer.autoConnect()
                    }
                }
        }
    }
}
