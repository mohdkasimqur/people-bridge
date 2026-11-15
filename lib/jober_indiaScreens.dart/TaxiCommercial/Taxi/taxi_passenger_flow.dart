import 'package:flutter/material.dart';

const Color taxiGreen = Color(0xFF16803C);
const Color taxiDarkGreen = Color(0xFF12652F);
const Color taxiBackground = Color(0xFFF7F8F7);

/// ============================================================
/// TAXI PASSENGER FLOW
///
/// Structure only for now.
/// 
/// sequential requests, driver acceptance, and live tracking.
/// ============================================================

class ScreenTaxiPassengerFlow extends StatefulWidget {
  final String vehicleCategory;

  const ScreenTaxiPassengerFlow({
    super.key,
    required this.vehicleCategory,
  });

  @override
  State<ScreenTaxiPassengerFlow> createState() =>
      _ScreenTaxiPassengerFlowState();
}

class _ScreenTaxiPassengerFlowState
    extends State<ScreenTaxiPassengerFlow> {
  final TextEditingController pickupController =
      TextEditingController();

  final TextEditingController dropoffController =
      TextEditingController();

  int currentStep = 0;

  bool isSearching = false;

  String driverTab = 'Live Drivers';

  final Set<String> selectedDriverIds = {};

  // TODO:
  // Replace this empty list with Firestore driver results.
  // Live drivers should be sorted by distance from pickup.
  // Logged-in drivers without live location should show
  // "Distance unavailable".
  final List<Map<String, dynamic>> drivers = [];

  @override
  void dispose() {
    pickupController.dispose();
    dropoffController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _findDrivers() {
    if (pickupController.text.trim().isEmpty) {
      _showMessage('Please enter your pickup location.');
      return;
    }

    if (dropoffController.text.trim().isEmpty) {
      _showMessage('Please enter your drop-off location.');
      return;
    }

    // TODO:
    // 1. Resolve pickup and drop-off to coordinates.
    // 2. Query live and logged-in drivers from Firestore.
    // 3. Sort live drivers by distance from pickup.
    // 4. Display actual results.
    setState(() {
      currentStep = 1;
      isSearching = false;
      selectedDriverIds.clear();
    });
  }

  void _toggleDriver(String id) {
    setState(() {
      if (selectedDriverIds.contains(id)) {
        selectedDriverIds.remove(id);
      } else {
        selectedDriverIds.add(id);
      }
    });
  }

  void _requestRide() {
    if (selectedDriverIds.isEmpty) {
      _showMessage('Please select at least one driver.');
      return;
    }

    // TODO: Call a trusted Firebase backend.
    //
    // The backend must contact drivers ONE AT A TIME,
    // allow 10 seconds for each response, and stop when
    // one driver accepts.
    //
    // Do not implement this using a client-only timer.
    // A client timer cannot safely enforce first acceptance.

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScreenTaxiRideStatus(
          vehicleCategory: widget.vehicleCategory,
          pickup: pickupController.text.trim(),
          dropoff: dropoffController.text.trim(),
          selectedDriverCount: selectedDriverIds.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: taxiBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.vehicleCategory,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: currentStep == 0
            ? _buildLocationStep()
            : _buildDriverSelectionStep(),
      ),
    );
  }

  // ==========================================================
  // STEP 1: PICKUP AND DROP-OFF
  // ==========================================================

  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Where would you like to go?',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your pickup and destination.',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 22),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _locationInput(
                  controller: pickupController,
                  label: 'Pickup location',
                  hint: 'Enter your pickup location',
                  icon: Icons.my_location,
                  iconColor: taxiGreen,
                ),

                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 24,
                      width: 1.5,
                      color: Colors.grey.shade300,
                    ),
                  ),
                ),

                _locationInput(
                  controller: dropoffController,
                  label: 'Drop-off location',
                  hint: 'Enter your destination',
                  icon: Icons.location_on_outlined,
                  iconColor: Colors.red.shade600,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5ED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: taxiDarkGreen,
                  size: 20,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Place suggestions and automatic coordinates '
                    'will be connected later.',
                    style: TextStyle(
                      fontSize: 13,
                      color: taxiDarkGreen,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _findDrivers,
              icon: const Icon(Icons.search),
              label: const Text(
                'Find a Ride',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: taxiGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: iconColor),
            filled: true,
            fillColor: const Color(0xFFF9F9F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: taxiGreen,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // STEP 2: LIVE / LOGGED-IN DRIVER SELECTION
  // ==========================================================

  Widget _buildDriverSelectionStep() {
    final filteredDrivers = drivers.where((driver) {
      return driver['availability'] == driverTab;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose your drivers',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.vehicleCategory} · '
                '${selectedDriverIds.length} selected',
                style: const TextStyle(
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _driverTabButton('Live Drivers'),
                    _driverTabButton('Logged-in Drivers'),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: filteredDrivers.isEmpty
              ? _emptyDrivers()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    16, 4, 16, 12,
                  ),
                  itemCount: filteredDrivers.length,
                  itemBuilder: (context, index) {
                    final driver = filteredDrivers[index];
                    final id = driver['uid'].toString();

                    return _driverCard(driver, id);
                  },
                ),
        ),

        if (selectedDriverIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(
              16, 12, 16, 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade200,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _requestRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: taxiGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: Text(
                  'Request a Ride (${selectedDriverIds.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _driverTabButton(String label) {
    final selected = driverTab == label;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() {
            driverTab = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? taxiDarkGreen : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyDrivers() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 54,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'Driver list will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Firestore driver search has not been connected yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _driverCard(
    Map<String, dynamic> driver,
    String id,
  ) {
    final selected = selectedDriverIds.contains(id);

    final name = (driver['name'] ?? 'Driver').toString();
    final vehicle = (driver['vehicle'] ?? '').toString();
    final distance = driver['distanceKm'];

    String distanceText = 'Distance unavailable';

    if (driverTab == 'Live Drivers' && distance is num) {
      distanceText = distance < 1
          ? '${(distance * 1000).round()} m away'
          : '${distance.toStringAsFixed(1)} km away';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: selected ? taxiGreen : Colors.grey.shade200,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: selected,
        onChanged: (_) => _toggleDriver(id),
        activeColor: taxiGreen,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            [
              if (vehicle.isNotEmpty) vehicle,
              distanceText,
            ].join(' · '),
          ),
        ),
        secondary: CircleAvatar(
          backgroundColor: const Color(0xFFEAF5ED),
          child: const Icon(
            Icons.person_outline,
            color: taxiDarkGreen,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STEP 3: RIDE REQUEST STATUS
// ============================================================

class ScreenTaxiRideStatus extends StatelessWidget {
  final String vehicleCategory;
  final String pickup;
  final String dropoff;
  final int selectedDriverCount;

  const ScreenTaxiRideStatus({
    super.key,
    required this.vehicleCategory,
    required this.pickup,
    required this.dropoff,
    required this.selectedDriverCount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: taxiBackground,
      appBar: AppBar(
        title: const Text(
          'Ride Request',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Center(
              child: Icon(
                Icons.directions_car_outlined,
                size: 65,
                color: taxiGreen,
              ),
            ),
            const SizedBox(height: 18),
            const Center(
              child: Text(
                'Ride request structure',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Driver contacting will be enabled later.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ),
            const SizedBox(height: 28),
            _detailRow('Vehicle', vehicleCategory),
            _detailRow('Pickup', pickup),
            _detailRow('Drop-off', dropoff),
            _detailRow(
              'Drivers selected',
              selectedDriverCount.toString(),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Text(
                'Future behavior: contact each selected driver '
                'one at a time. Each driver gets up to 10 seconds. '
                'Stop when one accepts, or show that no driver '
                'accepted when all attempts finish.',
                style: TextStyle(height: 1.5),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: taxiGreen,
                  side: const BorderSide(color: taxiGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: const Text('Back to Drivers'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STEP 4: TAXI RIDE CHAT STRUCTURE
// ============================================================

class ScreenTaxiRideChat extends StatelessWidget {
  final String taxiRideId;
  final String passengerUid;
  final String driverUid;
  final String pickup;
  final String dropoff;
  final String currentUserUid;

  const ScreenTaxiRideChat({
    super.key,
    required this.taxiRideId,
    required this.passengerUid,
    required this.driverUid,
    required this.pickup,
    required this.dropoff,
    required this.currentUserUid,
  });

  bool get isPassenger => currentUserUid == passengerUid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: taxiBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Taxi Ride Chat',
              style: TextStyle(
                fontSize: 17,
                color: Colors.black87,
              ),
            ),
            Text(
              'Discuss fare and ride details',
              style: TextStyle(
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Tracking panel: below header, above messages.
          _trackingPanel(),

          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ride messages will appear here',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'The existing ScreenMessage chat and '
                      'Firestore messaging will be connected later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Only the passenger sees these controls.
          if (isPassenger) _passengerRideControls(context),

          // Message composer placeholder.
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                const Expanded(
                  child: TextField(
                    enabled: false,
                    decoration: InputDecoration(
                      hintText: 'Message functionality will be connected',
                      filled: true,
                      fillColor: Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(
                          Radius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: null,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _trackingPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.directions_car,
                color: taxiGreen,
                size: 24,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Your driver is on the way',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Visual placeholder; real movement needs live GPS.
          Row(
            children: [
              const Icon(
                Icons.radio_button_checked,
                color: taxiGreen,
                size: 18,
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 4,
                      color: Colors.grey.shade300,
                    ),
                    const Icon(
                      Icons.directions_car,
                      color: taxiGreen,
                      size: 24,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 22,
              ),
            ],
          ),

          const SizedBox(height: 12),
          _locationLine('Pickup', pickup),
          const SizedBox(height: 8),
          _locationLine('Drop-off', dropoff),
          const SizedBox(height: 10),
          const Text(
            'Live distance and ETA will appear when driver GPS is connected.',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationLine(String label, String location) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 66,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            location,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _passengerRideControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                // TODO: Update the ride to cancelled through
                // a trusted backend and notify the driver.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Ride cancellation will be connected later.',
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size(0, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel Ride'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // TODO: Confirm through backend.
                // Only after confirmation should the driver
                // receive the passenger's pickup location.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Ride confirmation will be connected later.',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: taxiGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Confirm This Ride'),
            ),
          ),
        ],
      ),
    );
  }
}