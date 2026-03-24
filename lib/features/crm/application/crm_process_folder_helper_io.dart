import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'crm_process_folder_helper.dart';

CrmProcessFolderPlatform createCrmProcessFolderPlatform() =>
    _IoCrmProcessFolderPlatform();

class _IoCrmProcessFolderPlatform implements CrmProcessFolderPlatform {
  @override
  bool get isSupported => Platform.isWindows;

  @override
  Future<bool> openFolder(String path) async {
    if (!Platform.isWindows) {
      return false;
    }

    final exists = await Directory(path).exists();
    debugPrint('CRM folder open requested: $path');
    debugPrint('CRM folder open exists: $exists');
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
      return true;
    } catch (error) {
      debugPrint('CRM folder open failed: $error');
      return false;
    }
  }

  @override
  Future<int> copyFilesToFolder({
    required List<String> sourcePaths,
    required String targetFolder,
  }) async {
    if (!Platform.isWindows) {
      return 0;
    }

    final targetDirectory = Directory(targetFolder);
    if (!await targetDirectory.exists()) {
      debugPrint('CRM upload target folder missing: $targetFolder');
      return 0;
    }

    var copied = 0;
    for (final sourcePath in sourcePaths) {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        continue;
      }

      final fileName = sourcePath.split(Platform.pathSeparator).last;
      final destinationPath =
          '${targetDirectory.path}${Platform.pathSeparator}$fileName';

      await sourceFile.copy(destinationPath);
      copied++;
    }

    debugPrint('CRM upload copied files: $copied to $targetFolder');
    return copied;
  }

  @override
  Future<bool> folderExists(String path) async {
    if (!Platform.isWindows) {
      return false;
    }

    final exists = await Directory(path).exists();
    debugPrint('CRM folder exists [$path]: $exists');
    return exists;
  }

  @override
  Future<List<String>> pickFiles() async {
    if (!Platform.isWindows) {
      return const [];
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
      withData: false,
    );

    if (result == null) {
      return const [];
    }

    return result.files
        .map((file) => file.path)
        .whereType<String>()
        .where((path) => path.trim().isNotEmpty)
        .toList(growable: false);
  }
}
