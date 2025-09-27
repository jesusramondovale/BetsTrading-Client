import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../config/config.dart';
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

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(_cameras![0], ResolutionPreset.high);

    await _cameraController?.initialize();
    if (!mounted) return;

    setState(() {
      _isCameraInitialized = true;
    });
  }

  Future<void> _captureAndProcessImage() async {
    final strings = LocalizedStrings.of(context);
    try {
      XFile picture = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(picture.path);
      final textRecognizer = TextRecognizer();

      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      String extractedId =
          _extractIdNumber(recognizedText.text, widget.countryCode);

      Navigator.pop(context, extractedId);
    } catch (e) {
      print('Error taking picture: $e');
      Common().showFloatingSnack(
        context,
        strings?.get('cameraError') ??
            'Error taking picture. Please try again.',
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

  Widget _buildOverlay(LocalizedStrings? strings) {
    final Size screen = MediaQuery.of(context).size;
    final double boxWidth = screen.width * 0.75;
    final double boxHeight = screen.height * 0.25;
    const double boxRadius = 10;

    return Stack(
      children: [

        Container(
          color: Colors.black.withValues(alpha: .2),
        ),

        Positioned(
          left: (screen.width - boxWidth) / 2,
          top: (screen.height - boxHeight) / 2,
          child: Container(
            padding: EdgeInsetsGeometry.all(16),
            width: boxWidth,
            height: boxHeight,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(boxRadius),
            ),
            alignment: Alignment.center,
            child: Text(
              strings?.get('alignText') ?? 'Align your ID here',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),

        // Clip de oscurecimiento alrededor
        ClipPath(
          clipper: InvertedClipper(),
          child: Container(
            color: Colors.black.withValues(alpha: .75),
          ),
        ),

        Positioned(
          left: 0,
          right: 0,
          top: (screen.height - boxHeight) / 2 + boxHeight + 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/new_icon_white.png', width: 35),
              const SizedBox(width: 8),
              Text.rich(
                TextSpan(
                  text: Common().capitalizeFirst(
                    strings?.get('termsAndConditions')?.trim() ??
                        'terms and conditions',
                  ),
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Common().openInAppBrowser(
                        context,
                        Config.TERMS_N_CONDITIONS_PAGE,
                      );
                    },
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    if (!_isCameraInitialized) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(_cameraController!),
          ),
          // Overlay
          _buildOverlay(strings),
          Positioned(
            bottom: 20,
            left: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white70,
              onPressed: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: SizedBox(
              width: 150,
              height: 50,
              child: FloatingActionButton(
                backgroundColor: Colors.white70,
                onPressed: _captureAndProcessImage,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(FontAwesomeIcons.cameraRetro),
                    const SizedBox(width: 10),
                    Text(
                      " ${strings?.get('takePhoto') ?? "Take photo"}",
                      style: GoogleFonts.montserrat(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InvertedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final double boxWidth = size.width * 0.75;
    final double boxHeight = size.height * 0.25;
    const double boxRadius = 10;

    Path path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: boxWidth,
            height: boxHeight,
          ),
          const Radius.circular(boxRadius),
        ),
      )
      ..fillType = PathFillType.evenOdd;

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
