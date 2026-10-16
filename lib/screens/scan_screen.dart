
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../services/settings_service.dart';
import 'dyslexia_reading_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  // Camera and OCR
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];

  bool _isCameraReady = false;
  bool _isScanning = false;

  String? _errorMessage;
  String _recognizedText = '';

  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  // Accessibility settings
  double _fontSize = 22;
  double _letterSpacing = 1.2;
  double _lineSpacing = 1.5;
  bool _highContrast = false;
  bool _dyslexiaLayout = true;

  bool get _canReadRecognizedText {
    final text = _recognizedText.trim();

    return text.isNotEmpty &&
        !text.startsWith('No text detected') &&
        !text.startsWith('Something went wrong');
  }

  @override
  void initState() {
    super.initState();
    _loadPreviewSettings();
    _initializeCamera();
  }

  // Load saved accessibility settings.
  Future<void> _loadPreviewSettings() async {
    try {
      final results = await Future.wait([
        SettingsService.getFontSize(),
        SettingsService.getLetterSpacing(),
        SettingsService.getLineSpacing(),
        SettingsService.getHighContrast(),
        SettingsService.getDyslexiaLayout(),
      ]);

      if (!mounted) return;

      setState(() {
        _fontSize = (results[0] as num).toDouble()
            .clamp(16.0, 32.0)
            .toDouble();

        _letterSpacing = (results[1] as num).toDouble()
            .clamp(0.0, 3.0)
            .toDouble();

        _lineSpacing = (results[2] as num).toDouble()
            .clamp(1.0, 2.5)
            .toDouble();

        _highContrast = results[3] as bool;
        _dyslexiaLayout = results[4] as bool;
      });
    } catch (e) {
      debugPrint('Unable to load OCR preview settings: $e');
    }
  }

  // Initialize the device camera.
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (!mounted) return;

      if (_cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No camera found.';
        });
        return;
      }

      final camera = _cameras.firstWhere(
        (camera) =>
            camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _cameraController = controller;

      await controller.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraReady = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to start camera.';
      });
    }
  }

  // Scan text using the camera.
  Future<void> _scanText() async {
    if (!_isCameraReady ||
        _cameraController == null ||
        _isScanning) {
      return;
    }

    setState(() {
      _isScanning = true;
      _recognizedText = '';
    });

    try {
      final image = await _cameraController!.takePicture();

      final inputImage = InputImage.fromFilePath(image.path);

      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      if (!mounted) return;

      setState(() {
        _recognizedText = recognizedText.text;

        if (_recognizedText.trim().isEmpty) {
          _recognizedText =
              'No text detected. Try moving the camera closer to the text.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _recognizedText =
            'Something went wrong while scanning.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  // Select an image from the gallery and recognize its text.
  Future<void> _pickImageFromGallery() async {
    if (_isScanning) return;

    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null || !mounted) return;

      setState(() {
        _isScanning = true;
        _recognizedText = '';
      });

      final inputImage = InputImage.fromFilePath(image.path);

      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      if (!mounted) return;

      setState(() {
        _recognizedText = recognizedText.text;

        if (_recognizedText.trim().isEmpty) {
          _recognizedText =
              'No text detected. Please choose an image containing text.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _recognizedText =
            'Something went wrong while scanning the image.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color pageBackground = _highContrast
        ? Colors.black
        : const Color(0xFFFFFBF2);

    final Color primaryText = _highContrast
        ? Colors.white
        : const Color(0xFF263238);

    final Color secondaryText = _highContrast
        ? Colors.white70
        : const Color(0xFF607D8B);

    final Color previewBackground =
        _highContrast ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: pageBackground,
        elevation: 0,
        title: Text(
          'Scan Text',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primaryText,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Camera preview
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _buildCameraPreview(),
              ),
            ),

            const SizedBox(height: 16),

            // Recognized text preview
            if (_recognizedText.isNotEmpty)
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: previewBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _highContrast
                          ? Colors.white
                          : const Color(0xFFE8E2D8),
                      width: _highContrast ? 2 : 1,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _recognizedText,
                      style: TextStyle(
                        fontSize: _fontSize,
                        height: _lineSpacing,
                        letterSpacing:
                            _dyslexiaLayout ? _letterSpacing : 0,
                        color: primaryText,
                      ),
                    ),
                  ),
                ),
              ),

            if (_recognizedText.isNotEmpty)
              const SizedBox(height: 16),

            // Read this text button
            if (_canReadRecognizedText)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DyslexiaReadingScreen(
                          text: _recognizedText,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.menu_book),
                  label: const Text(
                    'Read This Text',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B9FE3),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            Text(
              'Point your camera at a book, document, or sign.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: secondaryText,
              ),
            ),

            const SizedBox(height: 12),

            // Scan button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isCameraReady && !_isScanning
                    ? _scanText
                    : null,
                icon: _isScanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.document_scanner),
                label: Text(
                  _isScanning ? 'Scanning...' : 'Scan Text',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B9FE3),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Choose from gallery button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _isScanning
                    ? null
                    : _pickImageFromGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text(
                  'Choose from Gallery',
                  style: TextStyle(fontSize: 15),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF5B9FE3),
                  side: const BorderSide(
                    color: Color(0xFF5B9FE3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Build the camera preview.
  Widget _buildCameraPreview() {
    if (_errorMessage != null) {
      return Container(
        color: const Color(0xFFE8E8E8),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF455A64),
              ),
            ),
          ),
        ),
      );
    }

    if (!_isCameraReady || _cameraController == null) {
      return Container(
        color: const Color(0xFFE8E8E8),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return CameraPreview(_cameraController!);
  }
}
