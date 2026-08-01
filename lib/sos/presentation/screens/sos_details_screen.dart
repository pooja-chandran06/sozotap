import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constants/app_colors.dart';
import '../providers/sos_details_provider.dart';

class SosDetailsScreen extends ConsumerStatefulWidget {
  final String sosId;

  const SosDetailsScreen({super.key, required this.sosId});

  @override
  ConsumerState<SosDetailsScreen> createState() => _SosDetailsScreenState();
}

class _SosDetailsScreenState extends ConsumerState<SosDetailsScreen> {
  GoogleMapController? _mapController;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer.')),
        );
      }
    }
  }

  Future<void> _launchTurnByTurnNavigation(double lat, double lng) async {
    final Uri navUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    try {
      if (await canLaunchUrl(navUri)) {
        await launchUrl(navUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open turn-by-turn navigation. Please check your map apps.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching navigation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _respondOnMyWay(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Status updated: You marked "On My Way!"'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sosAsync = ref.watch(sosDetailsProvider(widget.sosId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live SOS Tracking', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: sosAsync.when(
        data: (session) {
          final bool isSessionActive = session == null || session.status == 'active';
          final double lat = (session != null && session.latitude != 0) ? session.latitude : 37.7749;
          final double lng = (session != null && session.longitude != 0) ? session.longitude : -122.4194;
          final bool hasValidCoordinates = (lat != 0 && lng != 0);

          final patientName = session?.patientName ?? 'John Doe (Demo)';
          final bloodGroup = session?.bloodGroup ?? 'O+';
          final conditions = session?.medicalConditions ?? 'Asthma, Penicillin Allergy';

          final LatLng patientPos = LatLng(lat, lng);

          return Column(
            children: [
              // Header Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                color: AppColors.primary.withOpacity(0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.primary, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          patientName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const Spacer(),
                        Chip(
                          label: Text('Blood: $bloodGroup', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          backgroundColor: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Conditions: $conditions', style: const TextStyle(fontSize: 14, color: Colors.black87)),
                    Text('SOS ID: ${widget.sosId} • Status: ${session?.status.toUpperCase() ?? "ACTIVE"}', 
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),

              // Live Google Map View
              Expanded(
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: patientPos,
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('patient_location'),
                      position: patientPos,
                      infoWindow: InfoWindow(title: patientName, snippet: 'Emergency Live Location'),
                    ),
                  },
                ),
              ),

              // Bottom Action Buttons
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // On My Way Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isSessionActive ? () => _respondOnMyWay(context) : null,
                            icon: const Icon(Icons.directions_run),
                            label: const Text('ON MY WAY!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Turn-by-Turn Navigation Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: (isSessionActive && hasValidCoordinates)
                                ? () => _launchTurnByTurnNavigation(lat, lng)
                                : null,
                            icon: const Icon(Icons.navigation),
                            label: const Text('NAVIGATE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _makePhoneCall('+15550199'),
                            icon: const Icon(Icons.phone),
                            label: const Text('Call Patient'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Opening full medical dossier...')),
                              );
                            },
                            icon: const Icon(Icons.person),
                            label: const Text('View Profile'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accent,
                              side: const BorderSide(color: AppColors.accent),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading live tracking: $err')),
      ),
    );
  }
}
