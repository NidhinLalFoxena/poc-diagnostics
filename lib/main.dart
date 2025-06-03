import 'dart:async';
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
  // Bluetooth plugin instance
  final _bluetoothClassicPlugin = BluetoothClassic();

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey();

  // State variables
  List<Device> devices = []; // List of discovered Bluetooth devices
  Device? connectedDevice; // Currently connected device
  bool isScanning = false; // Scanning state flag
  bool isConnecting = false; // Connecting state flag
  bool isConnected = false; // Connection state flag
  String receivedData = ''; // Data received from OBD adapter

  // Vehicle information map with default values
  Map<String, String> vehicleInfo = {
    'OBD Protocol': 'Unknown',
    'VIN': 'Unknown',
    'ECU Name': 'Unknown',
    'Adapter': 'Unknown',
    'Battery Voltage': 'Unknown',
    'Battery SOC': 'Unknown',
    'Battery Temp': 'Unknown',
    'Motor Temp': 'Unknown',
    'Throttle Position': 'Unknown',
    'Speed': 'Unknown',
    'Odometer': 'Unknown',
  };

  // Stream controllers for Bluetooth events
  StreamSubscription<Uint8List>? _dataSubscription; // For incoming data
  StreamSubscription<int>? _statusSubscription; // For connection status changes
  StreamSubscription<Device>? _scanSubscription; // For device discovery

  final TextEditingController _commandController =
      TextEditingController(); // For OBD commands
  final String obdUuid =
      "00001101-0000-1000-8000-00805f9b34fb"; // Standard OBD UUID

  @override
  void initState() {
    super.initState();
    initBluetooth(); // Initialize Bluetooth when widget is created
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
    final lines = data.split('\r'); // Split by carriage return
    final newInfo = <String, String>{}; // Temporary map for new info

    for (var line in lines) {
      line = line.trim(); // Clean up the line
      if (line.isEmpty) continue; // Skip empty lines

      // Parse protocol information (ATDPN command response)
      if (line.contains('ATDPN')) {
        final protocolMatch = RegExp(r'ATDPN\r?\n?(.+)').firstMatch(line);
        if (protocolMatch != null) {
          newInfo['OBD Protocol'] = protocolMatch.group(1)!.trim();
        }
      }
      // Parse VIN (0902 command response)
      else if (line.contains('49 02') || line.contains('4D 34')) {
        // Try to parse the VIN from hex data
        try {
          final hexParts = line.split(' ').where((p) => p.length == 2).toList();
          if (hexParts.length >= 6) {
            // Skip first 2 bytes (49 02 is the response header)
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
        continue;
      }
      // Parse battery voltage (ATRV command response)
      else if (line.contains('V') && line.length < 10) {
        newInfo['Battery Voltage'] = line;
      }
      // Parse battery state of charge (015B command response)
      else if (line.contains('41 5B')) {
        final socMatch = RegExp(r'41 5B ([0-9A-F]{2})').firstMatch(line);
        if (socMatch != null) {
          final soc = int.parse(socMatch.group(1)!, radix: 16);
          newInfo['Battery SOC'] = '$soc%';
        }
      }
      // Parse battery temperature (015C command response)
      else if (line.contains('41 5C')) {
        final tempMatch = RegExp(r'41 5C ([0-9A-F]{2})').firstMatch(line);
        if (tempMatch != null) {
          final temp = int.parse(tempMatch.group(1)!, radix: 16) - 40;
          newInfo['Battery Temp'] = '$temp°C';
        }
      }
      // Parse motor temperature (2211 command response)
      else if (line.contains('62 11')) {
        final tempMatch = RegExp(r'62 11 ([0-9A-F]{2})').firstMatch(line);
        if (tempMatch != null) {
          final temp = int.parse(tempMatch.group(1)!, radix: 16) - 40;
          newInfo['Motor Temp'] = '$temp°C';
        }
      }
      // Parse throttle position (0145 command response)
      else if (line.contains('41 45')) {
        final throttleMatch = RegExp(r'41 45 ([0-9A-F]{2})').firstMatch(line);
        if (throttleMatch != null) {
          final throttle =
              (int.parse(throttleMatch.group(1)!, radix: 16) * 100 / 255);
          newInfo['Throttle Position'] = '${throttle.toStringAsFixed(1)}%';
        }
      }
      // Parse speed (010D command response)
      else if (line.contains('41 0D')) {
        final speedMatch = RegExp(r'41 0D ([0-9A-F]{2})').firstMatch(line);
        if (speedMatch != null) {
          final speed = int.parse(speedMatch.group(1)!, radix: 16);
          newInfo['Speed'] = '$speed km/h';
        }
      }
      // Parse odometer (01A6 command response)
      else if (line.contains('41 A6')) {
        final odoMatch = RegExp(r'41 A6 ([0-9A-F ]+)').firstMatch(line);
        if (odoMatch != null) {
          final hexParts = odoMatch.group(1)!.split(' ');
          if (hexParts.length >= 3) {
            // Combine multiple bytes to get odometer value
            final odo = (int.parse(hexParts[0], radix: 16) << 16) +
                (int.parse(hexParts[1], radix: 16) << 8) +
                int.parse(hexParts[2], radix: 16);
            newInfo['Odometer'] = '$odo km';
          }
        }
      }
      // Parse ELM327 adapter version
      else if (line.startsWith('ELM327')) {
        newInfo['Adapter'] = line;
      }
      // Parse ECU name (long unformatted text)
      else if (line.length > 10 && !line.contains(' ') && !line.contains('>')) {
        newInfo['ECU Name'] = line;
      }
    }

    // Update vehicle info if new data was found
    if (newInfo.isNotEmpty) {
      setState(() => vehicleInfo.addAll(newInfo));
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
    // **YOU MUST RESEARCH THESE FOR YOUR SPECIFIC BIKE'S BRAND/MODEL.**
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
      devices = []; // Clear previous devices
    });

    // Listen for discovered devices
    _scanSubscription =
        _bluetoothClassicPlugin.onDeviceDiscovered().listen((device) {
      // Add device if not already in list
      if (!devices.any((d) => d.address == device.address)) {
        setState(() => devices.add(device));
      }
    });

    await _bluetoothClassicPlugin.startScan(); // Start scanning
    await Future.delayed(const Duration(seconds: 10)); // Scan for 10 seconds
    await _bluetoothClassicPlugin.stopScan(); // Stop scanning
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
      setState(() => connectedDevice = device);

      // Clear previous data
      setState(() => receivedData = '');

      // Initialize OBD adapter
      await sendCommand('ATZ'); // Reset
      await Future.delayed(const Duration(seconds: 1));
      await sendCommand('ATE0'); // Echo off
      await Future.delayed(const Duration(milliseconds: 300));

      // Get vehicle information
      await _getVehicleInfo();
    } on TimeoutException {
      _showSnackBar('Connection timed out');
    } finally {
      setState(() => isConnecting = false);
    }
  }

  // Disconnect from current device
  Future<void> disconnectDevice() async {
    await _bluetoothClassicPlugin.disconnect();
    setState(() {
      connectedDevice = null;
      isConnected = false;
      receivedData = '';
      vehicleInfo.clear();
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

    // Show status message to user
    final messages = {
      0: 'Device disconnected',
      1: 'Connecting to device...',
      2: 'Connected successfully',
    };
    _showSnackBar(messages[statusCode]!);
  }

  // Helper method to show snackbar messages
  void _showSnackBar(String message) {
    if (!mounted) return;
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    // Clean up resources when widget is disposed
    _dataSubscription?.cancel();
    _statusSubscription?.cancel();
    _scanSubscription?.cancel();
    _bluetoothClassicPlugin.disconnect();
    _commandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    log('receivedData : ${receivedData.toString()}');
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
                // Connected device info tile
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
                // Vehicle information card
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Vehicle Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                )),
                            const SizedBox(height: 8),
                            // System Information section
                            _buildInfoSection('System Information', {
                              'OBD Protocol': vehicleInfo['OBD Protocol']!,
                              'ECU Name': vehicleInfo['ECU Name']!,
                              'Adapter': vehicleInfo['Adapter']!,
                              'VIN': vehicleInfo['VIN']!,
                            }),
                            const Divider(height: 20),
                            // Battery Information section
                            _buildInfoSection('Battery', {
                              'Voltage': vehicleInfo['Battery Voltage']!,
                              'State of Charge': vehicleInfo['Battery SOC']!,
                              'Temperature': vehicleInfo['Battery Temp']!,
                            }),
                            const Divider(height: 20),
                            // Performance Information section
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
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Device list
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
              // OBD Terminal section (shown when connected)
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
                      child: Text(receivedData,
                          style: const TextStyle(fontFamily: 'Monospace')),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Command input row
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
              ],
            ],
          ),
        ),
        // Scan button (only shown when not connected)
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

  String getrecevedData(String receivedDatas) {
    return receivedDatas;
  }

  // Helper widget to build an information section
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

  // Helper widget to build an information row
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
