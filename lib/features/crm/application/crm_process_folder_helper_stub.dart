import 'crm_process_folder_helper.dart';

CrmProcessFolderPlatform createCrmProcessFolderPlatform() =>
    _UnsupportedCrmProcessFolderPlatform();

class _UnsupportedCrmProcessFolderPlatform
    implements CrmProcessFolderPlatform {
  @override
  bool get isSupported => false;

  @override
  Future<bool> openFolder(String path) async {
    return false;
  }

  @override
  Future<int> copyFilesToFolder({
    required List<String> sourcePaths,
    required String targetFolder,
  }) async {
    return 0;
  }

  @override
  Future<bool> folderExists(String path) async {
    return false;
  }

  @override
  Future<List<String>> pickFiles() async {
    return const [];
  }
}
