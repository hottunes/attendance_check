import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? mapController;
  bool isCheckSuccess = false;

  static const LatLng companyLatLng = LatLng(37.5233273, 126.921252);
  static const CameraPosition companyCameraPosition = CameraPosition(
    target: companyLatLng,
    zoom: 14.4746,
  );
  static const Marker companyMarker = Marker(
    markerId: MarkerId('company'),
    position: companyLatLng,
  );

  static final Circle withInCircle = Circle(
      circleId: const CircleId('withInCircle'),
      radius: 100,
      fillColor: Colors.blue.withOpacity(0.5),
      center: companyLatLng,
      strokeWidth: 2,
      strokeColor: Colors.blue);
  static final Circle notWithInCircle = Circle(
      circleId: const CircleId('withInCircle'),
      radius: 100,
      fillColor: Colors.red.withOpacity(0.5),
      center: companyLatLng,
      strokeWidth: 2,
      strokeColor: Colors.red);
  static final Circle checkSuccessCircle = Circle(
      circleId: const CircleId('withInCircle'),
      radius: 100,
      fillColor: Colors.green.withOpacity(0.5),
      center: companyLatLng,
      strokeWidth: 2,
      strokeColor: Colors.green);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: renderAppBar(),
      body: FutureBuilder<String>(
          future: checkPermissionStatus(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.data == "permission granted") {
              return StreamBuilder(
                  stream: Geolocator.getPositionStream(),
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    bool isWithinRange = false;
                    if (snapshot.hasData) {
                      final start = snapshot.data!;
                      const end = companyLatLng;
                      final distance = Geolocator.distanceBetween(
                        start.latitude,
                        start.longitude,
                        end.latitude,
                        end.longitude,
                      );
                      if (distance <= 100) {
                        isWithinRange = true;
                      }
                    }

                    return Column(
                      children: [
                        _CustomGoogleMap(
                          companyCameraPosition: companyCameraPosition,
                          companyCircle: isCheckSuccess
                              ? checkSuccessCircle
                              : isWithinRange
                                  ? withInCircle
                                  : notWithInCircle,
                          companyMarker: companyMarker,
                          onMapCreated: onMapCreated,
                        ),
                        _CheckButton(
                          onPressed: onCheckButtonPressed,
                          isCheckSuccess: isCheckSuccess,
                          isWithinRange: isWithinRange,
                        )
                      ],
                    );
                  });
            }
            return Text(snapshot.data);
          }),
    );
  }

  void onCheckButtonPressed() async {
    final bool isUserCheckSuccess = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Are you sure?'),
            content: const Text('Do you want to check in?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text('Yes'),
              ),
            ],
          );
        });

    if (isUserCheckSuccess) {
      setState(() {
        isCheckSuccess = true;
      });
    }
  }

  Future<String> checkPermissionStatus() async {
    final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationEnabled) {
      return "Please turn on location service";
    }
    LocationPermission locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
      if (locationPermission == LocationPermission.denied) {
        return "Please turn on location service";
      }
    }
    if (locationPermission == LocationPermission.deniedForever) {
      return "Please turn on location service on the setting menu.";
    }

    return "permission granted";
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  AppBar renderAppBar() {
    return AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Check in',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.blue),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.blue),
            onPressed: onMyLocationPressed,
          ),
        ]);
  }

  void onMyLocationPressed() async {
    if (mapController == null) return;
    final location = await Geolocator.getCurrentPosition();

    mapController!.animateCamera(CameraUpdate.newLatLng(
      LatLng(location.latitude, location.longitude),
    ));
  }
}

class _CustomGoogleMap extends StatelessWidget {
  const _CustomGoogleMap({
    required this.companyCameraPosition,
    required this.companyCircle,
    required this.companyMarker,
    required this.onMapCreated,
  });

  final CameraPosition companyCameraPosition;
  final Circle companyCircle;
  final Marker companyMarker;
  final MapCreatedCallback onMapCreated;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: GoogleMap(
        initialCameraPosition: companyCameraPosition,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        circles: {companyCircle},
        markers: {companyMarker},
        onMapCreated: onMapCreated,
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  const _CheckButton({
    required this.onPressed,
    required this.isCheckSuccess,
    required this.isWithinRange,
  });
  final VoidCallback onPressed;
  final bool isCheckSuccess;
  final bool isWithinRange;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timelapse_outlined,
            size: 70,
            color: isCheckSuccess
                ? Colors.green
                : isWithinRange
                    ? Colors.blue
                    : Colors.red,
          ),
          const SizedBox(height: 20),
          if (!isCheckSuccess && isWithinRange)
            ElevatedButton(onPressed: onPressed, child: const Text('Check in'))
        ],
      ),
    );
  }
}
