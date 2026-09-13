import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MangaCover extends StatelessWidget {
  final String? url;
  final double width;
  final double height;
  final double borderRadius;

  const MangaCover({
    super.key,
    required this.url,
    this.width = 56,
    this.height = 80,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final placeholderColor = Theme.of(context).dividerColor;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: url != null
            ? CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: placeholderColor),
                errorWidget: (_, __, ___) => Container(
                  color: placeholderColor,
                  child: const Icon(Icons.broken_image_outlined, size: 18),
                ),
              )
            : Container(color: placeholderColor),
      ),
    );
  }
}
