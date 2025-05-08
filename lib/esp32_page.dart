import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestBluetoothPermissions() async {
    await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
    ].request();
}

class Esp32Page extends StatefulWidget {
  const Esp32Page({super.key});

  @override
  State<Esp32Page> createState() => _Esp32PageState();
}

class _Esp32PageState extends State<Esp32Page> {
  BluetoothDevice? _device;
  BluetoothConnection? _connection;
  bool _isConnecting = false;
  bool _connected = false;
  String _receivedData = "";
  String _statusMessage = "Esperando conexión...";
  StreamSubscription<Uint8List>? _dataSubscription;

  Future<bool> isBluetoothEnabled() async {
    final state = await FlutterBluetoothSerial.instance.state;
    return state == BluetoothState.STATE_ON;
  }

  Future<void> _selectDevice() async {
    try {
      final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      final selectedDevice = await showDialog<BluetoothDevice>(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Selecciona tu ESP32'),
          children: devices
              .where((d) => d.name?.contains('ESP32') ?? false)
              .map((d) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, d),
                    child: Text(d.name ?? d.address),
                  ))
              .toList(),
        ),
      );

      if (selectedDevice != null) {
        setState(() {
          _device = selectedDevice;
          _statusMessage = "Dispositivo seleccionado: ${_device!.name}";
        });
      }
    } catch (e) {
      _updateStatus("Error al buscar dispositivos: ${e.toString()}");
    }
  }

  Future<void> _connect() async {
    if (_device == null || _isConnecting) return;

    setState(() {
      _isConnecting = true;
      _statusMessage = "Conectando a ${_device!.name}...";
    });

    try {
      // Verificar si Bluetooth está activado
      if (!await isBluetoothEnabled()) {
        _updateStatus("⚠️ Activa el Bluetooth primero");
        return;
      }

      _connection = await BluetoothConnection.toAddress(_device!.address);
      
      setState(() {
        _connected = true;
        _isConnecting = false;
        _statusMessage = "✅ Conectado a ${_device!.name}";
      });

      // Enviar hora actual
      final now = DateTime.now();
      _connection!.output.add(utf8.encode("HORA:${now.hour}:${now.minute}:${now.second}\n"));
      await _connection!.output.allSent;

      // Recibir datos
      _dataSubscription = _connection!.input!.listen((data) {
        final text = utf8.decode(data);
        setState(() {
          _receivedData += text;
        });
      }, onError: (error) {
        _updateStatus("Error en conexión: ${error.toString()}");
      });

    } catch (e) {
      _updateStatus("❌ Error al conectar: ${e.toString()}");
      setState(() {
        _isConnecting = false;
      });
    }
  }

  Future<void> _disconnect() async {
    try {
      await _dataSubscription?.cancel();
      await _connection?.close();
      setState(() {
        _connected = false;
        _statusMessage = "🔌 Desconectado";
      });
    } catch (e) {
      _updateStatus("Error al desconectar: ${e.toString()}");
    }
  }

  void _updateStatus(String message) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
      });
    }
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    _connection?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bluetooth ESP32')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _selectDevice,
              child: const Text("Seleccionar dispositivo"),
            ),
            const SizedBox(height: 10),
            if (_device != null)
              ElevatedButton(
                onPressed: _connected || _isConnecting ? null : _connect,
                child: Text(
                  _isConnecting 
                    ? "Conectando..." 
                    : _connected ? "Conectado" : "Conectar y sincronizar hora"
                ),
              ),
            if (_connected)
              ElevatedButton(
                onPressed: _disconnect,
                child: const Text("Desconectar"),
              ),
            const SizedBox(height: 20),
            Text(
              _statusMessage,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            const Text("Datos recibidos del ESP32:"),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 5, 42, 176),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _receivedData,
                    style: const TextStyle(color: Color.fromARGB(255, 11, 179, 230)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}