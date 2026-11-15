import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:jober_india/jober_indiaScreens.dart/Message/screen_message.dart';
import 'package:jober_india/worker_data.dart';

class ScreenCategry extends StatefulWidget {
  final String jobs;
  final List<WorkerData> workers;
  const ScreenCategry({super.key, required this.jobs, required this.workers});

  @override
  State<ScreenCategry> createState() => _ScreenCategryState();
}

class _ScreenCategryState extends State<ScreenCategry> {
  final workerBox = Hive.box<WorkerData>('workerBox');

  double ownerLatitude = 0.0;

  double ownerLongitude = 0.0;

  Future<void> getOwnerLocation()async{
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied){
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever)
    {
      return;
    }
    Position position = await Geolocator.getCurrentPosition();
    if(!mounted) return;
    setState(() {
      ownerLatitude = position.latitude;
      ownerLongitude = position.longitude;
    });
  }
  @override
  void initState(){
    super.initState();
    getOwnerLocation();
  }
  @override
Widget build(BuildContext context) {
  final workers = workerBox.values
      .where((worker) => worker.job.contains(widget.jobs))
      .toList();

  return Scaffold(
    backgroundColor: const Color(0xFFFFF9FC),

    appBar: AppBar(
      title: Text(widget.jobs),
      centerTitle: true,
      backgroundColor: const Color(0xFFFFF9FC),
      elevation: 0,
    ),

    body: ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 20,
      ),

      itemCount: workers.length,

      itemBuilder: (context, index) {
        final worker = workers[index];

        final distanceMeters = Geolocator.distanceBetween(
          ownerLatitude,
          ownerLongitude,
          worker.latitude,
          worker.longitude,
        );

        final distanceKm = distanceMeters / 1000;

        return InkWell(borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ScreenMessage(
  chatUser: {
    'name': 'Worker',
    'locationName': 'Location not available',

    'profession': widget.jobs,
    'experience': worker.experience,
    'distance': distanceKm,
    'isActive': worker.availableToday,

    'role': 'worker',
  },
)
          )
          );
        },
          child: Container(
            margin: const EdgeInsets.only(bottom: 18),
          
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
          
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6EE),
              borderRadius: BorderRadius.circular(24),
            ),
          
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Worker type
                      Text(
                        widget.jobs,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF171717),
                        ),
                      ),
          
                      const SizedBox(height: 7),
          
                      // Experience
                      Text(
                        'Experience: ${worker.experience}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF555555),
                        ),
                      ),
          
                      const SizedBox(height: 5),
          
                      // Distance + availability
                      Row(
                        children: [
                          Text(
                            '${distanceKm.toStringAsFixed(1)} km away',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF555555),
                            ),
                          ),
          
                          const Spacer(),
          
                          Text(
                            worker.availableToday
                                ? '● Active'
                                : '● Not Active',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: worker.availableToday
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          
                const SizedBox(width: 12),
          
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 22,
                  color: Color(0xFFE88A00),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

}
