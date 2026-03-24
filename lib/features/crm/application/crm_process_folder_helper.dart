import 'crm_process_folder_helper_stub.dart'
    if (dart.library.io) 'crm_process_folder_helper_io.dart';

abstract class CrmProcessFolderHelper {
  static bool get isSupported => CrmProcessFolderPlatform.instance.isSupported;

  static Future<bool> openFolder(String path) {
    return CrmProcessFolderPlatform.instance.openFolder(path);
  }

  static Future<bool> folderExists(String path) {
    return CrmProcessFolderPlatform.instance.folderExists(path);
  }

  static Future<List<String>> pickFiles() {
    return CrmProcessFolderPlatform.instance.pickFiles();
  }

  static Future<int> copyFilesToFolder({
    required List<String> sourcePaths,
    required String targetFolder,
  }) {
    return CrmProcessFolderPlatform.instance.copyFilesToFolder(
      sourcePaths: sourcePaths,
      targetFolder: targetFolder,
    );
  }
}

abstract class CrmProcessFolderPlatform {
  static CrmProcessFolderPlatform instance = createCrmProcessFolderPlatform();

  bool get isSupported;

  Future<bool> openFolder(String path);

  Future<bool> folderExists(String path);

  Future<List<String>> pickFiles();

  Future<int> copyFilesToFolder({
    required List<String> sourcePaths,
    required String targetFolder,
  });
}
