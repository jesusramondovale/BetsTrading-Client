import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../locale/localized_texts.dart';
import '../helpers/common.dart';

class CameraPage extends StatefulWidget {

  final String countryCode;
  CameraPage({required this.countryCode});

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(_cameras![0], ResolutionPreset.high);

    await _cameraController?.initialize();
    if (!mounted) return;

    setState(() {
      _isCameraInitialized = true;
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _captureAndProcessImage() async {
    final strings = LocalizedStrings.of(context);
    try {
      XFile picture = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(picture.path);
      final textRecognizer = TextRecognizer();

      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      String extractedId = _extractIdNumber(recognizedText.text, widget.countryCode);

      Navigator.pop(context, extractedId);
    } catch (e) {
      print('Error taking picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings?.cameraError ?? 'Error taking picture. Please try again.')),
      );
      Navigator.pop(context, null);
    }
  }

  String _extractIdNumber(String scannedText, String countryCode) {

    RegExp idExp = Common().getIDRegExpByCountry(countryCode);
    final match = idExp.firstMatch(scannedText);
    if (match != null) {
      return match.group(0) ?? "";
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    if (!_isCameraInitialized) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_cameraController!),
          _buildOverlay(strings),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _captureAndProcessImage,
        child: Icon(Icons.camera),
      ),
    );
  }

  Widget _buildOverlay(LocalizedStrings? strings) {
    return Stack(
      children: [
        Container(
          color: Colors.black.withOpacity(0.5), // Capa semitransparente
        ),
        Center(
          child: Container(
            width: 300,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.transparent, // Área recortada transparente
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                strings?.alignText ?? 'Align your ID here',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ),
        // "Recortar" la parte interior del contenedor
        Center(
          child: ClipPath(
            clipper: InvertedClipper(),
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }
}

class InvertedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height)) // Área completa
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: 300,
            height: 200,
          ),
          Radius.circular(10),
        ),
      )
      ..fillType = PathFillType.evenOdd; // Recorte invertido

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
