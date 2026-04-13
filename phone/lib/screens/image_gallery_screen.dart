import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../models/ticket.dart';
import '../services/agent_api_client.dart';

/// Full-screen image gallery with swipe navigation and pinch-to-zoom.
///
/// Uses [PhotoViewGallery] to display image [DocRef]s fetched from pa-serve.
class ImageGalleryScreen extends StatefulWidget {
  final List<DocRef> images;
  final int initialIndex;
  final AgentApiClient client;

  const ImageGalleryScreen({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.client,
  });

  @override
  State<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;

  /// Caches fetched bytes so revisiting a page doesn't re-fetch.
  final Map<int, List<int>> _cache = {};

  /// Tracks loading state per page.
  final Map<int, bool> _loading = {};
  final Map<int, bool> _error = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    // Pre-load adjacent pages
    _ensureLoaded(_currentIndex - 1);
    _ensureLoaded(_currentIndex);
    _ensureLoaded(_currentIndex + 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _ensureLoaded(int index) {
    if (index < 0 || index >= widget.images.length) return;
    if (_cache.containsKey(index) || _loading[index] == true) return;
    _loading[index] = true;
    widget.client.getImageBytes(widget.images[index].path).then((bytes) {
      if (mounted) {
        setState(() {
          _cache[index] = bytes;
          _loading[index] = false;
        });
      }
    }).catchError((_) {
      if (mounted) {
        setState(() {
          _error[index] = true;
          _loading[index] = false;
        });
      }
    });
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _ensureLoaded(index - 1);
    _ensureLoaded(index + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: PhotoViewGallery.builder(
        pageController: _pageController,
        itemCount: widget.images.length,
        onPageChanged: _onPageChanged,
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: _cache[index] != null
                ? MemoryImage(Uint8List.fromList(_cache[index]!))
                : null,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
            errorBuilder: (_, __, ___) => _ErrorPage(
              onRetry: () {
                setState(() {
                  _cache.remove(index);
                  _error.remove(index);
                  _loading.remove(index);
                });
                _ensureLoaded(index);
              },
            ),
          );
        },
        backgroundDecoration: const BoxDecoration(color: Colors.black),
      ),
    );
  }
}

class _ErrorPage extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorPage({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image, color: Colors.grey, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Could not load image',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
