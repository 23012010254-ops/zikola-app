import 'dart:convert';
import 'package:flutter/material.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String? base64Image;
  final String? imageUrl;
  final String tag;

  const FullScreenImageViewer({
    super.key,
    this.base64Image,
    this.imageUrl,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Hero(
              tag: tag,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: base64Image != null
                    ? Image.memory(
                        base64Decode(base64Image!),
                        fit: BoxFit.contain,
                      )
                    : imageUrl != null
                        ? Image.network(
                            imageUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.broken_image,
                              color: Colors.white,
                              size: 50,
                            ),
                          )
                        : const Icon(
                            Icons.image,
                            color: Colors.white,
                            size: 50,
                          ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
