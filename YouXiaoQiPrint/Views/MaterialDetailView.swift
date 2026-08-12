import SwiftUI

struct MaterialDetailView: View {
    @EnvironmentObject private var store: MaterialStore
    @EnvironmentObject private var printer: BluetoothPrinterManager
    @Environment(\.dismiss) private var dismiss

    @State private var draft: Material
    @State private var startDate = Date()
    @State private var showingDelete = false
    @State private var actionMessage: String?

    init(material: Material) {
        _draft = State(initialValue: material)
    }

    var body: some View {
        Form {
            Section("产品") {
                TextField("产品名称", text: $draft.product)
                LabeledContent("岗位", value: draft.typeName)
                LabeledContent("类别", value: draft.cateName)
            }

            Section("储存方式") {
                Picker("储存方式", selection: storageBinding) {
                    ForEach(StorageType.allCases) { type in Text(type.title).tag(type) }
                }
                .pickerStyle(.segmented)

                Toggle("当天废弃", isOn: curDayBinding)
                if draft.curDay != 1 {
                    HStack {
                        Text("有效时长")
                        Spacer()
                        TextField("小时", value: durationBinding, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("小时").foregroundStyle(.secondary)
                    }
                }
                TextField("备注", text: $draft.remarks, axis: .vertical)
            }

            Section("标签预览") {
                DatePicker("开始时间", selection: $startDate)
                Image(uiImage: TSPLRenderer.labelImage(material: draft, startDate: startDate))
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .background(.white)
                    .overlay { Rectangle().stroke(.black, lineWidth: 1) }
                    .padding(.vertical, 6)
            }

            Section {
                Button {
                    store.update(draft)
                    AppFeedback.success()
                    showMessage("修改已保存")
                } label: {
                    Label("保存修改", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }

                Button {
                    AppFeedback.tap()
                    store.update(draft)
                    printer.print(material: draft, startDate: startDate)
                    showMessage("打印指令已发送")
                } label: {
                    HStack {
                        if printer.isSending { ProgressView() }
                        Label(
                            printer.isSending ? "正在发送…" : (printer.isConnected ? "打印" : "连接打印机后打印"),
                            systemImage: "printer"
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(!printer.isConnected)

                if store.canDelete(draft) {
                    Button("删除产品", role: .destructive) {
                        AppFeedback.tap()
                        showingDelete = true
                    }
                        .frame(maxWidth: .infinity)
                }
            }

            if let actionMessage {
                Section {
                    Label(actionMessage, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .navigationTitle(draft.product)
        .navigationBarTitleDisplayMode(.inline)
        .alert("是否删除该产品？", isPresented: $showingDelete) {
            Button("删除", role: .destructive) {
                store.delete(draft)
                dismiss()
            }
            Button("取消", role: .cancel) {}
        }
    }

    private func showMessage(_ message: String) {
        actionMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if actionMessage == message { actionMessage = nil }
        }
    }

    private var storageBinding: Binding<StorageType> {
        Binding(get: { draft.storage }, set: { draft.storage = $0 })
    }

    private var curDayBinding: Binding<Bool> {
        Binding(get: { draft.curDay == 1 }, set: { draft.curDay = $0 ? 1 : 0 })
    }

    private var durationBinding: Binding<Int> {
        Binding(
            get: { draft.durationHours },
            set: { value in
                let hours = max(0, value)
                switch draft.storage {
                case .refrigerated: draft.refrigerationTime = hours
                case .frozen: draft.freezingTime = hours
                case .roomTemperature: draft.normalTemperatureTime = hours
                }
            }
        )
    }
}
