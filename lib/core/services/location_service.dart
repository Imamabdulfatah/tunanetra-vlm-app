import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<String> getCurrentLocationUrl() async {
    Position position = await getCurrentPosition();
    return 'https://maps.google.com/?q=${position.latitude},${position.longitude}';
  }

  Future<String> getCurrentLocationReadable() async {
    Position position = await getCurrentPosition();
    return 'lintang ${position.latitude}, bujur ${position.longitude}';
  }
}
