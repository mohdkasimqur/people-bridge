import 'package:hive/hive.dart';
part 'worker_data.g.dart';

@HiveType(typeId: 1)
class WorkerData extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String phone;

  @HiveField(2)
  List<String> job;

  @HiveField(3)
  String experience;

  @HiveField(4)
  double latitude;

  @HiveField(5)
  double longitude;

  @HiveField(6)
  bool availableToday;

  WorkerData({
    required this.name,
    required this.phone,
    required this.job,
    required this.experience,
    required this.latitude,
    required this.longitude,
    required this.availableToday
  });
}
