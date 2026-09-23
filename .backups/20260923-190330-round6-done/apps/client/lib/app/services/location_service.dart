import 'package:geolocator/geolocator.dart';

/// Konum izni isteyip tek seferlik koordinat dondurur.
/// Izin verilmezse null doner; akis kilitlenmez.
Future<Position?> currentPosition() async {
  try {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return null;
    }
    const settings = LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 10));
    return await Geolocator.getCurrentPosition(locationSettings: settings);
  } catch (_) {
    return null;
  }
}
