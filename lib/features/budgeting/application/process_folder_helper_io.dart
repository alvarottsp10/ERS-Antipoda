import 'dart:io';

import 'package:flutter/foundation.dart';

import 'process_folder_helper.dart';

ProcessFolderPlatform createProcessFolderPlatform() => _IoProcessFolderPlatform();

class _IoProcessFolderPlatform implements ProcessFolderPlatform {
  @override
  bool get isSupported => Platform.isWindows;

  @override
  Future<bool> openFolder(String path) async {
    if (!Platform.isWindows) {
      debugPrint('Process folder open skipped: unsupported platform for path: $path');
      return false;
    }

    final directory = Directory(path);
    final exists = await directory.exists();
    debugPrint('Process folder open requested: $path');
    debugPrint('Process folder exists: $exists');

    if (!exists) {
      return false;
    }

    try {
      await Process.start(
        'explorer.exe',
        [path],
        runInShell: true,
        mode: ProcessStartMode.detached,
      );
      debugPrint('Process folder open dispatched successfully.');
      return true;
    } catch (error) {
      debugPrint('Process folder open failed: $error');
      return false;
    }
  }
}
