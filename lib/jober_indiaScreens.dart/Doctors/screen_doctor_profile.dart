import 'package:flutter/material.dart';
import 'package:jober_india/jober_indiaScreens.dart/Message/screen_message.dart';
import 'package:url_launcher/url_launcher.dart';

class ScreenDoctorProfile extends StatefulWidget {
  final Map<String, dynamic> doctor;

  final String selectedCategory;
  final String selectedSpecialization;

  const ScreenDoctorProfile({
    super.key,
    required this.doctor,
    required this.selectedCategory,
    required this.selectedSpecialization,
  });

  @override
  State<ScreenDoctorProfile> createState() =>
      _ScreenDoctorProfileState();
}

class _ScreenDoctorProfileState
    extends State<ScreenDoctorProfile> {
  String get doctorName {
    final name =
        (widget.doctor['doctorName'] ?? '')
            .toString()
            .trim();

    return name.isEmpty ? 'Doctor' : name;
  }

  String get phoneNumber {
    return (widget.doctor['phone'] ?? '')
        .toString()
        .trim();
  }

  String get gender {
    return (widget.doctor['gender'] ?? '')
        .toString()
        .trim();
  }

  List<String> get categories {
    final value =
        widget.doctor['categories'];

    if (value is! List) {
      return [];
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<String> get specializations {
    final value =
        widget.doctor['specializations'];

    if (value is! List) {
      return [];
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<String> get workingDays {
    final value =
        widget.doctor['workingDays'];

    if (value is! List) {
      return [];
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Map<String, dynamic>? get locationData {
    final value =
        widget.doctor['location'];

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  double? get latitude {
    final value =
        locationData?['latitude'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }

  double? get longitude {
    final value =
        locationData?['longitude'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }

  String get locationAddress {
    return (locationData?['address'] ?? '')
        .toString()
        .trim();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F7),

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
          'Doctor Profile',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            30,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              // Doctor header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: .04),
                      blurRadius: 7,
                      offset:
                          const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [

                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF12652F)
                                .withValues(alpha: 0.09),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        size: 45,
                        color:
                            Color(0xFF12652F),
                      ),
                    ),

                    const SizedBox(height: 13),

                    Text(
                      doctorName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      widget.selectedSpecialization,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color:
                            Color(0xFF12652F),
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    if (gender.isNotEmpty) ...[
                      const SizedBox(height: 5),

                      Text(
                        gender,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [

                  Expanded(
                    child: _actionButton(
                      icon: Icons.call,
                      title: 'CALL',
                      onTap: callDoctor,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _actionButton(
                      icon: Icons.chat_bubble_outline,
                      title: 'CHAT',
                      onTap: openChat,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: _actionButton(
                  icon: Icons.location_on_outlined,
                  title: 'GO TO LOCATION',
                  onTap: openDoctorLocation,
                ),
              ),

              const SizedBox(height: 22),

              sectionTitle('Doctor Categories'),

              const SizedBox(height: 9),

              _valueContainer(
                categories.isEmpty
                    ? [widget.selectedCategory]
                    : categories,
              ),

              const SizedBox(height: 20),

              sectionTitle('Specializations'),

              const SizedBox(height: 9),

              _valueContainer(
                specializations.isEmpty
                    ? [
                        widget.selectedSpecialization
                      ]
                    : specializations,
              ),

              if (workingDays.isNotEmpty) ...[
                const SizedBox(height: 20),

                sectionTitle('Working Days'),

                const SizedBox(height: 9),

                _valueContainer(
                  workingDays,
                ),
              ],

              if (locationAddress.isNotEmpty) ...[
                const SizedBox(height: 20),

                sectionTitle('Location'),

                const SizedBox(height: 9),

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(13),
                    border: Border.all(
                      color:
                          Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      const Icon(
                        Icons.location_on_outlined,
                        color:
                            Color(0xFF12652F),
                        size: 22,
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          locationAddress,
                          style:
                              const TextStyle(
                            color:
                                Colors.black87,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 19,
        ),
        label: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF12652F),
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }

  Widget sectionTitle(
    String title,
  ) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF202124),
      ),
    );
  }

  Widget _valueContainer(
    List<String> values,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(13),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: values.map((value) {
          return Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color:
                  const Color(0xFF12652F)
                      .withValues(alpha: .08),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF12652F),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  Future<void> callDoctor() async {
    if (phoneNumber.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Doctor phone number is not available.',
          ),
        ),
      );

      return;
    }

    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    try {
      final canCall =
          await canLaunchUrl(phoneUri);

      if (!canCall) {
        throw Exception(
          'Could not launch phone dialer',
        );
      }

      await launchUrl(phoneUri);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open phone dialer.',
          ),
        ),
      );
    }
  }

  void openChat() {
    final doctorData =
        Map<String, dynamic>.from(
      widget.doctor,
    );

    // Keep the doctor's phone hidden from
    // the profile UI, but pass the data to
    // the existing message screen.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScreenMessage(
          chatUser: doctorData,
        ),
      ),
    );
  }

  Future<void> openDoctorLocation() async {
    if (latitude == null ||
        longitude == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Doctor location is not available.',
          ),
        ),
      );

      return;
    }

    final Uri mapUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=$latitude,$longitude',
    );

    try {
      final canOpen =
          await canLaunchUrl(mapUri);

      if (!canOpen) {
        throw Exception(
          'Could not open Google Maps',
        );
      }

      await launchUrl(
        mapUri,
        mode:
            LaunchMode.externalApplication,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open doctor location.',
          ),
        ),
      );
    }
  }
}