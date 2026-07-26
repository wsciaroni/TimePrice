import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:time_price/services/camera_ar_service.dart';

class MockPlane implements Plane {
  MockPlane(this.bytes, {required this.bytesPerRow, this.bytesPerPixel, this.height, this.width});

  @override
  final Uint8List bytes;
  @override
  final int bytesPerRow;
  @override
  final int? bytesPerPixel;
  @override
  final int? height;
  @override
  final int? width;
}

class MockSinglePlaneCameraImage implements CameraImage {
  MockSinglePlaneCameraImage(Uint8List bytes)
      : _planes = [MockPlane(bytes, bytesPerRow: 4, bytesPerPixel: 1)];

  final List<Plane> _planes;

  @override
  List<Plane> get planes => _planes;
  @override
  int get width => 2;
  @override
  int get height => 2;
  @override
  ImageFormat get format => throw UnimplementedError();
  @override
  double? get lensAperture => null;
  @override
  int? get sensorExposureTime => null;
  @override
  double? get sensorSensitivity => null;
}

class MockMultiPlaneCameraImage implements CameraImage {
  MockMultiPlaneCameraImage({
    required Uint8List yBytes,
    required Uint8List uBytes,
    required Uint8List vBytes,
    required this.width,
    required this.height,
    required int yBytesPerRow,
    required int uvBytesPerRow,
    required int uvBytesPerPixel,
  }) : _planes = [
          MockPlane(yBytes, bytesPerRow: yBytesPerRow, bytesPerPixel: 1),
          MockPlane(uBytes, bytesPerRow: uvBytesPerRow, bytesPerPixel: uvBytesPerPixel),
          MockPlane(vBytes, bytesPerRow: uvBytesPerRow, bytesPerPixel: uvBytesPerPixel),
        ];

  final List<Plane> _planes;
  @override
  final int width;
  @override
  final int height;

  @override
  List<Plane> get planes => _planes;
  @override
  ImageFormat get format => throw UnimplementedError();
  @override
  double? get lensAperture => null;
  @override
  int? get sensorExposureTime => null;
  @override
  double? get sensorSensitivity => null;
}

void main() {
  group('CameraArService Unit Tests', () {
    test('rotationFromSensorOrientation returns correct InputImageRotation', () {
      expect(CameraArService.rotationFromSensorOrientation(0), InputImageRotation.rotation0deg);
      expect(CameraArService.rotationFromSensorOrientation(90), InputImageRotation.rotation90deg);
      expect(CameraArService.rotationFromSensorOrientation(180), InputImageRotation.rotation180deg);
      expect(CameraArService.rotationFromSensorOrientation(270), InputImageRotation.rotation270deg);
      expect(CameraArService.rotationFromSensorOrientation(360), InputImageRotation.rotation0deg);
    });

    test('scaleBoundingBox maps coordinates accurately for live camera frames (rotation 90deg)', () {
      const rawBox = Rect.fromLTRB(10, 20, 100, 50);
      final scaled = CameraArService.scaleBoundingBox(
        box: rawBox,
        imageSize: const Size(720, 480),
        widgetSize: const Size(1080, 2400),
        rotation: InputImageRotation.rotation90deg,
        isFileBased: false,
      );

      expect(scaled.left, closeTo(10 * 3.3333333333333335 - 260, 0.1));
      expect(scaled.top, closeTo(20 * 3.3333333333333335, 0.1));
    });

    test('scaleBoundingBox maps coordinates accurately for file-based photo captures', () {
      const rawBox = Rect.fromLTRB(100, 200, 500, 400);
      final scaled = CameraArService.scaleBoundingBox(
        box: rawBox,
        imageSize: const Size(1080, 1920),
        widgetSize: const Size(1080, 2400),
        rotation: InputImageRotation.rotation0deg,
        isFileBased: true,
      );

      expect(scaled.left, closeTo(100 * 1.25 - 135, 0.1));
      expect(scaled.top, closeTo(200 * 1.25, 0.1));
    });

    test('convertYUV420toNV21 handles single-plane NV21 input', () {
      final inputBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6]);
      final image = MockSinglePlaneCameraImage(inputBytes);
      final result = CameraArService.convertYUV420toNV21(image);

      expect(result, equals(inputBytes));
    });

    test('convertYUV420toNV21 handles multi-plane YUV420 with interleaved VU bytes', () {
      final yBytes = Uint8List.fromList([10, 20, 30, 40]);
      final uBytes = Uint8List.fromList([100, 200]);
      final vBytes = Uint8List.fromList([101, 201]);

      final image = MockMultiPlaneCameraImage(
        yBytes: yBytes,
        uBytes: uBytes,
        vBytes: vBytes,
        width: 2,
        height: 2,
        yBytesPerRow: 2,
        uvBytesPerRow: 2,
        uvBytesPerPixel: 2,
      );

      final result = CameraArService.convertYUV420toNV21(image);
      expect(result.length, 6);
      expect(result[0], 10);
      expect(result[1], 20);
      expect(result[2], 30);
      expect(result[3], 40);
    });

    test('convertYUV420toNV21 handles multi-plane YUV420 fallback pixel stride', () {
      final yBytes = Uint8List.fromList([10, 20, 30, 40]);
      final uBytes = Uint8List.fromList([100]);
      final vBytes = Uint8List.fromList([101]);

      final image = MockMultiPlaneCameraImage(
        yBytes: yBytes,
        uBytes: uBytes,
        vBytes: vBytes,
        width: 2,
        height: 2,
        yBytesPerRow: 2,
        uvBytesPerRow: 1,
        uvBytesPerPixel: 1,
      );

      final result = CameraArService.convertYUV420toNV21(image);
      expect(result.length, 6);
      expect(result[0], 10);
      expect(result[4], 101); // V byte first in NV21
      expect(result[5], 100); // U byte second in NV21
    });

    test('inputImageFromCameraImage creates InputImage correctly', () {
      final inputBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6]);
      final image = MockSinglePlaneCameraImage(inputBytes);
      const cameraDesc = CameraDescription(
        name: '0',
        lensDirection: CameraLensDirection.back,
        sensorOrientation: 90,
      );

      final inputImage = CameraArService.inputImageFromCameraImage(
        image: image,
        camera: cameraDesc,
        rotation: InputImageRotation.rotation90deg,
      );

      expect(inputImage, isNotNull);
      expect(inputImage!.metadata?.size, const Size(2, 2));
      expect(inputImage.metadata?.rotation, InputImageRotation.rotation90deg);
    });
  });
}
