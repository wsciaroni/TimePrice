import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CameraArService {
  /// Convert YUV_420_888 / NV21 CameraImage planes to single NV21 Uint8List.
  static Uint8List convertYUV420toNV21(CameraImage image) {
    if (image.planes.length == 1) {
      return image.planes[0].bytes;
    }

    final int width = image.width;
    final int height = image.height;
    final int ySize = width * height;
    final int uvSize = width * height ~/ 2;
    final nv21 = Uint8List(ySize + uvSize);

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    // Y plane
    if (yPlane.bytesPerRow == width) {
      nv21.setRange(0, ySize, yPlane.bytes);
    } else {
      for (int row = 0; row < height; row++) {
        final srcOffset = row * yPlane.bytesPerRow;
        final dstOffset = row * width;
        nv21.setRange(
          dstOffset,
          dstOffset + width,
          yPlane.bytes.buffer.asUint8List(yPlane.bytes.offsetInBytes + srcOffset, width),
        );
      }
    }

    // Interleave VU planes
    final int uvWidth = width ~/ 2;
    final int uvHeight = height ~/ 2;

    if (vPlane.bytesPerPixel == 2 && uPlane.bytesPerPixel == 2) {
      final int uvRowLength = uvWidth * 2;
      for (int row = 0; row < uvHeight; row++) {
        final srcOffset = row * vPlane.bytesPerRow;
        final dstOffset = ySize + row * uvRowLength;
        nv21.setRange(
          dstOffset,
          dstOffset + uvRowLength,
          vPlane.bytes.buffer.asUint8List(vPlane.bytes.offsetInBytes + srcOffset, uvRowLength),
        );
      }
    } else {
      int uvIndex = ySize;
      final int vPixelStride = vPlane.bytesPerPixel ?? 1;
      final int uPixelStride = uPlane.bytesPerPixel ?? 1;
      for (int row = 0; row < uvHeight; row++) {
        for (int col = 0; col < uvWidth; col++) {
          final vOffset = row * vPlane.bytesPerRow + col * vPixelStride;
          final uOffset = row * uPlane.bytesPerRow + col * uPixelStride;
          nv21[uvIndex++] = vPlane.bytes[vOffset];
          nv21[uvIndex++] = uPlane.bytes[uOffset];
        }
      }
    }

    return nv21;
  }

  static InputImage? inputImageFromCameraImage({
    required CameraImage image,
    required CameraDescription camera,
    required InputImageRotation rotation,
  }) {
    try {
      final nv21Bytes = convertYUV420toNV21(image);

      return InputImage.fromBytes(
        bytes: nv21Bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('CameraArService conversion error: $e');
      return null;
    }
  }

  static InputImageRotation rotationFromSensorOrientation(int sensorOrientation) {
    switch (sensorOrientation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      case 0:
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  /// Scale ML Kit bounding box from camera space to screen viewport space using BoxFit.cover.
  static Rect scaleBoundingBox({
    required Rect box,
    required Size imageSize, // Raw camera frame size (width, height) e.g. 720x480
    required Size widgetSize, // Screen size e.g. 1080x2400
    required InputImageRotation rotation,
    required bool isFileBased,
  }) {
    // When rotation is 90° or 270°, the ML Kit bounding box is already returned in upright portrait space (0..height, 0..width)
    final bool isRotated = !isFileBased &&
        (rotation == InputImageRotation.rotation90deg ||
            rotation == InputImageRotation.rotation270deg);

    final double imgW = isRotated ? imageSize.height : imageSize.width;
    final double imgH = isRotated ? imageSize.width : imageSize.height;

    // BoxFit.cover scaling calculation
    final double scaleX = widgetSize.width / imgW;
    final double scaleY = widgetSize.height / imgH;
    final double scale = max(scaleX, scaleY);

    final double renderedWidth = imgW * scale;
    final double renderedHeight = imgH * scale;

    final double offsetX = (widgetSize.width - renderedWidth) / 2.0;
    final double offsetY = (widgetSize.height - renderedHeight) / 2.0;

    return Rect.fromLTRB(
      box.left * scale + offsetX,
      box.top * scale + offsetY,
      box.right * scale + offsetX,
      box.bottom * scale + offsetY,
    );
  }
}
