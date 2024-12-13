import 'dart:async';
import 'dart:io';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path/path.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/src/utils/file_formats.dart';
import 'package:video_trimmer/src/utils/storage_dir.dart';

enum TrimmerEvent { initialized }

/// Helps in loading video from file, saving trimmed video to a file
/// and gives video playback controls. Some of the helpful methods
/// are:
/// - [loadVideo()]
/// - [saveTrimmedVideo()]
/// - [videoPlaybackControl()]
class Trimmer {
  // final FlutterFFmpeg _flutterFFmpeg = FFmpegKit();

  final StreamController<TrimmerEvent> _controller = StreamController<TrimmerEvent>.broadcast();

  VideoPlayerController? _videoPlayerController;

  VideoPlayerController? get videoPlayerController => _videoPlayerController;

  File? currentVideoFile;

  /// Listen to this stream to catch the events
  Stream<TrimmerEvent> get eventStream => _controller.stream;

  /// Loads a video using the path provided.
  ///
  /// Returns the loaded video file.
  Future<void> loadVideo({required File videoFile}) async {
    currentVideoFile = videoFile;
    if (videoFile.existsSync()) {
      _videoPlayerController = VideoPlayerController.file(currentVideoFile!);
      await _videoPlayerController!.initialize().then((_) {
        _controller.add(TrimmerEvent.initialized);
      });
    }
  }

  Future<String> _createFolderInAppDocDir(
    String folderName,
    StorageDir? storageDir,
  ) async {
    Directory? directory;

    if (storageDir == null) {
      directory = await getApplicationDocumentsDirectory();
    } else {
      switch (storageDir.toString()) {
        case 'temporaryDirectory':
          directory = await getTemporaryDirectory();
          break;

        case 'applicationDocumentsDirectory':
          directory = await getApplicationDocumentsDirectory();
          break;

        case 'externalStorageDirectory':
          directory = await getExternalStorageDirectory();
          break;
      }
    }

    // Directory + folder name
    final Directory directoryFolder = Directory('${directory!.path}/$folderName/');

    if (await directoryFolder.exists()) {
      // If folder already exists return path
      debugPrint('Exists');
      return directoryFolder.path;
    } else {
      debugPrint('Creating');
      // If folder does not exists create folder and then return its path
      final Directory directoryNewFolder = await directoryFolder.create(recursive: true);
      return directoryNewFolder.path;
    }
  }

  /// Saves the trimmed video to file system.
  ///
  ///
  /// The required parameters are [startValue], [endValue] & [onSave].
  ///
  /// The optional parameters are [videoFolderName], [videoFileName],
  /// [outputFormat], [fpsGIF], [scaleGIF], [applyVideoEncoding].
  ///
  /// The `@required` parameter [startValue] is for providing a starting point
  /// to the trimmed video. To be specified in `milliseconds`.
  ///
  /// The `@required` parameter [endValue] is for providing an ending point
  /// to the trimmed video. To be specified in `milliseconds`.
  ///
  /// The `@required` parameter [onSave] is a callback Function that helps to
  /// retrieve the output path as the FFmpeg processing is complete. Returns a
  /// `String`.
  ///
  /// The parameter [videoFolderName] is used to
  /// pass a folder name which will be used for creating a new
  /// folder in the selected directory. The default value for
  /// it is `Trimmer`.
  ///
  /// The parameter [videoFileName] is used for giving
  /// a new name to the trimmed video file. By default the
  /// trimmed video is named as `<original_file_name>_trimmed.mp4`.
  ///
  /// The parameter [outputFormat] is used for providing a
  /// file format to the trimmed video. This only accepts value
  /// of [FileFormat] type. By default it is set to `FileFormat.mp4`,
  /// which is for `mp4` files.
  ///
  /// The parameter [storageDir] can be used for providing a storage
  /// location option. It accepts only [StorageDir] values. By default
  /// it is set to [applicationDocumentsDirectory]. Some of the
  /// storage types are:
  ///
  /// * [temporaryDirectory] (Only accessible from inside the app, can be
  /// cleared at anytime)
  ///
  /// * [applicationDocumentsDirectory] (Only accessible from inside the app)
  ///
  /// * [externalStorageDirectory] (Supports only `Android`, accessible externally)
  ///
  /// The parameters [fpsGIF] & [scaleGIF] are used only if the
  /// selected output format is `FileFormat.gif`.
  ///
  /// * [fpsGIF] for providing a FPS value (by default it is set
  /// to `10`)
  ///
  ///
  /// * [scaleGIF] for proving a width to output GIF, the height
  /// is selected by maintaining the aspect ratio automatically (by
  /// default it is set to `480`)
  ///
  ///
  /// * [applyVideoEncoding] for specifying whether to apply video
  /// encoding (by default it is set to `false`).
  ///
  ///
  /// ADVANCED OPTION:
  ///
  /// If you want to give custom `FFmpeg` command, then define
  /// [ffmpegCommand] & [customVideoFormat] strings. The `input path`,
  /// `output path`, `start` and `end` position is already define.
  ///
  /// NOTE: The advanced option does not provide any safety check, so if wrong
  /// video format is passed in [customVideoFormat], then the app may
  /// crash.
  ///
  Future<void> saveTrimmedVideo({
    required double startValue,
    required double endValue,
    required Function(String outputPath) onSave,
    required Function(String errorMessage) onError,
    bool applyVideoEncoding = false,
    FileFormat? outputFormat,
    String? ffmpegCommand,
    String? customVideoFormat,
    int? fpsGIF,
    int? scaleGIF,
    String? videoFolderName,
    String? videoFileName,
    StorageDir? storageDir,
    double? minDuration,
  }) async {
    // Validate input parameters
    if (currentVideoFile == null || !currentVideoFile!.existsSync()) {
      debugPrint("ERROR: Current video file does not exist.");
      onError("Video file does not exist or is invalid.");
      return;
    }

    if (startValue >= endValue) {
      debugPrint("ERROR: Invalid start and end values. Start must be less than end.");
      onError("Start value cannot be greater than or equal to end value.");
      return;
    }

    // Enforce minimum duration if specified
    double duration = endValue - startValue;
    if (minDuration != null && duration < minDuration) {
      double adjustment = minDuration - duration;

      if (endValue + adjustment <= currentVideoFile!.lengthSync()) {
        debugPrint("WARNING: Adjusting end value to meet minimum duration.");
        endValue += adjustment;
      } else {
        debugPrint("ERROR: Video segment is too short and cannot meet minimum duration.");
        onError("Video segment duration is too short to meet the minimum duration.");
        return;
      }
    }

    // Set defaults
    outputFormat ??= FileFormat.mp4;
    fpsGIF ??= 10;
    scaleGIF ??= 480;

    // Prepare file paths and names
    final String videoPath = currentVideoFile!.path;
    final String videoName = basenameWithoutExtension(videoPath);
    final String dateTime = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    videoFolderName ??= "Trimmer";
    videoFileName ??= "${videoName}_trimmed_$dateTime".replaceAll(RegExp(r'[: ]'), '_');

    String outputDirectory = await _createFolderInAppDocDir(videoFolderName, storageDir);
    debugPrint("Trimmer folder path: $outputDirectory");

    String outputPath = '$outputDirectory/$videoFileName${outputFormat.toString()}';
    debugPrint('Output Path: $outputPath');

    // Format timestamps
    String formattedStart = _formatDuration(Duration(milliseconds: startValue.toInt()));
    String formattedEnd = _formatDuration(Duration(milliseconds: endValue.toInt() - startValue.toInt()));

    // Construct FFmpeg command
    final StringBuffer commandBuffer = StringBuffer()
      ..write('-ss $formattedStart ')
      ..write('-i "$videoPath" ')
      ..write('-t $formattedEnd ')
      ..write('-avoid_negative_ts make_zero ');

    if (ffmpegCommand == null) {
      commandBuffer.write('-c:a copy ');
      if (!applyVideoEncoding) {
        commandBuffer.write('-c:v copy ');
      }

      if (outputFormat == FileFormat.gif) {
        commandBuffer.write('-vf "fps=$fpsGIF,scale=$scaleGIF:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 ');
      }
    } else {
      commandBuffer.write('$ffmpegCommand ');
    }

    commandBuffer.write('"$outputPath"');
    String command = commandBuffer.toString();

    debugPrint('FFmpeg Command: $command');

    // Execute FFmpeg command
    FFmpegKit.executeAsync(command, (session) async {
      final state = await session.getState();
      final returnCode = await session.getReturnCode();
      final failStackTrace = await session.getFailStackTrace();

      debugPrint("FFmpeg process exited with state: ${FFmpegKitConfig.sessionStateToString(state)}");
      debugPrint("Return code: $returnCode");

      if (ReturnCode.isSuccess(returnCode)) {
        debugPrint("FFmpeg processing completed successfully.");
        onSave(outputPath);
      } else {
        debugPrint("FFmpeg processing failed with error: $failStackTrace");
        onError("FFmpeg processing failed: $failStackTrace");
      }
    });
  }

  /// Helper to format duration into FFmpeg-compatible timestamp
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final milliseconds = (duration.inMilliseconds % 1000).toString().padLeft(3, '0');
    return "$hours:$minutes:$seconds.$milliseconds";
  }

  /// For getting the video controller state, to know whether the
  /// video is playing or paused currently.
  ///
  /// The two required parameters are [startValue] & [endValue]
  ///
  /// * [startValue] is the current starting point of the video.
  /// * [endValue] is the current ending point of the video.
  ///
  /// Returns a `Future<bool>`, if `true` then video is playing
  /// otherwise paused.
  Future<bool> videoPlaybackControl({
    required double startValue,
    required double endValue,
  }) async {
    if (videoPlayerController!.value.isPlaying) {
      await videoPlayerController!.pause();
      return false;
    } else {
      if (videoPlayerController!.value.position.inMilliseconds >= endValue.toInt()) {
        await videoPlayerController!.seekTo(Duration(milliseconds: startValue.toInt()));
        await videoPlayerController!.play();
        return true;
      } else {
        await videoPlayerController!.play();
        return true;
      }
    }
  }

  /// Clean up
  void dispose() {
    _controller.close();
  }
}
