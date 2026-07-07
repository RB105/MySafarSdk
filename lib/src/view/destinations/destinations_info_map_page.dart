// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously

import 'dart:io';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:mysafar_sdk/src/core/tools/project_utils.dart';
import 'package:mysafar_sdk/src/cubit/main/popularDectinationInfo/popular_destination_info_cubit.dart';
import 'package:mysafar_sdk/src/model/remote/fornex/destinations_info_model.dart';
import 'package:mysafar_sdk/src/model/remote/fornex/pop_destinations.dart';
import 'package:mysafar_sdk/src/service/map/marker_service.dart';
import 'package:mysafar_sdk/src/view/destinations/destination_map_constants.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/view/tickets/ticket_page.dart' show RecommendationsTicketPage;

class DestinationInfoMapWidget extends StatefulWidget {
  final PopDestinationsModel destinationsModel;
  static const routeName = '/destinationInfo';

  const DestinationInfoMapWidget({super.key, required this.destinationsModel});

  @override
  State<DestinationInfoMapWidget> createState() =>
      _DestinationInfoMapWidgetState();
}

class _DestinationInfoMapWidgetState extends State<DestinationInfoMapWidget> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  late LatLng _initialCenter;
  String _selectedPlaceDescription = '';
  bool _markersLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeMapCenter();
  }

  void _initializeMapCenter() {
    final lat = double.tryParse(widget.destinationsModel.latitude) ?? 0;
    final lng = double.tryParse(widget.destinationsModel.longitude) ?? 0;
    _initialCenter = LatLng(lat, lng);
  }

  @override
  void dispose() {
    _markers.clear();
    _mapController?.dispose();
    _mapController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PopularDestinationInfoCubit(
        info: widget.destinationsModel.destination.slug,
      ),
      child: BlocConsumer<PopularDestinationInfoCubit, PopularDestinationInfoState>(
        listener: _handleStateChanges,
        builder: (context, state) => _buildScaffold(context, state),
      ),
    );
  }

  void _handleStateChanges(BuildContext context, PopularDestinationInfoState state) {
    if (state is PopularDestinationInfoSuccessState) {
      _loadMarkers(state.destinations);
    }
  }

  Widget _buildScaffold(BuildContext context, PopularDestinationInfoState state) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildMap(context),
      bottomNavigationBar: _buildBottomPanel(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        _getLocalizedValue(widget.destinationsModel.destination.name),
        style: context.textTheme.bodyLarge,
      ),
    );
  }

  Widget _buildMap(BuildContext context) {
    return SafeArea(
      top: Platform.isAndroid,
      bottom: Platform.isAndroid,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _initialCenter,
          zoom: DestinationMapConstants.initialZoom,
        ),
        onMapCreated: _onMapCreated,
        markers: _markers,
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        _initialCenter,
        DestinationMapConstants.defaultZoom,
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context) {
    return SafeArea(
      top: Platform.isAndroid,
      bottom: Platform.isAndroid,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.color.primaryContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: context.themeProvider.isDark
                  ? Colors.transparent
                  : const Color(0x80C6C7C9),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedPlaceDescription.isEmpty
                    ? _getLocalizedValue(widget.destinationsModel.description)
                    : _selectedPlaceDescription,
                style: context.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _buildTicketsButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketsButton(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _navigateToTickets(context),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: ProjectTheme.brandColor,
          foregroundColor: Colors.white,
        ),
        child: Text('tickets_button'.tr()),
      ),
    );
  }

  Future<void> _loadMarkers(DestinationsInfoModel infoModel) async {
    // Markerlar bir marta yuklanadi; har bir state o'zgarishida qayta yuklamaslik.
    if (_markersLoaded) return;
    _markersLoaded = true;

    final places = infoModel.result?.places ?? [];

    // Har bir joy uchun markerlarni parallel ravishda tayyorlaymiz (ketma-ket
    // kutib turish o'rniga) va oxirida bitta setState bilan qo'shamiz.
    final results = await Future.wait(
      places.map(_buildMarkersForPlace),
    );

    if (!mounted) return;

    setState(() {
      for (final placeMarkers in results) {
        for (final marker in placeMarkers) {
          _markers.removeWhere((m) => m.markerId.value == marker.markerId.value);
          _markers.add(marker);
        }
      }
    });
  }

  Future<List<Marker>> _buildMarkersForPlace(dynamic place) async {
    final lat = double.tryParse(place.latitude ?? '') ?? 0;
    final lng = double.tryParse(place.longitude ?? '') ?? 0;
    final id = place.id.toString();
    final position = LatLng(lat, lng);
    final title = _getLocalizedValue(place.name ?? '');
    final description = _getLocalizedValue(place.description ?? '');

    final markers = <Marker>[];

    final placeholderIcon = await MarkerService.createPlaceholderMarker();
    markers.add(_buildMarker(id, position, placeholderIcon, title, description));

    if (place.images?.isNotEmpty == true) {
      final imageUrl = place.images!.first.image ?? '';
      if (imageUrl.isNotEmpty) {
        final imageIcon = await MarkerService.createImageMarker(imageUrl);
        if (imageIcon != null) {
          markers.add(_buildMarker(id, position, imageIcon, title, description));
        }
      }
    }

    return markers;
  }

  Marker _buildMarker(
    String id,
    LatLng position,
    BitmapDescriptor icon,
    String title,
    String description,
  ) {
    return Marker(
      markerId: MarkerId(id),
      position: position,
      icon: icon,
      infoWindow: InfoWindow(title: title),
      onTap: () {
        if (mounted && description.isNotEmpty) {
          setState(() => _selectedPlaceDescription = description);
        }
      },
    );
  }

  void _navigateToTickets(BuildContext context) {
    final destination = widget.destinationsModel.destination;

    final requestBody = DestinationTicketHelper.createTicketRequest(
      destinationCode: destination.aviationCode,
      destinationName: _getLocalizedValue(destination.name),
    );

    ProjectUtils.setRecommendationParams(requestBody);

    Navigator.pushNamed(
      context,
      RecommendationsTicketPage.routeName,
      arguments: requestBody,
    );
  }

  String _getLocalizedValue(dynamic localizedObject) {
    if (localizedObject == null) return '';
    if (localizedObject is String) return localizedObject;

    final lang = dataLang();

    return switch (lang) {
      'uz' => localizedObject.uz ?? '',
      'ru' => localizedObject.ru ?? '',
      'en' => localizedObject.en ?? '',
      _ => localizedObject.uz ?? '',
    };
  }
}
