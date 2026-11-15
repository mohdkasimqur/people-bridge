import 'package:hive/hive.dart';
part 'owner_data.g.dart';

@HiveType(typeId: 0)
class OwnerData extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String phone;

  @HiveField(2)
  double areaKm;

  OwnerData({
    required this.name,
    required this.phone,
    required this.areaKm,
  });
}
