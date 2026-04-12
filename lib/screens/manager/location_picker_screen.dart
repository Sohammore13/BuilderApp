import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../constants.dart';
import '../../widgets/common_widgets.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();
  bool _locatingUser = false;

  // Mumbai default
  static const LatLng _initialPosition = LatLng(19.0760, 72.8777);

  Future<void> _goToCurrentLocation() async {
    setState(() => _locatingUser = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable them in settings.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied. Please enable it in app settings.');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final userLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _selectedLocation = userLatLng;
      });

      _mapController.move(userLatLng, 16.0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get current location: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locatingUser = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Select Site Location', style: AppTextStyles.appBarTitle),
      ),
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialPosition,
              initialZoom: 14.0,
              onTap: (tapPosition, latLng) {
                setState(() {
                  _selectedLocation = latLng;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.builderapp.app',
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ── Selected location info banner ────────────────────────
          if (_selectedLocation != null)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.card.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pin_drop, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                        'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── My Location FAB ──────────────────────────────────────
          Positioned(
            bottom: 90,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'myLocation',
              backgroundColor: AppColors.card,
              onPressed: _locatingUser ? null : _goToCurrentLocation,
              child: _locatingUser
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),

          // ── Confirm Button ───────────────────────────────────────
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: PrimaryButton(
              onPressed: _selectedLocation == null
                  ? null
                  : () => Navigator.pop(context, _selectedLocation),
              icon: Icons.check_circle_outline,
              label: _selectedLocation == null
                  ? 'Tap on map to select location'
                  : 'Confirm Location',
              color: _selectedLocation == null
                  ? AppColors.onSurfaceMuted
                  : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
