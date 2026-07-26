import 'dart:async';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:provider/provider.dart';
import 'package:time_price/models/detected_price_tag.dart';
import 'package:time_price/providers/app_state_provider.dart';
import 'package:time_price/services/ar_price_detector_service.dart';
import 'package:time_price/services/camera_ar_service.dart';
import 'package:time_price/ui/ar/ar_tag_overlay_painter.dart';
import 'package:time_price/ui/calculator/time_cost_display.dart';

class ArCameraScannerScreen extends StatefulWidget {
  const ArCameraScannerScreen({
    super.key,
    this.initialTags,
  });

  final List<DetectedPriceTag>? initialTags;

  @override
  State<ArCameraScannerScreen> createState() => _ArCameraScannerScreenState();
}

class _ArCameraScannerScreenState extends State<ArCameraScannerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  CameraController? _cameraController;
  TextRecognizer? _textRecognizer;

  bool _isCameraInitialized = false;
  bool _isProcessingFrame = false;
  bool _isTorchOn = false;
  bool _isFrozen = false;
  ArViewMode _viewMode = ArViewMode.compact;

  List<DetectedPriceTag> _detectedTags = [];
  DetectedPriceTag? _selectedTag;
  bool _isManualInputOpen = false;

  final TextEditingController _manualPriceController = TextEditingController();

  DateTime? _lastFrameTime;

  // Tag decay: keep tags for ~1.2 seconds (6 empty frames at 200ms rate)
  int _framesWithoutPrice = 0;
  static const int _maxFramesWithoutPrice = 6;

  // Periodic timer fallback
  Timer? _captureTimer;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    unawaited(_scanController.repeat(reverse: true));
    unawaited(_initializeRealCamera());
  }

  Future<void> _initializeRealCamera() async {
    try {
      _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('AR Camera: No cameras available');
        return;
      }

      final backCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await controller.initialize();
      if (!mounted) return;

      setState(() {
        _cameraController = controller;
        _isCameraInitialized = true;
        _detectedTags = [];
      });

      // Start live memory stream for zero-latency frame processing
      try {
        await controller.startImageStream((image) {
          if (_isFrozen || _isProcessingFrame) return;

          // Throttling: process frames every 150ms (~6.6 FPS)
          final now = DateTime.now();
          if (_lastFrameTime != null &&
              now.difference(_lastFrameTime!).inMilliseconds < 150) {
            return;
          }
          _lastFrameTime = now;

          unawaited(_processImageStreamFrame(image, backCamera));
        });
      } catch (e) {
        debugPrint('AR Camera: startImageStream fallback: $e');
        _startPeriodicCapture(backCamera);
      }
    } catch (e) {
      debugPrint('AR Camera: initialization error: $e');
    }
  }

  /// Zero-latency processing of live camera memory frames
  Future<void> _processImageStreamFrame(CameraImage image, CameraDescription camera) async {
    final recognizer = _textRecognizer;
    if (recognizer == null || !mounted) return;

    _isProcessingFrame = true;
    try {
      final rotation = CameraArService.rotationFromSensorOrientation(camera.sensorOrientation);

      final inputImage = CameraArService.inputImageFromCameraImage(
        image: image,
        camera: camera,
        rotation: rotation,
      );

      if (inputImage == null) return;

      await _runOcrOnInputImage(
        inputImage,
        Size(image.width.toDouble(), image.height.toDouble()),
        rotation,
        isFileBased: false,
      );
    } catch (e) {
      debugPrint('AR Frame processing error: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  /// Fallback mode: periodic takePicture
  void _startPeriodicCapture(CameraDescription camera) {
    _captureTimer?.cancel();
    _captureTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_isFrozen || _isProcessingFrame || !mounted) return;
      unawaited(_captureAndProcess(camera));
    });
  }

  Future<Size> _getImageFileDimensions(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final size = Size(frame.image.width.toDouble(), frame.image.height.toDouble());
      frame.image.dispose();
      return size;
    } catch (e) {
      final previewSize = _cameraController?.value.previewSize;
      return previewSize != null
          ? Size(previewSize.height, previewSize.width)
          : const Size(1080, 1920);
    }
  }

  Future<void> _captureAndProcess(CameraDescription camera) async {
    final controller = _cameraController;
    final recognizer = _textRecognizer;
    if (controller == null || recognizer == null || !mounted) return;
    if (!controller.value.isInitialized || controller.value.isTakingPicture) return;

    _isProcessingFrame = true;
    try {
      final xFile = await controller.takePicture();
      final inputImage = InputImage.fromFilePath(xFile.path);
      final imageSize = await _getImageFileDimensions(xFile);

      await _runOcrOnInputImage(
        inputImage,
        imageSize,
        InputImageRotation.rotation0deg,
        isFileBased: true,
      );
    } catch (e) {
      debugPrint('AR Capture error: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  /// Shared OCR processing for live stream and fallback
  Future<void> _runOcrOnInputImage(
    InputImage inputImage,
    Size imageSize,
    InputImageRotation rotation, {
    required bool isFileBased,
  }) async {
    final recognizer = _textRecognizer;
    if (recognizer == null || !mounted) return;

    final recognizedText = await recognizer.processImage(inputImage);
    if (!mounted) return;

    final provider = Provider.of<AppStateProvider>(context, listen: false);
    final screenSize = MediaQuery.of(context).size;

    final textBlocks = <({String text, Rect boundingBox})>[];

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final scaledBox = CameraArService.scaleBoundingBox(
          box: line.boundingBox,
          imageSize: imageSize,
          widgetSize: screenSize,
          rotation: rotation,
          isFileBased: isFileBased,
        );
        textBlocks.add((text: line.text, boundingBox: scaledBox));
      }
    }

    final newTags = ArPriceDetectorService.detectPricesFromTextBlocks(
      textBlocks: textBlocks,
      income: provider.incomeConfig,
      deductions: provider.deductions,
      tax: provider.taxConfig,
    );

    if (mounted) {
      setState(() {
        if (newTags.isNotEmpty) {
          _detectedTags = newTags;
          _framesWithoutPrice = 0;
        } else if (_detectedTags.isNotEmpty) {
          _framesWithoutPrice++;
          if (_framesWithoutPrice >= _maxFramesWithoutPrice) {
            _detectedTags = [];
            _framesWithoutPrice = 0;
          }
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_detectedTags.isEmpty && !_isCameraInitialized) {
      if (widget.initialTags != null) {
        _detectedTags = List.from(widget.initialTags!);
      } else {
        _loadDefaultSampleTags();
      }
    }
  }

  void _loadDefaultSampleTags() {
    final screenSize = MediaQuery.of(context).size;
    final provider = Provider.of<AppStateProvider>(context, listen: false);

    _detectedTags = ArPriceDetectorService.getSamplePriceTags(
      screenSize: screenSize,
      income: provider.incomeConfig,
      deductions: provider.deductions,
      tax: provider.taxConfig,
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    _manualPriceController.dispose();
    _captureTimer?.cancel();
    unawaited(_textRecognizer?.close());
    unawaited(_cameraController?.dispose());
    super.dispose();
  }

  void _onTapViewport(TapUpDetails details, Size screenSize) {
    if (_detectedTags.isEmpty) return;

    final tapPos = details.localPosition;
    DetectedPriceTag? tappedTag;

    for (final tag in _detectedTags) {
      final hitRect = tag.boundingBox.inflate(16.0);
      if (hitRect.contains(tapPos)) {
        tappedTag = tag;
        break;
      }
    }

    setState(() {
      _selectedTag = tappedTag;
    });

    if (tappedTag != null) {
      unawaited(_showTagDetailBottomSheet(tappedTag));
    }
  }

  Future<void> _showTagDetailBottomSheet(DetectedPriceTag tag) async {
    final provider = Provider.of<AppStateProvider>(context, listen: false);

    final shouldPop = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Scanned Price Tag: ${tag.rawText}',
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TimeCostDisplay(result: tag.timeCostResult),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                key: const Key('ar_apply_price_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text(
                  'Apply Price to Calculator',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  provider.updatePrice(tag.numericPrice);
                  Navigator.of(ctx).pop(true);
                },
              ),
            ],
          ),
        );
      },
    );

    if (shouldPop == true && mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _addManualPriceTag() {
    final text = _manualPriceController.text.trim();
    final price = ArPriceDetectorService.extractPrice(text);
    if (price == null) return;

    final provider = Provider.of<AppStateProvider>(context, listen: false);
    final screenSize = MediaQuery.of(context).size;

    final newTag = ArPriceDetectorService.detectPricesFromTextBlocks(
      textBlocks: [
        (
          text: '\$$price',
          boundingBox: Rect.fromLTWH(
            screenSize.width * 0.3,
            screenSize.height * 0.45,
            140,
            65,
          ),
        ),
      ],
      income: provider.incomeConfig,
      deductions: provider.deductions,
      tax: provider.taxConfig,
    ).first;

    setState(() {
      _detectedTags.add(newTag);
      _manualPriceController.clear();
      _isManualInputOpen = false;
    });
  }

  Future<void> _toggleTorch() async {
    final controller = _cameraController;
    if (controller != null && controller.value.isInitialized) {
      final newMode = _isTorchOn ? FlashMode.off : FlashMode.torch;
      await controller.setFlashMode(newMode);
    }
    setState(() {
      _isTorchOn = !_isTorchOn;
    });
  }

  Widget _buildCameraViewfinder(Size screenSize) {
    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              _isTorchOn ? Colors.amber.withValues(alpha: 0.15) : Colors.blueGrey[900]!,
              Colors.black,
            ],
          ),
        ),
        child: CustomPaint(
          size: screenSize,
          painter: _ViewfinderGridPainter(),
        ),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize?.height ?? screenSize.width,
          height: _cameraController!.value.previewSize?.width ?? screenSize.height,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Live Undistorted Camera Preview Background (BoxFit.cover)
          Positioned.fill(
            child: _buildCameraViewfinder(screenSize),
          ),

          // 2. Interactive AR Overlay Layer
          Positioned.fill(
            child: GestureDetector(
              key: const Key('ar_viewport_gesture_detector'),
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => _onTapViewport(details, screenSize),
              child: AnimatedBuilder(
                animation: _scanController,
                builder: (context, child) {
                  return CustomPaint(
                    size: screenSize,
                    painter: ArTagOverlayPainter(
                      tags: _detectedTags,
                      scanAnimationValue: _isFrozen ? 0.5 : _scanController.value,
                      viewMode: _viewMode,
                      selectedTagId: _selectedTag?.id,
                    ),
                  );
                },
              ),
            ),
          ),

          // 3. Top Header Bar
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    key: const Key('ar_back_button'),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isCameraInitialized ? Icons.videocam : Icons.camera_alt,
                        color: _isFrozen ? Colors.orangeAccent : Colors.cyanAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isFrozen
                            ? 'AR Frame Paused'
                            : _isCameraInitialized
                                ? 'Live AR Camera'
                                : 'AR Price Tag Scanner',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    key: const Key('ar_add_tag_button'),
                    icon: const Icon(Icons.add_a_photo, color: Colors.cyanAccent),
                    onPressed: () {
                      setState(() {
                        _isManualInputOpen = !_isManualInputOpen;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // 4. Manual Entry Box if toggled
          if (_isManualInputOpen)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.cyanAccent),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('ar_manual_price_input'),
                        controller: _manualPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Enter price e.g. 29.99',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('ar_submit_manual_price'),
                      icon: const Icon(Icons.send, color: Colors.cyanAccent),
                      onPressed: _addManualPriceTag,
                    ),
                  ],
                ),
              ),
            ),

          // 5. Bottom Controls Bar
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Flash / Torch Toggle
                  IconButton(
                    key: const Key('ar_flash_toggle'),
                    icon: Icon(
                      _isTorchOn ? Icons.flash_on : Icons.flash_off,
                      color: _isTorchOn ? Colors.amberAccent : Colors.white70,
                    ),
                    onPressed: _toggleTorch,
                  ),

                  // Freeze Frame / Pause Scanning
                  IconButton(
                    key: const Key('ar_freeze_toggle'),
                    icon: Icon(
                      _isFrozen ? Icons.play_arrow : Icons.pause,
                      color: _isFrozen ? Colors.greenAccent : Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        _isFrozen = !_isFrozen;
                      });
                    },
                  ),

                  // View Mode Toggle (Compact Badge vs Expanded Tag)
                  IconButton(
                    key: const Key('ar_view_mode_toggle'),
                    icon: Icon(
                      _viewMode == ArViewMode.compact ? Icons.label : Icons.label_important,
                      color: Colors.cyanAccent,
                    ),
                    onPressed: () {
                      setState(() {
                        _viewMode = _viewMode == ArViewMode.compact
                            ? ArViewMode.expanded
                            : ArViewMode.compact;
                      });
                    },
                  ),

                  // Reset / Reload Sample Tags
                  IconButton(
                    key: const Key('ar_reset_tags_button'),
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    onPressed: () {
                      setState(() {
                        _loadDefaultSampleTags();
                        _selectedTag = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewfinderGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    const gridStep = 40.0;
    for (double x = 0; x < size.width; x += gridStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
