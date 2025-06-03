import 'dart:async';
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

  // State variables
  List<Device> devices = []; // List of discovered Bluetooth devices
  Device? connectedDevice; // Currently connected device
  bool isScanning = false; // Scanning state flag
  bool isConnecting = false; // Connecting state flag
  bool isConnected = false; // Connection state flag
  String receivedData = ''; // Data received from OBD adapter

  // Vehicle information
  Map<String, String> vehicleInfo = {
    'OBD Protocol': 'Unknown',
    'VIN': 'Unknown',
    'ECU Name': 'Unknown',
    'Adapter': 'Unknown',
    'Battery Voltage': '0V',
    'Battery SOC': '0%',
    'Battery Temp': '0°C',
    'Motor Temp': '0°C',
    'Throttle Position': '0%',
    'Speed': '0 km/h',
    'Odometer': '0 km',
  };

  // Real-time streaming
  Timer? _pollingTimer;
  final Map<String, String> _streamingPids = {
    'speed': '010D', // Vehicle speed
    'throttle': '0145', // Throttle position
    'voltage': 'ATRV', // Battery voltage
    'soc': '015B', // State of charge
    'motorTemp': '2211', // Motor temperature
  };

  // Stream subscriptions
  StreamSubscription<Uint8List>? _dataSubscription; // For incoming data
  StreamSubscription<int>? _statusSubscription; // For connection status changes
  StreamSubscription<Device>? _scanSubscription; // For device discover

  final TextEditingController _commandController =
      TextEditingController(); // For OBD commands
  final String obdUuid =
      "00001101-0000-1000-8000-00805f9b34fb"; // Standard OBD UUID

  @override
  void initState() {
    super.initState();
    initBluetooth();
  }

  // Initialize Bluetooth functionality
  Future<void> initBluetooth() async {
    await _bluetoothClassicPlugin.initPermissions(); // Request permissions
    await getPairedDevices(); // Get already paired devices

    // Listen for incoming data from OBD adapter
    _dataSubscription =
        _bluetoothClassicPlugin.onDeviceDataReceived().listen((data) {
      final newData = String.fromCharCodes(data); // Convert bytes to string
      setState(() => receivedData += newData); // Append to received data
      _parseVehicleInfo(newData); // Parse for vehicle information
    });

    // Listen for connection status changes
    _statusSubscription = _bluetoothClassicPlugin
        .onDeviceStatusChanged()
        .listen(_handleStatusChange);
  }

  // Parse received data for vehicle information
  void _parseVehicleInfo(String data) {
    final lines = data.split('\r');
    final newInfo = <String, String>{};

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // --- Protocol Information ---
      if (line.contains('ATDPN')) {
        final protocolMatch = RegExp(r'ATDPN\r?\n?(.+)').firstMatch(line);
        if (protocolMatch != null) {
          newInfo['OBD Protocol'] = protocolMatch.group(1)!.trim();
        }
      }
      // --- Adapter Information ---
      else if (line.startsWith('ELM327')) {
        newInfo['Adapter'] = line;
      }
      // --- VIN (Vehicle Identification Number) ---
      else if (line.contains('49 02') || line.contains('4D 34')) {
        try {
          final hexParts = line.split(' ').where((p) => p.length == 2).toList();
          if (hexParts.length >= 6) {
            final vinHex = hexParts.skip(2).take(17).join('');
            String vin = '';
            for (int i = 0; i < vinHex.length; i += 2) {
              final hex = vinHex.substring(i, i + 2);
              vin += String.fromCharCode(int.parse(hex, radix: 16));
            }
            newInfo['VIN'] = vin.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
          }
        } catch (e) {
          newInfo['VIN'] = 'Unable to decode';
        }
      }
      // --- ECU Name ---
      else if (line.length > 10 && !line.contains(' ') && !line.contains('>')) {
        newInfo['ECU Name'] = line;
      }
      // --- Real-Time Data ---
      // Speed (010D)
      else if (line.contains('41 0D')) {
        final speedMatch = RegExp(r'41 0D ([0-9A-F]{2})').firstMatch(line);
        if (speedMatch != null) {
          final speed = int.parse(speedMatch.group(1)!, radix: 16);
          newInfo['Speed'] = '$speed km/h';
        }
      }
      // Throttle Position (0145)
      else if (line.contains('41 45')) {
        final throttleMatch = RegExp(r'41 45 ([0-9A-F]{2})').firstMatch(line);
        if (throttleMatch != null) {
          final throttle =
              (int.parse(throttleMatch.group(1)!, radix: 16) * 100 / 255);
          newInfo['Throttle Position'] = '${throttle.toStringAsFixed(1)}%';
        }
      }
      // Battery Voltage (ATRV)
      else if (line.contains('V') && line.length < 10) {
        newInfo['Battery Voltage'] = line;
      }
      // Battery State of Charge (015B)
      else if (line.contains('41 5B')) {
        final socMatch = RegExp(r'41 5B ([0-9A-F]{2})').firstMatch(line);
        if (socMatch != null) {
          final soc = int.parse(socMatch.group(1)!, radix: 16);
          newInfo['Battery SOC'] = '$soc%';
        }
      }
      // Battery Temperature (015C)
      else if (line.contains('41 5C')) {
        final tempMatch = RegExp(r'41 5C ([0-9A-F]{2})').firstMatch(line);
        if (tempMatch != null) {
          final temp = int.parse(tempMatch.group(1)!, radix: 16) - 40;
          newInfo['Battery Temp'] = '$temp°C';
        }
      }
      // Motor Temperature (2211)
      else if (line.contains('62 11')) {
        final tempMatch = RegExp(r'62 11 ([0-9A-F]{2})').firstMatch(line);
        if (tempMatch != null) {
          final temp = int.parse(tempMatch.group(1)!, radix: 16) - 40;
          newInfo['Motor Temp'] = '$temp°C';
        }
      }
      // Odometer (01A6)
      else if (line.contains('41 A6')) {
        final odoMatch = RegExp(r'41 A6 ([0-9A-F ]+)').firstMatch(line);
        if (odoMatch != null) {
          final hexParts = odoMatch.group(1)!.split(' ');
          if (hexParts.length >= 3) {
            final odo = (int.parse(hexParts[0], radix: 16) << 16) +
                (int.parse(hexParts[1], radix: 16) << 8) +
                int.parse(hexParts[2], radix: 16);
            newInfo['Odometer'] = '$odo km';
          }
        }
      }
    }

    if (newInfo.isNotEmpty) {
      setState(() => vehicleInfo.addAll(newInfo));
    }
  }

  /// Starts or stops real-time streaming of vehicle data.
  ///
  /// When [enable] is true, this function starts a timer that sends a command
  /// to the vehicle every 500 milliseconds. The command is chosen from the
  /// list of streaming PIDs in [_streamingPids] by wrapping around the list
  /// with each timer tick. When [enable] is false, the timer is stopped and
  /// any pending timer is cancelled.
  void _toggleRealTimeStreaming(bool enable) {
    if (enable) {
      _pollingTimer =
          Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (isConnected) {
          final pidIndex = timer.tick % _streamingPids.length;
          final pid = _streamingPids.values.elementAt(pidIndex);
          sendCommand(pid);
        }
      });
    } else {
      _pollingTimer?.cancel();
      _pollingTimer = null;
    }
  }

  // Send a series of OBD commands to get vehicle information
  Future<void> _getVehicleInfo() async {
    setState(() {
      // Reset all values to "Detecting..." while we query
      vehicleInfo =
          vehicleInfo.map((key, value) => MapEntry(key, 'Detecting...'));
    });

    // --- ELM327 Adapter Initialization ---
    // Reset the adapter
    await sendCommand('ATZ');
    await Future.delayed(const Duration(milliseconds: 500));

    // Turn off echo for cleaner responses (removes the command from the received data)
    await sendCommand('ATE0');
    await Future.delayed(const Duration(milliseconds: 300));

    // Turn off linefeeds
    await sendCommand('ATL0');
    await Future.delayed(const Duration(milliseconds: 300));

    // Set header off (for cleaner PID responses)
    await sendCommand('ATH0');
    await Future.delayed(const Duration(milliseconds: 300));

    // Set protocol to automatic detection (important for diverse vehicles)
    // This allows the ELM327 to try different protocols until it connects.
    await sendCommand('ATSP0');
    await Future.delayed(const Duration(milliseconds: 300));

    // Adapter identification (e.g., ELM327 v1.5)
    await sendCommand('ATI');
    await Future.delayed(const Duration(milliseconds: 300));

    // Get protocol information (ATDPN command)
    await sendCommand('ATDPN');
    await Future.delayed(const Duration(milliseconds: 300));

    // --- Standard OBD2 PIDs (may or may not work on electric bikes) ---

    // VIN (Vehicle Identification Number) - Mode 09, PID 02
    // Some electric bikes might implement this.
    await sendCommand('0902');
    await Future.delayed(const Duration(milliseconds: 700));

    // Battery voltage at the ELM327 (helpful for power supply)
    await sendCommand('ATRV');
    await Future.delayed(const Duration(milliseconds: 300));

    // --- Electric Bike Specific / Common EV PIDs (often proprietary, but some are semi-standard) ---

    // Battery State of Charge (SOC) - Mode 01, PID 5B (often used for EVs)
    await sendCommand('015B');
    await Future.delayed(const Duration(milliseconds: 300));

    // Battery Temperature - Mode 01, PID 5C (often used for EVs)
    await sendCommand('015C');
    await Future.delayed(const Duration(milliseconds: 300));

    // Throttle Position (Mode 01, PID 45)
    await sendCommand('0145');
    await Future.delayed(const Duration(milliseconds: 300));

    // Vehicle Speed (Mode 01, PID 0D)
    await sendCommand('010D');
    await Future.delayed(const Duration(milliseconds: 300));

    // Odometer (Mode 01, PID A6) - Less common for general OBD2, but some vehicles might have it.
    await sendCommand('01A6');
    await Future.delayed(const Duration(milliseconds: 500));

    // --- Manufacturer-Specific PIDs (CRITICAL for electric bikes) proprietary (manufacturer-specific) PIDs (Parameter IDs)  ---
    // These are the most important for detailed electric bike data.
    // **WE MUST RESEARCH THESE FOR YOUR SPECIFIC BIKE'S BRAND/MODEL.**
    // They typically fall into Mode 21, Mode 22, Mode 23, etc., or proprietary modes.

    // Example: Reading a proprietary PID for Motor Temperature (Mode 22, PID 11)
    // This is a placeholder. '2211' is a common starting point for manufacturer-specific PIDs.
    // The actual PID, scaling, and interpretation will be in your bike's service manual or community forums.
    await sendCommand('2211'); // Example for Motor Temperature
    await Future.delayed(const Duration(milliseconds: 300));

    // Example: Another proprietary PID for custom battery health data
    // This could be any 4-digit hex code, e.g., '22F0', '22A0', '21B5', etc.
    // await sendCommand('22F0'); // Placeholder for another custom EV parameter
    // await Future.delayed(const Duration(milliseconds: 300));

    // Example: Requesting a "current data list" or "all PIDs" from a specific ECU (if supported)
    // This varies wildly and might involve "tester present" messages (0x3E) or specific session changes (0x10, 0x01).
    // This is advanced and not typically handled by simple `sendCommand`.

    // --- ECU Name / Manufacturer Identification ---
    // This is often not directly available via a simple OBD2 PID.
    // Sometimes the VIN will contain manufacturer info.
    // Other times, it might be a response to a proprietary "identification" command.
    // The current parsing for `ECU Name` is a heuristic;
    // a specific command like 'ATSH' (Set Header) followed by a manufacturer-specific
    // diagnostic session command might be needed to query deeper.

    // If you find specific manufacturer commands, add them here.
  }

  // Get list of paired Bluetooth devices
  Future<void> getPairedDevices() async {
    List<Device> discoveredDevices =
        await _bluetoothClassicPlugin.getPairedDevices();
    setState(() => devices = discoveredDevices);
  }

  // Scan for nearby Bluetooth devices
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

  // Connect to a specific Bluetooth device
  Future<void> connectToDevice(Device device) async {
    setState(() => isConnecting = true);
    try {
      // Attempt connection with timeout
      await _bluetoothClassicPlugin
          .connect(device.address, obdUuid)
          .timeout(const Duration(seconds: 15));

      // Clear previous data
      setState(() {
        connectedDevice = device;
        receivedData = '';
      });

      // Initialize OBD adapter
      await sendCommand('ATZ'); // Reset
      await Future.delayed(const Duration(seconds: 1));
      await sendCommand('ATE0'); // Echo off
      await Future.delayed(const Duration(milliseconds: 300));
      await sendCommand('ATH0');

      // Start real-time streaming
      _toggleRealTimeStreaming(true);

      // Get vehicle info
      await _getVehicleInfo();
    } on TimeoutException {
      _showSnackBar('Connection timed out');
    } finally {
      setState(() => isConnecting = false);
    }
  }

  // Disconnect from current device
  Future<void> disconnectDevice() async {
    _toggleRealTimeStreaming(false);
    await _bluetoothClassicPlugin.disconnect();
    setState(() {
      connectedDevice = null;
      isConnected = false;
      receivedData = '';
      vehicleInfo.updateAll((key, value) => key.endsWith('Temp') ||
              key.endsWith('SOC') ||
              key.endsWith('Voltage') ||
              key.endsWith('Position') ||
              key == 'Speed'
          ? '0'
          : 'Unknown');
    });
  }

  // Send an OBD command to the connected device
  Future<void> sendCommand(String command) async {
    if (command.isEmpty) return;
    await _bluetoothClassicPlugin
        .write('$command\r'); // Send with carriage return
    _commandController.clear();
  }

  // Handle Bluetooth connection status changes
  void _handleStatusChange(int statusCode) {
    setState(() {
      switch (statusCode) {
        case 0: // Disconnected
          isConnected = false;
          isConnecting = false;
          _toggleRealTimeStreaming(false);
          break;
        case 1: // Connecting
          isConnecting = true;
          break;
        case 2: // Connected
          isConnected = true;
          isConnecting = false;
          break;
      }
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
    _pollingTimer?.cancel();
    _bluetoothClassicPlugin.disconnect();
    _commandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('OBD2 Bike Monitor'),
          actions: [
            if (isConnected) ...[
              IconButton(
                icon:
                    const Icon(Icons.bluetooth_connected, color: Colors.green),
                onPressed: disconnectDevice,
              ),
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Icon(Icons.circle, color: Colors.green, size: 12),
              ),
            ],
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (connectedDevice != null) ...[
                _buildRealtimeDisplay(),
                ListTile(
                  leading: const Icon(Icons.bluetooth),
                  title:
                      Text('Connected: ${connectedDevice!.name ?? 'Unknown'}'),
                  subtitle: Text(connectedDevice!.address),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _getVehicleInfo,
                  ),
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildInfoSection('System Information', {
                          'OBD Protocol': vehicleInfo['OBD Protocol']!,
                          'ECU Name': vehicleInfo['ECU Name']!,
                          'Adapter': vehicleInfo['Adapter']!,
                          'VIN': vehicleInfo['VIN']!,
                        }),
                        const Divider(height: 20),
                        _buildInfoSection('Battery', {
                          'Voltage': vehicleInfo['Battery Voltage']!,
                          'State of Charge': vehicleInfo['Battery SOC']!,
                          'Temperature': vehicleInfo['Battery Temp']!,
                        }),
                        const Divider(height: 20),
                        _buildInfoSection('Performance', {
                          'Motor Temp': vehicleInfo['Motor Temp']!,
                          'Throttle Position':
                              vehicleInfo['Throttle Position']!,
                          'Speed': vehicleInfo['Speed']!,
                          'Odometer': vehicleInfo['Odometer']!,
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                      child: Text(receivedData,
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
                        onSubmitted: sendCommand,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () => sendCommand(_commandController.text),
                    ),
                  ],
                ),
              ] else ...[
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

  Widget _buildRealtimeDisplay() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 20,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricTile('Speed', vehicleInfo['Speed']!, Icons.speed),
              _buildMetricTile(
                  'Throttle', vehicleInfo['Throttle Position']!, Icons.speed),
              _buildMetricTile(
                  'Battery', vehicleInfo['Battery SOC']!, Icons.battery_full),
              _buildMetricTile(
                  'Voltage', vehicleInfo['Battery Voltage']!, Icons.flash_on),
              _buildMetricTile(
                  'Motor', vehicleInfo['Motor Temp']!, Icons.thermostat),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 12)),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInfoSection(String title, Map<String, String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...items.entries.map((entry) => _buildInfoRow(entry.key, entry.value)),
      ],
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
