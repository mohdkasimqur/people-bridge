import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommonProfileService {
  CommonProfileService._();

static Future<void> saveLogin({
  required String uid,
  required String name,
  required String mobile,
  required String role,
  String? profilePhotoUrl,
}) async {
  final userBox = Hive.box('userBox');

  await userBox.put('uid', uid);
  await userBox.put('name', name);
  await userBox.put('mobile', mobile);
  await userBox.put('role', role);

  // Save the profile photo URL for the profile icon.
  if (profilePhotoUrl != null &&
      profilePhotoUrl.trim().isNotEmpty) {
    await userBox.put(
      'profilePhotoUrl',
      profilePhotoUrl.trim(),
    );
  }

  final prefs = await SharedPreferences.getInstance();

  await prefs.setBool('isLoggedIn', true);
  await prefs.setString('userRole', role);
}
  /// Gets the current user's role.
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('userRole');

    if (role != null && role.isNotEmpty) {
      return role;
    }

    final userBox = Hive.box('userBox');

    final hiveRole = userBox.get('role');

    return hiveRole?.toString();
  }

  /// Gets the current user's UID.
  static String? getUid() {
    final userBox = Hive.box('userBox');

    final uid = userBox.get('uid');

    return uid?.toString();
  }
}