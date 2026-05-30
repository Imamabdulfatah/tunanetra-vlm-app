import 'dart:async';
import 'dart:typed_data';

import 'package:usb_serial/usb_serial.dart';

class UsbService {
  UsbPort? _port;
  StreamSubscription<Uint8List>? _subscription;
  StreamSubscription<UsbEvent>? _usbEventSubscription;
  Function(String)? onDataReceived;
  Function(String)? onStatusChanged;

  void init({Function(String)? onData, Function(String)? onStatus}) {
    onDataReceived = onData;
    onStatusChanged = onStatus;
    _usbEventSubscription = UsbSerial.usbEventStream?.listen(_handleUsbEvent);
    connectToDevice();
  }

  Future<void> connectToDevice() async {
    List<UsbDevice> devices = await UsbSerial.listDevices();
    print("USB devices found: $devices");
    if (devices.isNotEmpty) {
      UsbDevice device = devices.first;
      _port = await device.create();
      bool openResult = await _port!.open();
      if (!openResult) {
        onStatusChanged?.call("Gagal membuka port");
        print("Failed to open USB port");
        return;
      }
      await _port!.setPortParameters(
        115200,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );
      onStatusChanged?.call("Terhubung ke ESP32");
      _subscription = _port!.inputStream!.listen((Uint8List data) {
        String received = String.fromCharCodes(data).trim();
        onDataReceived?.call(received);
      });
    } else {
      onStatusChanged?.call("Tidak ada perangkat USB ditemukan");
      print("No USB devices found");
    }
  }

  void _handleUsbEvent(UsbEvent event) {
    print("USB Event: ${event.event}");
    if (event.event == UsbEvent.ACTION_USB_ATTACHED) {
      print("USB device attached, attempting auto-connect");
      connectToDevice();
    } else if (event.event == UsbEvent.ACTION_USB_DETACHED) {
      print("USB device detached");
      _closePort();
    }
  }

  void _closePort() {
    if (_port != null) {
      _port!.close();
      _port = null;
      _subscription?.cancel();
      _subscription = null;
      onStatusChanged?.call("Terputus");
    }
  }

  void dispose() {
    _closePort();
    _usbEventSubscription?.cancel();
  }
}
