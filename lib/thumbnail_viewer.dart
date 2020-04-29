import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbnailViewer extends StatelessWidget {
  final videoFile;
  final videoDuration;

  ThumbnailViewer(
    this.videoFile,
    this.videoDuration,
  )   : assert(videoFile != null),
        assert(videoDuration != null);

  Stream<List<Uint8List>> generateThumbnail() async* {
    final String _videoPath = videoFile.path;

    double _eachPart = videoDuration / 8;

    List<Uint8List> _byteList = [];

    for (int i = 1; i <= 8; i++) {
      Uint8List _bytes;
      _bytes = await VideoThumbnail.thumbnailData(
        video: _videoPath,
        imageFormat: ImageFormat.JPEG,
        timeMs: (_eachPart * i).toInt(),
        // specify the height of the thumbnail, let the width auto-scaled to keep the source aspect ratio
        quality: 75,
      );

      _byteList.add(_bytes);

      yield _byteList;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: generateThumbnail(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Uint8List> _imageBytes = snapshot.data;
          return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: snapshot.data.length,
              itemBuilder: (context, index) {
                return Container(
                  height: 50.0,
                  width: 50.0,
                  child: Image(
                    image: MemoryImage(_imageBytes[index]),
                    fit: BoxFit.fitHeight,
                  ),
                );
              });
        } else {
          return Container(
            color: Colors.grey[900],
            height: 50,
            width: double.maxFinite,
          );
        }
      },
    );
  }
}
