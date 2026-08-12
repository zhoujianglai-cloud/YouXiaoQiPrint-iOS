import SwiftUI

struct PrinterView: View {
    @EnvironmentObject private var printer: BluetoothPrinterManager

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                HStack(spacing: 16) {
                    Image(systemName: printer.isConnected ? "checkmark.circle.fill" : "printer.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(printer.isConnected ? .green : AppTheme.accentBright)
                        .frame(width: 56, height: 56)
                        .background(AppTheme.chip, in: RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 5) {
                        Text(printer.statusText)
                            .font(.title3.bold())
                        Text("GP-M322 · BLE · TSPL")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    Spacer()
                    if printer.isSending { ProgressView() }
                }
                .padding(20)
                .background(AppTheme.surfaceRaised, in: RoundedRectangle(cornerRadius: 22))

                Button {
                    AppFeedback.tap()
                    if printer.isConnected { printer.disconnect() } else { printer.startScan() }
                } label: {
                    Label(
                        printer.isConnected ? "断开打印机" : "搜索打印机",
                        systemImage: printer.isConnected ? "link.badge.minus" : "antenna.radiowaves.left.and.right"
                    )
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(ResponsiveButtonStyle())

                VStack(alignment: .leading, spacing: 12) {
                    Text("附近设备")
                        .font(.title2.bold())

                    if printer.devices.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "dot.radiowaves.left.and.right")
                                .font(.largeTitle)
                                .foregroundStyle(AppTheme.accent)
                            Text("正在等待名称带 _BLE 的打印机")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18))
                    } else {
                        ForEach(printer.devices) { device in
                            Button {
                                AppFeedback.tap()
                                printer.connect(device)
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "printer")
                                        .font(.title3)
                                        .foregroundStyle(AppTheme.accent)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(device.name)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text("信号 \(device.rssi) dBm")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.secondaryText)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                                .padding(17)
                                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 17))
                            }
                            .buttonStyle(ResponsiveButtonStyle())
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 15) {
                    Text("使用提示")
                        .font(.title2.bold())
                    TipRow(icon: "iphone", text: "iPhone 不需要在系统蓝牙页面配对")
                    TipRow(icon: "bolt.horizontal.circle", text: "打开 App 后会自动连接 _BLE 设备")
                    TipRow(icon: "ruler", text: "标签规格：50 × 40 mm，间隙 1 mm")
                }
                .padding(20)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20))
            }
            .padding(18)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("打印机")
    }
}

private struct TipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 25)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}
