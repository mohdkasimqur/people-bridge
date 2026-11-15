import 'package:flutter/material.dart';

class ScreenFishDeliveryProfile extends StatelessWidget {
  final Map<String, dynamic> profile;
  final String selectedCategoryId;
  final String selectedCategoryName;

  const ScreenFishDeliveryProfile({
    super.key,
    required this.profile,
    required this.selectedCategoryId,
    required this.selectedCategoryName,
  });

  String _text(dynamic value, {String fallback = 'Not provided'}) {
    if (value == null) return fallback;

    final String result = value.toString().trim();

    return result.isEmpty ? fallback : result;
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return [];

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 20,
        bottom: 10,
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal, size: 23),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 5),
                SelectableText(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecializations(List<String> specializations) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: specializations.isEmpty
          ? const Text('No specializations provided.')
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: specializations.map((item) {
                return Chip(
                  avatar: const Icon(
                    Icons.check_circle,
                    size: 17,
                    color: Colors.teal,
                  ),
                  label: Text(item),
                  backgroundColor: Colors.teal.shade50,
                  side: BorderSide.none,
                );
              }).toList(),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = _text(
      profile['username'] ??
          profile['name'] ??
          profile['fullName'] ??
          profile['userName'],
      fallback: 'Fish Delivery Rider',
    );

    final String photoUrl = _text(
      profile['profilePhotoUrl'],
      fallback: '',
    );

    final List<String> specializations = _stringList(
      profile['specializations'] ??
          profile['selectedItemList'],
    );

    final List<String> vehicleCategories = _stringList(
      profile['categories'],
    );

    final dynamic distanceValue = profile['distanceKm'];
    final String distance = distanceValue is num
        ? '${distanceValue.toStringAsFixed(1)} km'
        : 'Not available';

    final bool isLive = profile['locationType'] == 'live' ||
        profile['isLive'] == true;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Fish Delivery Profile'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // =====================================================
          // PROFILE HEADER
          // =====================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: Colors.teal.shade50,
                  backgroundImage: photoUrl.startsWith('http')
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl.startsWith('http')
                      ? null
                      : const Icon(
                          Icons.delivery_dining,
                          size: 55,
                          color: Colors.teal,
                        ),
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedCategoryName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isLive
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 10,
                        color: isLive ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        isLive ? 'Live now' : 'Registered rider',
                        style: TextStyle(
                          color: isLive
                              ? Colors.green.shade800
                              : Colors.orange.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$distance from your location',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // =====================================================
          // CONTACT DETAILS
          // =====================================================

          _buildSectionTitle('Contact Details', Icons.contact_phone),

          _buildDetailCard(
            icon: Icons.phone,
            title: 'Mobile Number',
            value: _text(profile['mobileNumber']),
          ),

          _buildDetailCard(
            icon: Icons.phone_in_talk,
            title: 'Secondary Mobile Number',
            value: _text(profile['secondaryMobileNumber']),
          ),

          // =====================================================
          // SPECIALIZATIONS
          // =====================================================

          _buildSectionTitle(
            'Fish Delivery Specializations',
            Icons.set_meal,
          ),

          _buildSpecializations(specializations),

          // =====================================================
          // VEHICLE DETAILS
          // =====================================================

          _buildSectionTitle('Vehicle Details', Icons.two_wheeler),

          _buildDetailCard(
            icon: Icons.category,
            title: 'Vehicle Categories',
            value: vehicleCategories.isEmpty
                ? 'Not provided'
                : vehicleCategories.join(', '),
          ),

          _buildDetailCard(
            icon: Icons.directions_bike,
            title: 'Vehicle Number',
            value: _text(profile['vehicleNumber']),
          ),

          _buildDetailCard(
            icon: Icons.color_lens,
            title: 'Vehicle Number Color',
            value: _text(profile['vehicleNumberColor']),
          ),

          // =====================================================
          // LOCATION DETAILS
          // =====================================================

          _buildSectionTitle('Location Details', Icons.location_on),

          _buildDetailCard(
            icon: Icons.map,
            title: 'State',
            value: _text(profile['state']),
          ),

          _buildDetailCard(
            icon: Icons.location_city,
            title: 'District',
            value: _text(profile['district']),
          ),

          _buildDetailCard(
            icon: Icons.place,
            title: 'Nearest Town',
            value: _text(profile['nearestTown']),
          ),

          _buildDetailCard(
            icon: Icons.my_location,
            title: 'Current Location',
            value: _text(profile['currentLocationName']),
          ),

          _buildDetailCard(
            icon: Icons.pin_drop,
            title: 'Latitude',
            value: _text(
              profile['latitude'] ??
                  profile['currentLocationLatitude'],
            ),
          ),

          _buildDetailCard(
            icon: Icons.pin_drop,
            title: 'Longitude',
            value: _text(
              profile['longitude'] ??
                  profile['currentLocationLongitude'],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}