import 'process_folder_helper_stub.dart'
    if (dart.library.io) 'process_folder_helper_io.dart';

abstract class ProcessFolderHelper {
  static bool get isSupported => ProcessFolderPlatform.instance.isSupported;

  static Future<bool> openFolder(String path) {
    return ProcessFolderPlatform.instance.openFolder(path);
  }
}

abstract class ProcessFolderPlatform {
  static ProcessFolderPlatform instance = createProcessFolderPlatform();

  bool get isSupported;

  Future<bool> openFolder(String path);
}
