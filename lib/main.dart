import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:bluetooth_classic/models/device.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final _bluetoothClassicPlugin = BluetoothClassic();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey();

  List<Device> devices = [];
  Device? connectedDevice;
  bool isScanning = false;
  bool isConnecting = false;
  bool isConnected = false;
  String terminalData = '';
  String terminalList = '';

  String _responseBuffer = '';
  Timer? _responseTimer;
  final _responseTimeout =
      const Duration(milliseconds: 300); // Adjust as needed
  bool _awaitingResponse = false;

  Map<String, String> vehicleInfo = {
    'VIN': 'Unknown',
  };

  StreamSubscription<Uint8List>? _dataSubscription;
  StreamSubscription<int>? _statusSubscription;
  StreamSubscription<Device>? _scanSubscription;
  String vinBuffer = '';

  final TextEditingController _commandController = TextEditingController();
  final String obdUuid = "00001101-0000-1000-8000-00805f9b34fb";

  @override
  void initState() {
    super.initState();
    initBluetooth();
  }

  Future<void> initBluetooth() async {
    await _bluetoothClassicPlugin.initPermissions();
    await getPairedDevices();

    _dataSubscription =
        _bluetoothClassicPlugin.onDeviceDataReceived().listen((data) {
      final newData = String.fromCharCodes(data);
      log('===> Raw Data: ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
      log('===> New Data: $newData');

      setState(() {
        terminalData += newData;
        terminalList += data.toString();
      });

      // Add to buffer and reset timer
      _responseBuffer += newData;
      _responseTimer?.cancel();

      // Check for termination conditions
      if (_responseBuffer.contains('>') ||
          _responseBuffer.contains('NO DATA') ||
          _responseBuffer.contains('ERROR') ||
          _responseBuffer.contains('?')) {
        log('===> Response Buffer: $_responseBuffer');
        _processResponse();
      } else {
        _responseTimer = Timer(_responseTimeout, _processResponse);
      }
    });

    _statusSubscription = _bluetoothClassicPlugin
        .onDeviceStatusChanged()
        .listen(_handleStatusChange);
  }

  void _processResponse() {
    _responseTimer?.cancel();
    if (_responseBuffer.isEmpty) return;

    log('Processing complete response: $_responseBuffer');

    // Handle VIN response specifically
    if (_awaitingResponse && _responseBuffer.contains('49 02')) {
      log('===> Response Buffer: $_responseBuffer. $_awaitingResponse');

      final vin = _parseVIN(_responseBuffer);
      log('===> Response Buffer: $vin');

      if (vin != null) {
        setState(() => vehicleInfo['VIN'] = vin);
      }
    }

    // Clear the buffer for next command
    _responseBuffer = '';
    _awaitingResponse = false;
  }

  Future<void> _getVehicleInfo() async {
    setState(() {
      vehicleInfo['VIN'] = 'Detecting...';
    });

    // Clear any previous response data
    _responseBuffer = '';

    await sendCommand('0902');
  }

  String? _parseVIN(String rawData) {
    try {
      final lines = rawData.split('\r');
      final vinLines = lines.where((line) => line.contains(':')).toList();
      final hexBytes = <String>[];

      for (final line in vinLines) {
        final parts = line.split(' ');
        hexBytes.addAll(parts.where((part) =>
            part.length == 2 && int.tryParse(part, radix: 16) != null));
      }

      final startIndex = hexBytes.indexOf('49') + 2;
      if (startIndex < 2 || startIndex >= hexBytes.length) return null;

      final vinBytes =
          hexBytes.skip(startIndex).takeWhile((byte) => byte != '00').toList();

      return vinBytes
          .map((hex) => String.fromCharCode(int.parse(hex, radix: 16)))
          .join();
    } catch (e) {
      debugPrint('Error parsing VIN: $e');
      return null;
    }
  }

  Future<void> getPairedDevices() async {
    List<Device> discoveredDevices =
        await _bluetoothClassicPlugin.getPairedDevices();
    setState(() => devices = discoveredDevices);
  }

  Future<void> scanDevices() async {
    setState(() {
      isScanning = true;
      devices = [];
    });

    _scanSubscription =
        _bluetoothClassicPlugin.onDeviceDiscovered().listen((device) {
      if (!devices.any((d) => d.address == device.address)) {
        setState(() => devices.add(device));
      }
    });

    await _bluetoothClassicPlugin.startScan();
    await Future.delayed(const Duration(seconds: 10));
    await _bluetoothClassicPlugin.stopScan();
    setState(() => isScanning = false);
  }

  Future<void> connectToDevice(Device device) async {
    setState(() => isConnecting = true);
    try {
      await _bluetoothClassicPlugin
          .connect(device.address, obdUuid)
          .timeout(const Duration(seconds: 15));
      setState(() => connectedDevice = device);
      await Future.delayed(const Duration(milliseconds: 300));
      await _getVehicleInfo();
    } on TimeoutException {
      _showSnackBar('Connection timed out');
    } finally {
      setState(() => isConnecting = false);
    }
  }

  Future<void> disconnectDevice() async {
    await _bluetoothClassicPlugin.disconnect();
    setState(() {
      connectedDevice = null;
      isConnected = false;
      terminalData = '';
      vehicleInfo['VIN'] = 'Unknown';
    });
  }

  Future<void> sendCommand(String command) async {
    if (command.isEmpty) return;

    // Clear previous buffer and set awaiting flag
    _responseBuffer = '';
    _awaitingResponse = true;

    await _bluetoothClassicPlugin.write('$command\r');
    _commandController.clear();

    log('Sent command: $command');
  }

  void _handleStatusChange(int statusCode) {
    setState(() {
      isConnected = statusCode == 2;
      isConnecting = statusCode == 1;
    });

    final messages = {
      0: 'Device disconnected',
      1: 'Connecting to device...',
      2: 'Connected successfully',
    };
    _showSnackBar(messages[statusCode]!);
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    _statusSubscription?.cancel();
    _scanSubscription?.cancel();
    _bluetoothClassicPlugin.disconnect();
    _commandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    log('===> Terminal ${terminalList}');
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('OBD2 Vehicle Info'),
          actions: [
            if (isConnected)
              IconButton(
                icon:
                    const Icon(Icons.bluetooth_connected, color: Colors.green),
                onPressed: disconnectDevice,
                tooltip: 'Disconnect',
              )
            else if (isConnecting)
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (connectedDevice != null) ...[
                ListTile(
                  leading: const Icon(Icons.bluetooth),
                  title:
                      Text('Connected: ${connectedDevice!.name ?? 'Unknown'}'),
                  subtitle: Text(connectedDevice!.address),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _getVehicleInfo,
                    tooltip: 'Refresh data',
                  ),
                ),
                const Divider(),
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        const Text('Vehicle Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            )),
                        const SizedBox(height: 8),
                        _buildInfoRow('VIN', vehicleInfo['VIN']!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Expanded(
                child: ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return ListTile(
                      leading: const Icon(Icons.devices),
                      title: Text(device.name ?? 'Unknown'),
                      subtitle: Text(device.address),
                      trailing: IconButton(
                        icon: const Icon(Icons.bluetooth),
                        onPressed: () => connectToDevice(device),
                      ),
                    );
                  },
                ),
              ),
              if (isConnected) ...[
                const Divider(),
                const Text('OBD Terminal',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: SingleChildScrollView(
                      reverse: true,
                      child: Text(terminalList,
                          style: const TextStyle(fontFamily: 'Monospace')),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commandController,
                        decoration: const InputDecoration(
                          hintText: 'Enter OBD command (e.g., ATZ, 0100)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () => sendCommand(_commandController.text),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        floatingActionButton: !isConnected
            ? FloatingActionButton(
                onPressed: isScanning ? null : scanDevices,
                tooltip: 'Scan for devices',
                child: isScanning
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.white))
                    : const Icon(Icons.search),
              )
            : null,
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$title:',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: value == 'Unknown' || value == 'Detecting...'
                        ? Colors.grey
                        : null)),
          ),
        ],
      ),
    );
  }
}
