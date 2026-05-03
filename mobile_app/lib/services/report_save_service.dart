import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum SaveDestination { downloads, custom }

class SavedReport {
  SavedReport(this.displayPath, this.openTarget);

  final String displayPath;
  final String openTarget;
}

class PermissionDeniedException implements Exception {
  PermissionDeniedException({required this.permanentlyDenied});

  final bool permanentlyDenied;

  @override
  String toString() => 'Storage permission denied';
}

class ReportSaveService {
  static const String _fileName = 'dayaar_crm_report.pdf';

  Future<SavedReport?> save({
    required String tempFilePath,
    required SaveDestination destination,
  }) async {
    if (destination == SaveDestination.downloads) {
      return _saveToDownloads(tempFilePath);
    }
    return _saveToCustomLocation(tempFilePath);
  }

  Future<bool> needsLegacyStoragePermission() async {
    if (!Platform.isAndroid) return false;
    final info = await DeviceInfoPlugin().androidInfo;
    return info.version.sdkInt <= 28;
  }

  Future<PermissionStatus> checkStoragePermission() {
    return Permission.storage.status;
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }

  Future<SavedReport> _saveToDownloads(String tempFilePath) async {
    if (Platform.isAndroid) {
      await _ensureLegacyStoragePermission();
      await MediaStore.ensureInitialized();
      MediaStore.appFolder = 'DayaarCRM';
      final info = await MediaStore().saveFile(
        tempFilePath: tempFilePath,
        dirType: DirType.download,
        dirName: DirName.download,
      );
      if (info == null || info.uri.toString().isEmpty) {
        throw Exception('Failed to save report to Downloads');
      }
      return SavedReport(
        'Download/$_fileName',
        info.uri.toString(),
      );
    }

    final docs = await getApplicationDocumentsDirectory();
    final dest = File('${docs.path}/$_fileName');
    await File(tempFilePath).copy(dest.path);
    return SavedReport(dest.path, dest.path);
  }

  Future<SavedReport?> _saveToCustomLocation(String tempFilePath) async {
    final params = SaveFileDialogParams(
      sourceFilePath: tempFilePath,
      fileName: _fileName,
      mimeTypesFilter: const ['application/pdf'],
    );
    final picked = await FlutterFileDialog.saveFile(params: params);
    if (picked == null || picked.isEmpty) return null;
    return SavedReport(picked, picked);
  }

  Future<void> _ensureLegacyStoragePermission() async {
    if (!await needsLegacyStoragePermission()) return;

    var status = await Permission.storage.status;
    if (status.isGranted) return;
    if (status.isPermanentlyDenied) {
      throw PermissionDeniedException(permanentlyDenied: true);
    }

    status = await Permission.storage.request();
    if (status.isGranted) return;
    throw PermissionDeniedException(
      permanentlyDenied: status.isPermanentlyDenied,
    );
  }
}
