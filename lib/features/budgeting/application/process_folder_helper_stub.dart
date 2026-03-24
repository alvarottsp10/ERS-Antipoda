import 'process_folder_helper.dart';

ProcessFolderPlatform createProcessFolderPlatform() =>
    _UnsupportedProcessFolderPlatform();

class _UnsupportedProcessFolderPlatform implements ProcessFolderPlatform {
  @override
  bool get isSupported => false;

  @override
  Future<bool> openFolder(String path) async {
    return false;
  }
}
