import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:my_flutter_app/models/verification_model.dart';
import 'package:my_flutter_app/deepfake_service.dart';
// --- NEW IMPORT ---
import 'package:my_flutter_app/settings_service.dart';

class UploadScreenSimple extends StatefulWidget {
  const UploadScreenSimple({super.key});

  @override
  State<UploadScreenSimple> createState() => _UploadScreenSimpleState();
}

class _UploadScreenSimpleState extends State<UploadScreenSimple> {
  File? _image;
  Uint8List? _imageBytes;
  bool _isVerifying = false;
  final DeepfakeService _deepfakeService = DeepfakeService();

  @override
  void dispose() {
    _deepfakeService.close();
    super.dispose();
  }

  Future<void> _pickImageFromFileSystem() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: kIsWeb,
        withReadStream: false,
      );

      if (result != null && result.files.isNotEmpty) {
        if (kIsWeb) {
          setState(() {
            _imageBytes = result.files.single.bytes;
            _image = null;
          });
        } else {
          final path = result.files.single.path;
          if (path != null) {
            setState(() {
              _image = File(path);
              _imageBytes = null;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _verifyNow() async {
    if (_image == null) return;
    setState(() => _isVerifying = true);

    try {
      final Map<String, double> prediction =
          await _deepfakeService.predict(_image!);
      final double realScore = prediction['real'] ?? 0.0;
      final double fakeScore = prediction['fake'] ?? 0.0;
      final double inferenceTime = prediction['inference_time'] ?? 0.0;

      // --- USE SETTINGS THRESHOLD ---
      final double threshold = SettingsService().fakeThreshold;

      String authenticityDescription;
      if (fakeScore >= threshold) {
        authenticityDescription = 'Fake';
      } else {
        authenticityDescription = 'Real';
      }

      final result = VerificationResult(
        id: DateTime.now().millisecondsSinceEpoch,
        imageFilename: _image!.path.split('/').last,
        verificationDate: DateTime.now(),
        credibilityScore: realScore,
        classificationResult: authenticityDescription,
        metadata: {
          'real_probability': realScore,
          'fake_probability': fakeScore,
          'inference_type': 'on-device-tflite',
          'inference_speed_ms': inferenceTime,
        },
        imageBytes: await _image!.readAsBytes(),
      );

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/result',
          arguments: {'result': result, 'isNew': true},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget displayImage() {
      if (_image != null) return Image.file(_image!, fit: BoxFit.cover);
      if (_imageBytes != null)
        return Image.memory(_imageBytes!, fit: BoxFit.cover);

      return InkWell(
        onTap: _pickImageFromFileSystem,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 60,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap to select an image from files',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Upload Image',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: Container(
                  width: double.infinity,
                  height: 300,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    border: Border.all(color: Colors.grey[800]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isVerifying
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.green),
                              SizedBox(height: 10),
                              Text(
                                "Analyzing...",
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        )
                      : displayImage(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isVerifying ? null : _pickImageFromFileSystem,
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('Select Image'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: (_image == null || _isVerifying) ? null : _verifyNow,
              icon: const Icon(Icons.shield_outlined),
              label: const Text('Verify Now'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 64, 164, 68),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
