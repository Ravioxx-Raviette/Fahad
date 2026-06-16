import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:my_flutter_app/deepfake_service.dart';
import 'package:my_flutter_app/history_manager.dart';
import 'package:my_flutter_app/models/verification_model.dart';
import 'package:my_flutter_app/settings_service.dart';

class BatchVerificationScreen extends StatefulWidget {
  const BatchVerificationScreen({super.key});

  @override
  State<BatchVerificationScreen> createState() =>
      _BatchVerificationScreenState();
}

class _BatchVerificationScreenState extends State<BatchVerificationScreen> {
  final DeepfakeService _service = DeepfakeService();
  List<File> _queue = [];
  final List<VerificationResult> _results = [];
  bool _isProcessing = false;
  double _progress = 0.0;

  @override
  void dispose() {
    _service.close();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _queue = result.paths.map((path) => File(path!)).toList();
        _results.clear();
      });
    }
  }

  Future<void> _startBatch() async {
    setState(() {
      _isProcessing = true;
      _progress = 0;
    });

    final double threshold = SettingsService().fakeThreshold;

    for (int i = 0; i < _queue.length; i++) {
      File image = _queue[i];

      // Predict
      var prediction = await _service.predict(image);

      double realScore = prediction['real']!;
      double fakeScore = prediction['fake']!;
      double inferenceTime = prediction['inference_time']!;

      String label;
      if (fakeScore >= threshold) {
        label = "Fake";
      } else {
        label = "Real";
      }

      // Create Result
      VerificationResult res = VerificationResult(
        id: DateTime.now().millisecondsSinceEpoch,
        imageFilename: image.path.split('/').last,
        verificationDate: DateTime.now(),
        credibilityScore: realScore,
        classificationResult: label,
        metadata: {
          'real_probability': realScore,
          'fake_probability': fakeScore,
          'inference_speed_ms': inferenceTime,
        },
        imageBytes: await image.readAsBytes(),
      );

      // Save to DB
      await HistoryManager().addResult(res);

      setState(() {
        _results.add(res);
        _progress = (i + 1) / _queue.length;
      });
    }

    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Batch Verification',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // --- PROGRESS BAR ---
          if (_isProcessing)
            LinearProgressIndicator(
              value: _progress,
              color: const Color.fromARGB(255, 64, 164, 68), // Tech Green
              backgroundColor: Colors.grey[800],
              minHeight: 6,
            ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // STATE 1: EMPTY (No files selected)
    if (_queue.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[800]!, width: 2),
              ),
              child: Icon(Icons.layers_outlined,
                  size: 60, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            const Text("No Images Selected",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Select multiple photos to analyze at once",
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),

            // --- REDESIGNED SELECT BUTTON ---
            FilledButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 24),
              label: const Text("Select Images",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                backgroundColor:
                    const Color.fromARGB(255, 64, 164, 68), // Cyber Green
                foregroundColor: Colors.white, // White Text/Icon
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                elevation: 8,
                shadowColor: const Color.fromARGB(255, 64, 164, 68)
                    .withOpacity(0.4), // Glowing shadow
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          ],
        ),
      );
    }

    // STATE 2: SELECTED BUT NOT STARTED (Show Grid)
    if (!_isProcessing && _results.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Queue (${_queue.length})",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              // Option to clear selection
              TextButton(
                onPressed: () {
                  setState(() => _queue.clear());
                },
                child: const Text("Clear",
                    style: TextStyle(color: Colors.redAccent)),
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            // --- GRID VIEW FOR SELECTED FILES ---
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 3 images per row
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _queue.length,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_queue[index], fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _startBatch,
            icon: const Icon(Icons.play_arrow),
            label: const Text("Start Analysis"),
            style: FilledButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 64, 164, 68),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      );
    }

    // STATE 3: PROCESSING / RESULTS (Show Cyber Cards)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _isProcessing ? "Processing..." : "Batch Complete",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            Text("${_results.length}/${_queue.length}",
                style: TextStyle(color: Colors.grey[400])),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final item = _results[index];
              final isFake = item.classificationResult.contains("Fake");

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  // --- GLOWING BORDER EFFECT ---
                  border: Border(
                    left: BorderSide(
                      color: isFake ? Colors.redAccent : Colors.greenAccent,
                      width: 4,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(item.imageBytes!,
                          width: 50, height: 50, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 16),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.imageFilename,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isFake
                                      ? Colors.red.withOpacity(0.2)
                                      : Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.classificationResult.toUpperCase(),
                                  style: TextStyle(
                                    color: isFake
                                        ? Colors.redAccent
                                        : Colors.greenAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "${item.credibilityScore.toStringAsFixed(1)}%",
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Icon Status
                    Icon(
                      isFake
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      color: isFake ? Colors.redAccent : Colors.greenAccent,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (!_isProcessing)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text("Done"),
            ),
          ),
      ],
    );
  }
}
