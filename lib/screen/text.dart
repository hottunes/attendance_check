import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // latitude: 37.4279613,longitude: -122.0857419,
  static LatLng companyLatLng = const LatLng(37.5233273, 126.921252);
  static final CameraPosition initialPosition =
      CameraPosition(target: companyLatLng, zoom: 15.0);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: renderAppBar(),
      body: Column(
        children: [
          _CustomGoogleMap(initialPosition: initialPosition),
          _CheckButton()
        ],
      ),
    );
  }

  AppBar renderAppBar() {
    return AppBar(
      title: const Text(
        "Today's attendance",
        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w700),
      ),
      backgroundColor: Colors.white,
    );
  }
}

//  위치서비스가 켜져있는가를 확인
//  허가상태를 체크>> 로케이션 퍼미션 이음을 확인
//  디나이상태라면 허가요청
//  한번더체크했는데 된다? 통과 안된다? 허가해달라고 메시지출력
//  혹시 디나이포에버인가 체크
//

Future<String> checkPermission() async {
  final isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!isLocationServiceEnabled) {
    return 'Location service is not enabled';
  }
  LocationPermission checkLocationPermission =
      await Geolocator.checkPermission();
  if (checkLocationPermission == LocationPermission.denied) {
    checkLocationPermission = await Geolocator.requestPermission();
    if (checkLocationPermission == LocationPermission.denied) {
      return 'Location permission denied';
    }
  }
  if (checkLocationPermission == LocationPermission.deniedForever) {
    return 'Location permission denied forever';
  }
  return 'Location permission granted';
}

class _CustomGoogleMap extends StatelessWidget {
  const _CustomGoogleMap({
    super.key,
    required this.initialPosition,
  });

  final CameraPosition initialPosition;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: initialPosition,
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  const _CheckButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Expanded(child: Text("CHECK"));
  }
}
