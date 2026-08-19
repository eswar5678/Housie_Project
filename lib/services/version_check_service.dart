import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class VersionCheckService {
  /// Checks for updates on the Google Play Store and triggers the native prompt.
  /// In-app updates are Android-only; on other platforms (including web) this
  /// is a no-op.
  Future<void> checkForUpdates() async {
    // Platform guard: in-app updates are only supported on Android.
    // Uses kIsWeb + defaultTargetPlatform instead of dart:io's Platform so the
    // code also compiles and runs on the web.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      debugPrint('VersionCheckService: In-app updates are only supported on Android.');
      return;
    }

    try {
      debugPrint('VersionCheckService: Checking for updates on Google Play Store...');
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        debugPrint('VersionCheckService: Update is available. Version Code: ${info.availableVersionCode}');

        if (info.immediateUpdateAllowed) {
          debugPrint('VersionCheckService: Performing immediate (mandatory) update...');
          await InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          debugPrint('VersionCheckService: Starting flexible (background) update...');
          await InAppUpdate.startFlexibleUpdate();
          debugPrint('VersionCheckService: Flexible update download complete. Prompting user to install...');
          await InAppUpdate.completeFlexibleUpdate();
        } else {
          debugPrint('VersionCheckService: Update available but neither immediate nor flexible updates are allowed.');
        }
      } else {
        debugPrint('VersionCheckService: App is up to date.');
      }
    } catch (e) {
      debugPrint('VersionCheckService: Error checking or performing in-app update: $e');
    }
  }
}
