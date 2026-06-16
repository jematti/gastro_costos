import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ImageHelper {
  const ImageHelper._();

  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickAndSaveImage(String folderName) async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (image == null) {
      return null;
    }

    final appDirectory = await getApplicationDocumentsDirectory();
    final imagesDirectory = Directory(path.join(appDirectory.path, folderName));

    if (!await imagesDirectory.exists()) {
      await imagesDirectory.create(recursive: true);
    }

    final extension = path.extension(image.path).isEmpty
        ? '.jpg'
        : path.extension(image.path);
    final fileName =
        '${folderName}_${DateTime.now().microsecondsSinceEpoch}$extension';
    final localPath = path.join(imagesDirectory.path, fileName);

    await File(image.path).copy(localPath);
    return localPath;
  }

  static bool imageExists(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return false;
    }

    return File(imagePath).existsSync();
  }
}
