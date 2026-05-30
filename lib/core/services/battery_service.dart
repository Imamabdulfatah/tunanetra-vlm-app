import 'dart:async';
import 'package:battery_plus/battery_plus.dart';

class BatteryService {
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batteryStateSubscription;

  Stream<BatteryState> get onBatteryStateChanged =>
      _battery.onBatteryStateChanged;

  Future<int> getBatteryLevel() async {
    return await _battery.batteryLevel;
  }

  Future<bool> isBatteryLow() async {
    final level = await _battery.batteryLevel;
    return level < 12; // Threshold from original code
  }

  void dispose() {
    _batteryStateSubscription?.cancel();
  }
}
