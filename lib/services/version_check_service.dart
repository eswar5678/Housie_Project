import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class VersionCheckService {
  /// Checks for updates on the Google Play Store and triggers the native prompt.
  /// This is only supported on Android.
  Future<void> checkForUpdates() async {
    // Platform guard: In-app updates are Android-only
    if (!Platform.isAndroid) {
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
