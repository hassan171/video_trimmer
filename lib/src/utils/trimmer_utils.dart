import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path_provider/path_provider.dart';

/// Formats a [Duration] object to a human-readable string.
///
/// Example:
/// ```dart
/// final duration = Duration(hours: 1, minutes: 30, seconds: 15);
/// print(_formatDuration(duration)); // Output: 01:30:15
/// ```
String _formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final hours = twoDigits(duration.inHours);
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return '$hours:$minutes:$seconds';
}

// Maps quality (1–100) to FFmpeg scale (-q:v 1–31, lower is better quality)
int _mapQualityToFFmpegScale(int quality) {
  if (quality < 1) return 1; // Best quality
  if (quality > 100) return 31; // Worst quality
  return ((101 - quality) / 3.25).toInt().clamp(1, 31); // Scale 1 (best) to 31 (worst)
}

/// Generates a stream of thumbnails for a given video.
///
/// This function generates a specified number of thumbnails for a video at
/// different timestamps and yields them as a stream of lists of byte arrays.
/// The thumbnails are generated using FFmpeg and stored temporarily on the
/// device.
///
/// Parameters:
/// - `videoPath` (required): The path to the video file.
/// - `videoDuration` (required): The duration of the video in milliseconds.
/// - `numberOfThumbnails` (required): The number of thumbnails to generate.
/// - `quality` (required): The quality of the thumbnails (percentage).
/// - `onThumbnailLoadingComplete` (required): A callback function that is
///   called when all thumbnails have been generated.
///
/// Returns:
/// A stream of lists of byte arrays, where each list contains the generated
/// thumbnails up to that point.
///
/// Example usage:
/// ```dart
/// final thumbnailStream = generateThumbnail(
///   videoPath: 'path/to/video.mp4',
///   videoDuration: 60000, // 1 minute
///   numberOfThumbnails: 10,
///   quality: 50,
///   onThumbnailLoadingComplete: () {
///     print('Thumbnails generated successfully!');
///   },
/// );
///
/// await for (final thumbnails in thumbnailStream) {
///   // Process the thumbnails
/// }
/// ```
///
/// Throws:
/// An error if the thumbnails could not be generated.
Stream<List<Uint8List?>> generateThumbnail({
  required String videoPath,
  required int videoDuration,
  required int numberOfThumbnails,
  required int quality,
  required VoidCallback onThumbnailLoadingComplete,
}) async* {
  final double eachPart = videoDuration / numberOfThumbnails;

  final List<Uint8List?> thumbnailBytes = [];
  Uint8List? lastBytes;

  log('Generating thumbnails for video: $videoPath');
  log('Total thumbnails to generate: $numberOfThumbnails');
  log('Quality: $quality% (FFmpeg scale: ${_mapQualityToFFmpegScale(quality)})');
  log('---------------------------------');

  try {
    // Get the temporary directory
    final tmpDir = await getTemporaryDirectory();

    // Step 2: Generate thumbnails from the down scaled video
    for (int i = 1; i <= numberOfThumbnails; i++) {
      log('Generating thumbnail $i / $numberOfThumbnails');

      Uint8List? bytes;

      // Calculate the timestamp for the thumbnail in milliseconds
      final timestamp = (eachPart * i).toInt();
      final formattedTimestamp = _formatDuration(Duration(milliseconds: timestamp));
      final thumbnailPath = "${tmpDir.path}/thumbnail_$i.jpg";

      // Delete any existing file at the path
      if (File(thumbnailPath).existsSync()) {
        await File(thumbnailPath).delete();
      }

      // Construct and execute FFmpeg command
      final command = [
        '-ss',
        formattedTimestamp,
        '-i',
        videoPath,
        '-frames:v',
        '1',
        '-q:v',
        _mapQualityToFFmpegScale(quality).toString(),
        thumbnailPath,
      ];
      final session = await FFmpegKit.execute(command.join(' '));
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        // Read generated file and clean up
        if (File(thumbnailPath).existsSync()) {
          bytes = await File(thumbnailPath).readAsBytes();
          await File(thumbnailPath).delete();
        }
      } else {
        log('FFmpeg failed for thumbnail $i with return code: $returnCode');
      }

      // Cache and yield the thumbnail
      bytes = bytes ?? lastBytes;
      thumbnailBytes.add(bytes);
      lastBytes = bytes;

      if (thumbnailBytes.length == numberOfThumbnails) {
        onThumbnailLoadingComplete();
      }

      yield thumbnailBytes;
    }
    log('Thumbnails generated successfully!');
  } catch (e) {
    log('ERROR: Couldn\'t generate thumbnails: $e');
    yield thumbnailBytes; // Yield partial results on error
  }
}
