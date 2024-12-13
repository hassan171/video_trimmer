import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:video_trimmer/src/utils/trimmer_utils.dart';

/// A widget for showing the thumbnails generated from the video
/// in a horizontally scrollable view, like a frame-by-frame preview.
class ScrollableThumbnailViewer extends StatefulWidget {
  /// Creates a [ScrollableThumbnailViewer] widget.
  ///
  /// - [videoFile] is the video file from which thumbnails are generated.
  /// - [videoDuration] is the total duration of the video in milliseconds.
  /// - [thumbnailHeight] is the height of each thumbnail.
  /// - [numberOfThumbnails] is the number of thumbnails to generate.
  /// - [fit] is how the thumbnails should be inscribed into the allocated space.
  /// - [scrollController] is the scroll controller for the scrollable thumbnail view.
  /// - [onThumbnailLoadingComplete] is the callback function that is called when thumbnail loading is complete.
  /// - [quality] is the quality of the generated thumbnails, ranging from 0 to 100. Defaults to 75.
  const ScrollableThumbnailViewer({
    super.key,
    required this.videoFile,
    required this.videoDuration,
    required this.thumbnailHeight,
    required this.numberOfThumbnails,
    required this.fit,
    required this.scrollController,
    required this.onThumbnailLoadingComplete,
    this.quality = 75,
  });

  /// The video file from which thumbnails are generated.
  final File videoFile;

  /// The total duration of the video in milliseconds.
  final int videoDuration;

  /// The height of each thumbnail.
  final double thumbnailHeight;

  /// The number of thumbnails to generate.
  final int numberOfThumbnails;

  /// How the thumbnails should be inscribed into the allocated space.
  final BoxFit fit;

  /// The scroll controller for the scrollable thumbnail view.
  final ScrollController scrollController;

  /// Callback function that is called when thumbnail loading is complete.
  final VoidCallback onThumbnailLoadingComplete;

  /// The quality of the generated thumbnails, ranging from 0 to 100. Defaults to 75.
  final int quality;

  @override
  State<ScrollableThumbnailViewer> createState() => _ScrollableThumbnailViewerState();
}

class _ScrollableThumbnailViewerState extends State<ScrollableThumbnailViewer> {
  /// Cache to store generated thumbnails and avoid redundant regeneration.
  late List<Uint8List?> _thumbnailCache;

  /// Stream of thumbnail data for generating thumbnails dynamically.
  late Stream<List<Uint8List?>> _thumbnailStream;

  @override
  void initState() {
    super.initState();
    _initializeThumbnails();
  }

  /// Initializes the thumbnail cache and starts the thumbnail generation stream.
  void _initializeThumbnails() {
    // Initialize the cache with placeholders (null).
    _thumbnailCache = List<Uint8List?>.filled(widget.numberOfThumbnails, null);

    // Start generating thumbnails via the stream.
    _thumbnailStream = generateThumbnail(
      videoPath: widget.videoFile.path,
      videoDuration: widget.videoDuration,
      numberOfThumbnails: widget.numberOfThumbnails,
      quality: widget.quality,
      onThumbnailLoadingComplete: widget.onThumbnailLoadingComplete,
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: widget.scrollController,
        child: SizedBox(
          width: widget.numberOfThumbnails * widget.thumbnailHeight,
          height: widget.thumbnailHeight,
          child: StreamBuilder<List<Uint8List?>>(
            stream: _thumbnailStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                // Update the cache with new thumbnails from the stream.
                List<Uint8List?> newThumbnails = snapshot.data!;
                for (int i = 0; i < newThumbnails.length; i++) {
                  if (newThumbnails[i] != null) {
                    _thumbnailCache[i] = newThumbnails[i];
                  }
                }
              }

              // Build the row of thumbnails using the cache.
              return Row(
                mainAxisSize: MainAxisSize.max,
                children: List.generate(
                  widget.numberOfThumbnails,
                  (index) => SizedBox(
                    height: widget.thumbnailHeight,
                    width: widget.thumbnailHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Display a placeholder with reduced opacity as a fallback.
                        Opacity(
                          opacity: 0.2,
                          child: Image.memory(
                            _thumbnailCache[0] ?? kTransparentImage,
                            fit: widget.fit,
                          ),
                        ),
                        // Display the actual thumbnail if available in the cache.
                        _thumbnailCache[index] != null
                            ? FadeInImage(
                                placeholder: MemoryImage(kTransparentImage),
                                image: MemoryImage(_thumbnailCache[index]!),
                                fit: widget.fit,
                              )
                            : const SizedBox(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant ScrollableThumbnailViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Regenerate thumbnails only if key parameters change.
    if (oldWidget.videoFile != widget.videoFile ||
        oldWidget.videoDuration != widget.videoDuration ||
        oldWidget.numberOfThumbnails != widget.numberOfThumbnails ||
        oldWidget.quality != widget.quality) {
      _initializeThumbnails();
    }
  }
}
