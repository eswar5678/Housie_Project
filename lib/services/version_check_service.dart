import 'package:firebase_database/firebase_database.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionCheckService {
  final _database = FirebaseDatabase.instance.ref('config/app_update');

  Future<Map<String, dynamic>?> checkUpdate() async {
    try {
      final snapshot = await _database.get();
      if (!snapshot.exists) return null;

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final latestVersion = data['latest_version'] as String;
      final minRequiredVersion = data['min_required_version'] as String;
      final updateUrl = data['update_url'] as String;
      final forceUpdate = data['force_update'] as bool? ?? false;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final needsUpdate = _isVersionLower(currentVersion, latestVersion);
      final isMandatory = _isVersionLower(currentVersion, minRequiredVersion) || forceUpdate;

      if (needsUpdate) {
        return {
          'needsUpdate': true,
          'isMandatory': isMandatory,
          'latestVersion': latestVersion,
          'updateUrl': updateUrl,
        };
      }
    } catch (e) {
      print('Error checking for updates: $e');
    }
    return {'needsUpdate': false};
  }

  bool _isVersionLower(String current, String latest) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final latestParts = latest.split('.').map(int.parse).toList();

      for (var i = 0; i < 3; i++) {
        final currentPart = i < currentParts.length ? currentParts[i] : 0;
        final latestPart = i < latestParts.length ? latestParts[i] : 0;

        if (currentPart < latestPart) return true;
        if (currentPart > latestPart) return false;
      }
    } catch (e) {
      print('Version parsing error: $e');
    }
    return false;
  }
}
