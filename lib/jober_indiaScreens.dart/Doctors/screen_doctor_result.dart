import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jober_india/jober_indiaScreens.dart/Doctors/screen_doctor_profile.dart';

class ScreenDoctorResults extends StatefulWidget {
  final String selectedCategory;
  final String selectedSpecialization;
  final List<Map<String, dynamic>> doctors;

  const ScreenDoctorResults({
    super.key,
    required this.selectedCategory,
    required this.selectedSpecialization,
    required this.doctors,
  });

  @override
  State<ScreenDoctorResults> createState() =>
      _ScreenDoctorResultsState();
}

class _ScreenDoctorResultsState
    extends State<ScreenDoctorResults> {
  String searchText = '';

  // Pagination
static const int _pageSize = 10;
int _currentPage = 0;

// User's current GPS position
Position? _userPosition;

@override
void initState() {
  super.initState();
  _loadUserPosition();
}

Future<void> _loadUserPosition() async {
  try {
    bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) return;

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (!mounted) return;

    setState(() {
      _userPosition = position;
    });
  } catch (e) {
    debugPrint('Could not get user location: $e');
  }
}

double? _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

List<double>? _doctorCoordinates(
Map<String, dynamic> doctor,
) {
// ==========================================================
// FIRST: READ THE LOCATION STRUCTURE SAVED BY DOCTOR LOGIN
// Firestore: doctors/{uid}/location
// ==========================================================

final savedLocation = doctor['location'];

if (savedLocation is Map) {
final location =
Map<String, dynamic>.from(savedLocation);

final latitude =
    _toDouble(location['latitude']);

final longitude =
    _toDouble(location['longitude']);

if (latitude != null &&
    longitude != null &&
    latitude >= -90 &&
    latitude <= 90 &&
    longitude >= -180 &&
    longitude <= 180) {
  return [latitude, longitude];
}

}

// ==========================================================
// SECOND: SUPPORT MULTIPLE LOCATIONS IF USED LATER
// ==========================================================

final locations = doctor['locations'];

final activeLocationId =
(doctor['activeLocationId'] ?? '').toString();

if (locations is List && locations.isNotEmpty) {
final candidates = <Map<String, dynamic>>[];

Map<String, dynamic>? selectedLocation;

for (final item in locations) {
  if (item is! Map) continue;

  final location =
      Map<String, dynamic>.from(item);

  final locationId =
      (location['id'] ??
              location['locationId'] ??
              '')
          .toString();

  if (activeLocationId.isNotEmpty &&
      locationId == activeLocationId) {
    selectedLocation = location;
    break;
  }
}

if (selectedLocation != null) {
  candidates.add(selectedLocation);
}

candidates.addAll(
  locations
      .whereType<Map>()
      .map((item) =>
          Map<String, dynamic>.from(item))
      .where((item) => item != selectedLocation),
);

for (final location in candidates) {
  final latitude = _toDouble(
    location['latitude'],
  );

  final longitude = _toDouble(
    location['longitude'],
  );

  if (latitude != null &&
      longitude != null &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180) {
    return [latitude, longitude];
  }
}

}

// ==========================================================
// THIRD: SUPPORT TOP-LEVEL COORDINATES
// ==========================================================

final latitude =
_toDouble(doctor['latitude']);

final longitude =
_toDouble(doctor['longitude']);

if (latitude != null &&
longitude != null &&
latitude >= -90 &&
latitude <= 90 &&
longitude >= -180 &&
longitude <= 180) {
return [latitude, longitude];
}

// No valid coordinates found.
return null;
}

String? _distanceText(
  Map<String, dynamic> doctor,
) {
  final userPosition = _userPosition;

  if (userPosition == null) return null;

  final coordinates = _doctorCoordinates(doctor);

  if (coordinates == null) return null;

  final distanceInMeters = Geolocator.distanceBetween(
    userPosition.latitude,
    userPosition.longitude,
    coordinates[0],
    coordinates[1],
  );

  final distanceInKm = distanceInMeters / 1000;

  if (distanceInKm < 1) {
    return '${distanceInMeters.round()} m away';
  }

  return '${distanceInKm.toStringAsFixed(1)} km away';
}

  List<Map<String, dynamic>> get filteredDoctors {
    final search =
        searchText.trim().toLowerCase();

    if (search.isEmpty) {
      return widget.doctors;
    }

    return widget.doctors.where((doctor) {
      final name =
          (doctor['doctorName'] ?? '')
              .toString()
              .toLowerCase();

      final categories =
          doctor['categories'] is List
              ? (doctor['categories'] as List)
                  .map((e) => e.toString())
                  .join(' ')
                  .toLowerCase()
              : '';

      final specializations =
          doctor['specializations'] is List
              ? (doctor['specializations'] as List)
                  .map((e) => e.toString())
                  .join(' ')
                  .toLowerCase()
              : '';

      return name.contains(search) ||
          categories.contains(search) ||
          specializations.contains(search);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
   // final doctors = filteredDoctors;
final allDoctors = filteredDoctors;

final totalPages =
    allDoctors.isEmpty
        ? 1
        : (allDoctors.length + _pageSize - 1) ~/
            _pageSize;

final safePage =
    _currentPage >= totalPages
        ? totalPages - 1
        : _currentPage;

final startIndex = safePage * _pageSize;

final endIndex =
    (startIndex + _pageSize) > allDoctors.length
        ? allDoctors.length
        : startIndex + _pageSize;

final doctors = allDoctors.isEmpty
    ? <Map<String, dynamic>>[]
    : allDoctors.sublist(startIndex, endIndex);
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F8F7),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Doctors',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            _header(),


            Expanded(
              // child: doctors.isEmpty
              //     ? _emptyState()
              //     : ListView.builder(
              //         padding:
              //             const EdgeInsets.fromLTRB(
              //           16,
              //           8,
              //           16,
              //           24,
              //         ),
              //         itemCount: doctors.length,
              //         itemBuilder:
              //             (context, index) {
              //           return _doctorCard(
              //             doctors[index],
              //           );
              //         },
              //       ),
              child: allDoctors.isEmpty
    ? _emptyState()
    : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                16, 8, 16, 12,
              ),
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                return _doctorCard(doctors[index]);
              },
            ),
          ),

          _paginationControls(
            totalDoctors: allDoctors.length,
            totalPages: totalPages,
            currentPage: safePage,
          ),
        ],
      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paginationControls({
  required int totalDoctors,
  required int totalPages,
  required int currentPage,
}) {
  final firstDoctor = currentPage * _pageSize + 1;

  final lastDoctor =
      ((currentPage + 1) * _pageSize) > totalDoctors
          ? totalDoctors
          : (currentPage + 1) * _pageSize;

  return Container(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(
        top: BorderSide(color: Color(0xFFE8E8E8)),
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Showing $firstDoctor–$lastDoctor of $totalDoctors doctors',
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: currentPage > 0
                  ? () {
                      setState(() {
                        _currentPage = currentPage - 1;
                      });
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF12652F),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
              child: const Text('Previous'),
            ),
            const SizedBox(width: 18),
            Text(
              '${currentPage + 1} / $totalPages',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 18),
            OutlinedButton(
              onPressed: currentPage < totalPages - 1
                  ? () {
                      setState(() {
                        _currentPage = currentPage + 1;
                      });
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF12652F),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
              child: const Text('Next'),
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _header() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        10,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Doctors',
            style: TextStyle(
              color: Color(0xFF12652F),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            widget.selectedSpecialization,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            widget.selectedCategory,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '${widget.doctors.length} doctor${widget.doctors.length == 1 ? '' : 's'} found',
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _doctorCard(
    Map<String, dynamic> doctor,
  ) {
    final distanceText = _distanceText(doctor);
    final doctorName =
        (doctor['doctorName'] ?? 'Doctor')
            .toString()
            .trim();

    final categories =
        doctor['categories'] is List
            ? (doctor['categories'] as List)
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList()
            : <String>[];

    final specializations =
        doctor['specializations'] is List
            ? (doctor['specializations'] as List)
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList()
            : <String>[];

    final gender =
        (doctor['gender'] ?? '')
            .toString()
            .trim();

    final workingDays =
        doctor['workingDays'] is List
            ? (doctor['workingDays'] as List)
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList()
            : <String>[];

    return Container(
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(16),
          onTap: () {
            openDoctorProfile(doctor);
          },
          child: Padding(
            padding:
                const EdgeInsets.all(11),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF12652F)
                                .withValues(alpha: .09),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color:
                            Color(0xFF12652F),
                        size: 31,
                      ),
                    ),

                    const SizedBox(width: 13),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            doctorName,
                            maxLines: 2,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              color:
                                  Colors.black87,
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 5,
                          ),

                          Text(
                            widget
                                .selectedSpecialization,
                            maxLines: 2,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              color:
                                  Color(0xFF12652F),
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),

                       const SizedBox(height: 5),

Row(
  children: [
    const Icon(
      Icons.location_on_outlined,
      size: 15,
      color: Color(0xFF16803C),
    ),
    const SizedBox(width: 4),
    Expanded(
      child: Text(
        distanceText ?? 'Distance unavailable',
        style: const TextStyle(
          color: Color(0xFF16803C),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  ],
),

                          if (gender.isNotEmpty) ...[
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              gender,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const Icon(
                      Icons
                          .arrow_forward_ios_rounded,
                      color: Colors.black38,
                      size: 17,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                if (categories.isNotEmpty)
                  _infoSection(
                    title: 'Categories',
                    values: categories,
                    icon: Icons
                        .medical_services_outlined,
                  ),

                if (specializations.isNotEmpty)
                  _infoSection(
                    title: 'Specializations',
                    values: specializations,
                    icon: Icons
                        .local_hospital_outlined,
                  ),

                if (workingDays.isNotEmpty)
                  _infoSection(
                    title: 'Working Days',
                    values: workingDays,
                    icon: Icons
                        .calendar_today_outlined,
                  ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      openDoctorProfile(doctor);
                    },
                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor:
                          const Color(
                        0xFF12652F,
                      ),
                      side: const BorderSide(
                        color:
                            Color(0xFF12652F),
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 11,
                      ),
                    ),
                    child: const Text(
                      'VIEW PROFILE',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoSection({
    required String title,
    required List<String> values,
    required IconData icon,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF12652F),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$title: ',
                    style:
                        const TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: values.join(', '),
                    style:
                        const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  void openDoctorProfile(
    Map<String, dynamic> doctor,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ScreenDoctorProfile(
          doctor: doctor,
          selectedCategory:
              widget.selectedCategory,
          selectedSpecialization:
              widget.selectedSpecialization,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search_outlined,
              size: 60,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 16),

            const Text(
              'No doctors found',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              searchText.isNotEmpty
                  ? 'Try a different doctor name.'
                  : 'No doctor is currently available for this specialization.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),

            if (searchText.isNotEmpty) ...[
              const SizedBox(height: 18),

              OutlinedButton(
                onPressed: () {
                  setState(() {
                    searchText = '';
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      const Color(0xFF12652F),
                  side: const BorderSide(
                    color: Color(0xFF12652F),
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'CLEAR SEARCH',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}