import 'package:geolocator/geolocator.dart';

final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
if (!isLocationEnabled) {
return "Please turn on location service";
}
LocationPermission checkPermission = await Geolocator.checkPermission();

if (checkPermission == LocationPermission.denied) {
checkPermission = await Geolocator.requestPermission();
if (checkPermission == LocationPermission.denied) {
return "Please permit location service";
}
}
if (checkPermission == LocationPermission.deniedForever) {
return "Please permit location service on security settings";
}
return "Location permission granted";
