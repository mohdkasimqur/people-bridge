import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/Message/screen_message.dart';
import 'package:url_launcher/url_launcher.dart';

class ScreenCommercialDriverProfile extends StatelessWidget {
  final Map<String, dynamic> driver;
  final double distance;

  const ScreenCommercialDriverProfile({
    super.key,
    required this.driver,
    this.distance = 0,
  });

  String _firstValue(List<String> keys, String fallback) {
    for (final key in keys) {
      final value = driver[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value != 'null') {
        return value;
      }
    }
    return fallback;
  }

  double? _coordinate(List<String> keys) {
    for (final key in keys) {
      final value = driver[key];
      if (value == null) continue;

      final parsed = double.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  String _formatDistance(double value) {
    if (value < 1) {
      return '${(value * 1000).round()} m';
    }
    return '${value.toStringAsFixed(1)} km';
  }

  Future<void> _showRegisteredLocation(
    BuildContext context,
  ) async {
    // Use the location saved by the commercial driver
    // during registration, not the viewer's GPS position.
    final latitude = _coordinate([
      'parkedLatitude',
      'latitude',
      'locationLatitude',
    ]);

    final longitude = _coordinate([
      'parkedLongitude',
      'longitude',
      'locationLongitude',
    ]);

    final locationName = _firstValue([
      'parkedLocation',
      'nearestTown',
      'district',
      'state',
    ], 'Registered location');

    if (latitude == null || longitude == null) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Registered Location'),
          content: Text(
            locationName == 'Registered location'
                ? 'The driver has not provided map coordinates. '
                    'The registered location is unavailable.'
                : '$locationName\n\n'
                    'Map coordinates are not available for this location.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$latitude,$longitude',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open the map.'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open the map.'),
          ),
        );
      }
    }
  }

  Future<void> _callSecondaryNumber(
    BuildContext context,
  ) async {
    final secondaryPhone = _firstValue([
      'secondaryMobile',
      'secondaryPhone',
      'secondaryMobileNumber',
    ], '');

    if (secondaryPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Secondary phone number is not available.',
          ),
        ),
      );
      return;
    }

    final phoneUri = Uri(
      scheme: 'tel',
      path: secondaryPhone,
    );

    try {
      final launched = await launchUrl(phoneUri);

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open the phone dialer.',
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open the phone dialer.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _firstValue(
      ['username', 'name', 'fullName'],
      'Commercial Driver',
    );

    final photo = _firstValue([
      'profilePhoto',
      'profilePhotoUrl',
      'photoUrl',
    ], '');

    final vehicleNumber = _firstValue(
      ['vehicleNumber'],
      'Not available',
    );

    final category = _firstValue(
      ['vehicle', 'category', 'vehicleCategory'],
      'Commercial Vehicle',
    );

    final vehicleName = _firstValue(
      ['vehicleName'],
      '',
    );

    final locationName = _firstValue([
      'parkedLocation',
      'nearestTown',
      'district',
      'state',
    ], 'Location not available');

    final uid = _firstValue(['uid'], '');

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Commercial Driver Profile'),
        backgroundColor: const Color(0xFF138808),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // DRIVER PHOTO
            Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE8F5E9),
                ),
                clipBehavior: Clip.antiAlias,
                child: photo.isNotEmpty
                    ? Image.network(
                        photo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return const Icon(
                            Icons.person,
                            size: 55,
                            color: Color(0xFF138808),
                          );
                        },
                      )
                    : const Icon(
                        Icons.person,
                        size: 55,
                        color: Color(0xFF138808),
                      ),
              ),
            ),

            const SizedBox(height: 15),

            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // COMMERCIAL CATEGORY
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  category,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF138808),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            if (vehicleName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                vehicleName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // REGISTERED LOCATION
            const Text(
              'Registered Location',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE0E0E0),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF138808),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      locationName,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // UNLOCK / OPEN REGISTERED LOCATION
            ElevatedButton.icon(
              onPressed: () => _showRegisteredLocation(context),
              icon: const Icon(Icons.location_on),
              label: const Text('Unlock Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF138808),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // VEHICLE NUMBER
            const Text(
              'Vehicle Number',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 13,
                horizontal: 15,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD600),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black87),
              ),
              child: Text(
                vehicleNumber.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.black,
                ),
              ),
            ),

            if (distance > 0) ...[
              const SizedBox(height: 15),
              Text(
                'Distance: ${_formatDistance(distance)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
            ],

            const SizedBox(height: 25),

            // IN-APP CHAT
            ElevatedButton.icon(
              onPressed: uid.isEmpty
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ScreenMessage(
                            chatUser: {
                              'uid': uid,
                              'name': name,
                              'photo': photo,
                              'role': 'taxi_commercial',
                            },
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF138808),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // CALL SECONDARY MOBILE NUMBER
            OutlinedButton.icon(
              onPressed: () => _callSecondaryNumber(context),
              icon: const Icon(Icons.call_outlined),
              label: const Text('Call'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF138808),
                side: const BorderSide(
                  color: Color(0xFF138808),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Chat opens the in-app messaging screen. '
              'Call uses the commercial driver’s secondary mobile number.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}