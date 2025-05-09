import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleUartPage extends StatefulWidget {
  const BleUartPage({super.key});

  @override
  State<BleUartPage> createState() => _BleUartPageState();
}

class _BleUartPageState extends State<BleUartPage> {
  final FlutterBluePlus flutterBlue = FlutterBluePlus();
  ScanResult? selectedResult;
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? txCharacteristic;
  String status = 'Idle';
  String receivedData = '';

  static const String serviceUuid = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
  static const String txUuid = '6E400003-B5A3-F393-E0A9-E50E24DCCA9E';

  void startScan() {
    setState(() {
      status = 'Scanning…';
      selectedResult = null;
      connectedDevice = null;
      txCharacteristic = null;
      receivedData = '';
    });

    // Inicia escaneo BLE
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    // Cambia el estado después del timeout
    Future.delayed(const Duration(seconds: 4), () {
      setState(() {
        status = 'Scan complete';
      });
    });

    // Escucha resultados de escaneo
    FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        // ignore: deprecated_member_use
        if (r.device.name == 'ESP32-Hidro') {
          FlutterBluePlus.stopScan();
          setState(() {
            selectedResult = r;
          });
          connectToDevice(r.device);
          break;
        }
      }
    });
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    setState(() {
      // ignore: deprecated_member_use
      status = 'Connecting to ${device.name}…';
    });

    try {
      await device.connect(autoConnect: false);
      setState(() {
        connectedDevice = device;
        // ignore: deprecated_member_use
        status = 'Connected to ${device.name}';
      });

      // Descubre servicios y características
      final services = await device.discoverServices();
      final uartService = services.firstWhere(
        (s) => s.uuid.toString().toUpperCase() == serviceUuid,
      );

      final txChar = uartService.characteristics.firstWhere(
        (c) => c.uuid.toString().toUpperCase() == txUuid,
      );

      setState(() {
        txCharacteristic = txChar;
      });

      // Activa notificaciones para recibir datos
      await txChar.setNotifyValue(true);
      // ignore: deprecated_member_use
      txChar.value.listen((buf) {
        final msg = utf8.decode(buf);
        setState(() {
          receivedData += '$msg\n';
        });
      });
    } catch (e) {
      setState(() {
        status = 'Error: $e';
      });
    }
  }

  @override
  void dispose() {
    connectedDevice?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE UART'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: startScan,
              child: Text(status.startsWith('Scanning') ? '…' : 'Scan & Connect'),
            ),
            const SizedBox(height: 10),
            Text(status),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Text(receivedData),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
