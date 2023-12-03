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
  bool checkDone = false;
  static const LatLng companyLatLng = LatLng(37.5233273, 126.921252);
  static const CameraPosition companyCameraPosition = CameraPosition(
    target: companyLatLng,
    zoom: 14.4746,
  );
  static const Marker companyMarker =
      Marker(markerId: MarkerId("companyMarker"), position: companyLatLng);
  static final Circle withinCircle = Circle(
    circleId: const CircleId('companyCircle'),
    strokeWidth: 1,
    strokeColor: Colors.blue,
    radius: 100,
    center: companyLatLng,
    fillColor: Colors.blue.withOpacity(0.5),
  );
  static final Circle notWithinCircle = Circle(
    circleId: const CircleId('companyCircle'),
    strokeWidth: 1,
    strokeColor: Colors.red,
    radius: 100,
    center: companyLatLng,
    fillColor: Colors.red.withOpacity(0.5),
  );
  static final Circle checkDoneCircle = Circle(
    circleId: const CircleId('companyCircle'),
    fillColor: Colors.green.withOpacity(0.5),
    center: companyLatLng,
    strokeColor: Colors.green,
    strokeWidth: 1,
    radius: 100,
  );
  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      return Scaffold(
        appBar: renderAppBar(),
        body: FutureBuilder(
            future: checkPermissionStatus(),
            builder: (
              BuildContext context,
              AsyncSnapshot snapshot,
            ) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              if (snapshot.data == 'permission granted') {
                return StreamBuilder<Position>(
                    stream: Geolocator.getPositionStream(),
                    builder: (context, snapshot) {
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
                            companyMarker: companyMarker,
                            companyCircle: checkDone
                                ? checkDoneCircle
                                : isWithinRange
                                    ? withinCircle
                                    : notWithinCircle,
                            onMapCreated: onMapCreated,
                          ),
                          _CheckButton(
                            onPressed: onCheckButtonPressed,
                            checkDone: checkDone,
                            isWithinRange: isWithinRange,
                          ),
                        ],
                      );
                    });
              }
              return Center(
                child: Text(snapshot.data),
              );
            }),
      );
    });
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void onCheckButtonPressed() async {
    final bool result = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: const Text('Check In'),
              content: const Text('Do you want to check your location?'),
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
              ]);
        });
    if (result) {
      setState(() {
        checkDone = true;
      });
    }
  }

  AppBar renderAppBar() {
    return AppBar(
      title: const Text(
        'Attendance App',
        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w700),
      ),
      backgroundColor: Colors.white,
      actions: [
        IconButton(
            icon: const Icon(Icons.my_location),
            color: Colors.red,
            onPressed: onMyLocationPressed),
      ],
    );
  }

  void onMyLocationPressed() async {
    if (mapController == null) {
      return;
    }
    final location = await Geolocator.getCurrentPosition();

    mapController!.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(
          location.latitude,
          location.longitude,
        ),
      ),
    );
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
}

class _CustomGoogleMap extends StatelessWidget {
  const _CustomGoogleMap({
    required this.companyCameraPosition,
    required this.companyMarker,
    required this.companyCircle,
    required this.onMapCreated,
  });
  final MapCreatedCallback onMapCreated;
  final CameraPosition companyCameraPosition;
  final Marker companyMarker;
  final Circle companyCircle;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: GoogleMap(
        initialCameraPosition: companyCameraPosition,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        markers: {companyMarker},
        circles: {companyCircle},
        onMapCreated: onMapCreated,
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool checkDone;
  final bool isWithinRange;
  const _CheckButton({
    required this.onPressed,
    required this.checkDone,
    required this.isWithinRange,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timelapse_outlined,
            color: checkDone
                ? Colors.green
                : isWithinRange
                    ? Colors.blue
                    : Colors.red,
            size: 50,
          ),
          const SizedBox(height: 20),
          if (!checkDone && isWithinRange)
            ElevatedButton(onPressed: onPressed, child: const Text("Check In"))
        ],
      ),
    );
  }
}
