import SwiftUI

struct PrinterView: View {
    @EnvironmentObject private var printer: BluetoothPrinterManager

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: printer.isConnected ? "checkmark.circle.fill" : "printer")
                        .font(.title2)
                        .foregroundStyle(printer.isConnected ? .green : .orange)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(printer.statusText).font(.headline)
                        Text("GP-M322 · BLE · TSPL")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if printer.isConnected {
                    Button("断开连接", role: .destructive) {
                        AppFeedback.tap()
                        printer.disconnect()
                    }
                    .buttonStyle(ResponsiveButtonStyle())
                } else {
                    Button {
                        AppFeedback.tap()
                        printer.startScan()
                    } label: {
                        Label("搜索打印机", systemImage: "antenna.radiowaves.left.and.right")
                    }
                    .buttonStyle(ResponsiveButtonStyle())
                }
            }

            Section("附近设备") {
                if printer.devices.isEmpty {
                    Text("请打开 GP-M322，点击“搜索打印机”，选择名称带 _BLE 或 _IOS 的设备。")
                        .foregroundStyle(.secondary)
                }
                ForEach(printer.devices) { device in
                    Button {
                        AppFeedback.tap()
                        printer.connect(device)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(device.name).foregroundStyle(.primary)
                                Text(device.id.uuidString).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(device.rssi) dBm").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(ResponsiveButtonStyle())
                }
            }

            Section("使用提示") {
                Label("iPhone 不需要在系统蓝牙页面配对", systemImage: "iphone")
                Label("优先选择名称带 _BLE 或 _IOS 的打印机", systemImage: "checkmark.seal")
                Label("标签规格：50 × 40 mm，间隙 1 mm", systemImage: "ruler")
            }
            .font(.subheadline)
        }
        .navigationTitle("打印机")
    }
}
