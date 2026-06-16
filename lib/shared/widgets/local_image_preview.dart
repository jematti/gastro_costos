import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/helpers/image_helper.dart';

class LocalImagePreview extends StatelessWidget {
  const LocalImagePreview({
    required this.imagePath,
    required this.size,
    required this.fallbackIcon,
    super.key,
  });

  final String? imagePath;
  final double size;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final localPath = imagePath;

    if (ImageHelper.imageExists(localPath)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(localPath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              _FallbackIcon(size: size, icon: fallbackIcon),
        ),
      );
    }

    return _FallbackIcon(size: size, icon: fallbackIcon);
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon({required this.size, required this.icon});

  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
