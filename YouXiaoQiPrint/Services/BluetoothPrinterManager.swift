import CoreBluetooth
import Combine
import Foundation

struct DiscoveredPrinter: Identifiable {
    let id: UUID
    var name: String
    var rssi: Int
    fileprivate let peripheral: CBPeripheral
}

final class BluetoothPrinterManager: NSObject, ObservableObject {
    enum ConnectionState: Equatable {
        case bluetoothUnavailable
        case idle
        case scanning
        case connecting(String)
        case connected(String)
        case sending
        case failed(String)
    }

    @Published private(set) var devices: [DiscoveredPrinter] = []
    @Published private(set) var state: ConnectionState = .idle

    private static let serviceUUID = CBUUID(string: "49535343-FE7D-4AE5-8FA9-9FAFD205E455")
    private static let writeUUID = CBUUID(string: "49535343-8841-43F4-A8D4-ECBE34729BB3")
    private static let notifyUUID = CBUUID(string: "49535343-1E4D-4BD9-BA61-23C647249616")
    private static let savedPrinterKey = "savedAutoBLEPrinterIdentifier"

    private var central: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var outgoingChunks: [Data] = []
    private var waitingForWriteResponse = false
    private var userRequestedDisconnect = false

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    var isConnected: Bool {
        switch state {
        case .connected, .sending:
            return connectedPeripheral?.state == .connected && writeCharacteristic != nil
        default:
            return false
        }
    }

    var statusText: String {
        switch state {
        case .bluetoothUnavailable: return "请打开蓝牙"
        case .idle: return "未连接"
        case .scanning: return "正在搜索打印机…"
        case let .connecting(name): return "正在连接 \(name)…"
        case let .connected(name): return "已连接：\(name)"
        case .sending: return "正在发送打印数据…"
        case let .failed(message): return message
        }
    }

    var isSending: Bool {
        if case .sending = state { return true }
        return false
    }

    func startScan() {
        guard central.state == .poweredOn else {
            state = .bluetoothUnavailable
            return
        }
        userRequestedDisconnect = false
        devices = []
        state = .scanning
        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            guard let self, case .scanning = self.state else { return }
            self.stopScan()
        }
    }

    func autoConnect() {
        guard central.state == .poweredOn else { return }
        switch state {
        case .connecting, .connected, .sending:
            return
        default:
            break
        }

        userRequestedDisconnect = false
        if let saved = UserDefaults.standard.string(forKey: Self.savedPrinterKey),
           let identifier = UUID(uuidString: saved),
           let peripheral = central.retrievePeripherals(withIdentifiers: [identifier]).first {
            connect(DiscoveredPrinter(
                id: peripheral.identifier,
                name: peripheral.name ?? "GP-M322_BLE",
                rssi: 0,
                peripheral: peripheral
            ))
        } else {
            startScan()
        }
    }

    func stopScan() {
        central.stopScan()
        if case .scanning = state { state = .idle }
    }

    func connect(_ device: DiscoveredPrinter) {
        stopScan()
        if let current = connectedPeripheral, current.identifier != device.id {
            central.cancelPeripheralConnection(current)
        }
        connectedPeripheral = device.peripheral
        writeCharacteristic = nil
        device.peripheral.delegate = self
        state = .connecting(device.name)
        central.connect(device.peripheral)
    }

    func disconnect() {
        guard let peripheral = connectedPeripheral else { return }
        userRequestedDisconnect = true
        central.cancelPeripheralConnection(peripheral)
    }

    func print(material: Material, startDate: Date = Date()) {
        guard connectedPeripheral != nil, writeCharacteristic != nil else {
            state = .failed("请先连接打印机")
            return
        }
        enqueue(TSPLRenderer.fastPrintCommand(material: material, startDate: startDate))
    }

    private func enqueue(_ data: Data) {
        guard let peripheral = connectedPeripheral, let characteristic = writeCharacteristic else { return }
        // Acknowledged writes are safe to send at the negotiated CoreBluetooth
        // size. This greatly reduces round trips while still preventing the
        // dropped raster bytes seen with unacknowledged large bursts. For a
        // write-without-response-only channel, retain the printer SDK's 20-byte
        // packet size and let CoreBluetooth provide flow control.
        let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.write)
            ? .withResponse : .withoutResponse
        let maximumSize = peripheral.maximumWriteValueLength(for: writeType)
        let packetSize = writeType == .withResponse ? maximumSize : min(20, maximumSize)
        outgoingChunks = stride(from: 0, to: data.count, by: packetSize).map {
            data.subdata(in: $0..<min($0 + packetSize, data.count))
        }
        state = .sending
        drainQueue()
    }

    private func drainQueue() {
        guard let peripheral = connectedPeripheral, let characteristic = writeCharacteristic else { return }
        guard !outgoingChunks.isEmpty else {
            state = .connected(peripheral.name ?? "GP-M322")
            return
        }

        if characteristic.properties.contains(.write) {
            guard !waitingForWriteResponse else { return }
            waitingForWriteResponse = true
            peripheral.writeValue(outgoingChunks[0], for: characteristic, type: .withResponse)
        } else if characteristic.properties.contains(.writeWithoutResponse) {
            while peripheral.canSendWriteWithoutResponse, !outgoingChunks.isEmpty {
                let chunk = outgoingChunks.removeFirst()
                peripheral.writeValue(chunk, for: characteristic, type: .withoutResponse)
            }
            if outgoingChunks.isEmpty {
                state = .connected(peripheral.name ?? "GP-M322")
            }
        } else {
            state = .failed("打印机没有可写入的蓝牙通道")
        }
    }

    private func chooseWriteCharacteristic(_ characteristic: CBCharacteristic) {
        let canWrite = characteristic.properties.contains(.write)
            || characteristic.properties.contains(.writeWithoutResponse)
        guard canWrite else { return }
        if characteristic.uuid == Self.writeUUID || writeCharacteristic == nil {
            writeCharacteristic = characteristic
            if let peripheral = connectedPeripheral {
                state = .connected(peripheral.name ?? "GP-M322")
            }
        }
    }
}

extension BluetoothPrinterManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            state = .idle
            autoConnect()
        } else {
            state = .bluetoothUnavailable
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let advertisedName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let name = advertisedName ?? peripheral.name ?? "未知蓝牙设备"
        let upper = name.uppercased()
        guard upper.contains("GP") || upper.contains("M322") || upper.contains("PRINTER") || upper.contains("BLE") else {
            return
        }
        let item = DiscoveredPrinter(id: peripheral.identifier, name: name, rssi: RSSI.intValue, peripheral: peripheral)
        if let index = devices.firstIndex(where: { $0.id == item.id }) {
            devices[index] = item
        } else {
            devices.append(item)
            devices.sort { $0.rssi > $1.rssi }
        }
        if upper.hasSuffix("_BLE") {
            connect(item)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if (peripheral.name ?? "").uppercased().hasSuffix("_BLE") {
            UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: Self.savedPrinterKey)
        }
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        state = .failed(error?.localizedDescription ?? "连接失败")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedPeripheral = nil
        writeCharacteristic = nil
        outgoingChunks = []
        state = error.map { .failed($0.localizedDescription) } ?? .idle
        if !userRequestedDisconnect {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.autoConnect()
            }
        }
    }
}

extension BluetoothPrinterManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            state = .failed(error.localizedDescription)
            return
        }
        let services = peripheral.services ?? []
        let ordered = services.sorted {
            ($0.uuid == Self.serviceUUID ? 0 : 1) < ($1.uuid == Self.serviceUUID ? 0 : 1)
        }
        ordered.forEach { peripheral.discoverCharacteristics(nil, for: $0) }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            state = .failed(error.localizedDescription)
            return
        }
        for characteristic in service.characteristics ?? [] {
            chooseWriteCharacteristic(characteristic)
            if characteristic.uuid == Self.notifyUUID, characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        waitingForWriteResponse = false
        if let error {
            state = .failed(error.localizedDescription)
            outgoingChunks = []
            return
        }
        if !outgoingChunks.isEmpty { outgoingChunks.removeFirst() }
        drainQueue()
    }

    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        drainQueue()
    }
}
