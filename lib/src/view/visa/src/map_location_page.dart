// ignore_for_file: depend_on_referenced_packages

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc;
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/view/visa/src/search_location.dart';
import 'package:google_places_flutter/model/prediction.dart';

class MapLocationPickerPage extends StatefulWidget {
  const MapLocationPickerPage({super.key});

  @override
  State<MapLocationPickerPage> createState() => _MapLocationPickerPageState();
}

class _MapLocationPickerPageState extends State<MapLocationPickerPage> {
  GoogleMapController? mapController;
  LatLng currentLatLng = const LatLng(41.311081, 69.240562);
  String address = "";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    loc.Location location = loc.Location();

    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;
    loc.LocationData locationData;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        return;
      }
    }

    locationData = await location.getLocation();

    setState(() {
      currentLatLng = LatLng(locationData.latitude!, locationData.longitude!);
    });

    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(currentLatLng, 16),
      );
    }

    _getAddressFromLatLng(currentLatLng);
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() => isLoading = true);
    try {
      List<Placemark> placemarks = await Geocoding()
          .placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          address =
          "${place.subLocality ?? ''}, ${place.thoroughfare ?? ''}, ${place.subThoroughfare ??""}, ";
        });
      }
    } catch (e) {
      debugPrint("Error getting address: $e");
    }
    setState(() => isLoading = false);
  }

  void _onCameraMove(CameraPosition position) {
    currentLatLng = position.target;
  }

  void _onCameraIdle() {
    _getAddressFromLatLng(currentLatLng);
  }

  void _confirmLocation() {
    Navigator.pop(context, address);
  }

  void _moveToMyLocation() {
    _determinePosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Yetkazib berish manzilini kiriting"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body:Padding(padding: EdgeInsets.all(16),child:  Column(children: [

        SizedBox(
            height: context.height*0.6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child:  Stack(
        alignment: Alignment.center,
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: currentLatLng,
              zoom: 18,
            ),
            onMapCreated: (controller) {
              mapController = controller;

              _determinePosition();
            },
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          const Icon(Icons.location_pin, size: 50, color: Colors.blue),

          Positioned(
            bottom: 16,
            right: 12,
            child:SizedBox(
            height: 48,
              width: 48,
              child:  FloatingActionButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),

              ),
              onPressed: _moveToMyLocation,
              backgroundColor: Colors.white,
              child:SvgPicture.asset(Assets.homeSendIcon),
            ),
          )),

          ],
      ),)
        ),
        context.szBoxHeight12,
        
        InkWell(
          onTap: ()async {
            final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddressSearchPage())
            );

            if (result != null) {
              if (result is Prediction) {
                if (mapController != null) {
                  currentLatLng = LatLng(double.parse(result.lat!), double.parse(result.lng!));
                  mapController!.animateCamera(
                    CameraUpdate.newLatLngZoom(currentLatLng, 16),
                  );
                }
              } else if (result is Map) {
                debugPrint("Joriy joylashuv: ${result['address']}");
              }
            }
          },
          child: Container(
            height: 56,
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1
              ),
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: isLoading
                ? const Center(
                child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
              address.isEmpty
                  ? "Manzil aniqlanmoqda..."
                  : address,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        context.szBoxHeight12,
        ElevatedButton(
          onPressed: _confirmLocation,
          style: ElevatedButton.styleFrom(
            backgroundColor: ProjectTheme.brandColor,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text("Shu yerga olib kelish", style: TextStyle(fontSize: 18,color: Colors.white)),
        ),
      ]))
    );
  }
}
