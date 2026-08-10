import 'package:geolocator/geolocator.dart';

class LocationService {

  // =====================================================
  // CHECK LOCATION
  // =====================================================

  Future<Position> getCurrentLocation() async {

    bool serviceEnabled;

    LocationPermission permission;

    // --------------------------------------
    // Is GPS Enabled?
    // --------------------------------------

    serviceEnabled =
    await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {

      await Geolocator.openLocationSettings();

      throw Exception(
        "Please enable Location Services.",
      );
    }

    // --------------------------------------
    // Permission
    // --------------------------------------

    permission =
    await Geolocator.checkPermission();

    if (permission ==
        LocationPermission.denied) {

      permission =
      await Geolocator.requestPermission();

      if (permission ==
          LocationPermission.denied) {

        throw Exception(
          "Location permission denied.",
        );
      }
    }

    // --------------------------------------
    // Permanently Denied
    // --------------------------------------

    if (permission ==
        LocationPermission.deniedForever) {

      await Geolocator.openAppSettings();

      throw Exception(
        "Location permission permanently denied.",
      );
    }

    // --------------------------------------
    // Current Position
    // --------------------------------------

    return await Geolocator.getCurrentPosition(

      locationSettings: const LocationSettings(

        accuracy: LocationAccuracy.best,

      ),

    );
  }
}