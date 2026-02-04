import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import '../utils/colors.dart';

class ImageViewerWidget extends StatelessWidget {
  final String imagePath;
  final String? imageUrl;
  final String? title;
  final VoidCallback? onDelete;

  const ImageViewerWidget({
    super.key,
    required this.imagePath,
    this.imageUrl,
    this.title,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: title != null
            ? Text(
                title!,
                style: const TextStyle(color: Colors.white),
              )
            : null,
        actions: [
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
                onDelete?.call();
              },
            ),
        ],
      ),
      body: PhotoView(
        imageProvider: _getImageProvider(),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        loadingBuilder: (context, event) => Center(
          child: CircularProgressIndicator(
            value: event != null && event.expectedTotalBytes != null
                ? event.cumulativeBytesLoaded / event.expectedTotalBytes!
                : null,
            color: Colors.white,
          ),
        ),
        errorBuilder: (context, error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.grey[400], size: 48),
              const SizedBox(height: 16),
              Text(
                'Không thể tải hình ảnh',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider _getImageProvider() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return NetworkImage(imageUrl!);
    }
    return FileImage(File(imagePath));
  }
}

/// Widget hiển thị hình ảnh nhỏ (thumbnail)
class ImageThumbnailWidget extends StatelessWidget {
  final String? imagePath;
  final String? imageUrl;
  final double size;
  final double borderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ImageThumbnailWidget({
    super.key,
    this.imagePath,
    this.imageUrl,
    this.size = 60,
    this.borderRadius = 8,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = (imagePath != null && imagePath!.isNotEmpty) ||
        (imageUrl != null && imageUrl!.isNotEmpty);

    if (!hasImage) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap ?? () => _openViewer(context),
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: _buildImage(),
            ),
          ),
          if (onDelete != null)
            Positioned(
              top: -4,
              right: -4,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoading();
        },
      );
    }

    if (imagePath != null && imagePath!.isNotEmpty) {
      final file = File(imagePath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      }
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Icon(
        Icons.image,
        color: Colors.grey[400],
        size: size * 0.4,
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: SizedBox(
          width: size * 0.3,
          height: size * 0.3,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  void _openViewer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewerWidget(
          imagePath: imagePath ?? '',
          imageUrl: imageUrl,
          onDelete: onDelete,
        ),
      ),
    );
  }
}
