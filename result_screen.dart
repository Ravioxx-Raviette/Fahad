import 'package:flutter/material.dart';
import 'package:my_flutter_app/models/verification_model.dart';
import 'package:my_flutter_app/history_manager.dart';
import 'package:my_flutter_app/pdf_service.dart';
// --- NEW IMPORT ---
import 'package:my_flutter_app/settings_service.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Extract arguments
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final VerificationResult result = args['result'];
    final bool isNew = args['isNew'] ?? false;

    // 2. Logic for Colors
    final bool isManipulated =
        result.classificationResult.contains('Manipulated') ||
            result.classificationResult.contains('Fake');
    final Color resultColor = isManipulated ? Colors.red : Colors.green;

    // Retrieve scores
    final double realScore =
        result.metadata['real_probability'] ?? result.credibilityScore;
    final double fakeScore =
        result.metadata['fake_probability'] ?? (100.0 - realScore);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Verification Result',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        // --- PDF BUTTON ---
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Export Report",
            onPressed: () async {
              final pdfService = PdfService();
              await pdfService.generateAndPrint(result);
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- IMAGE ---
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: result.imageBytes != null
                          ? Image.memory(result.imageBytes!,
                              height: 200, width: 200, fit: BoxFit.cover)
                          : const Icon(Icons.image_not_supported,
                              size: 100, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- MAIN SCORE ---
                  Text(
                    'Credibility Score',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                  ),
                  Text(
                    '${result.credibilityScore.toStringAsFixed(1)}%',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: resultColor,
                    ),
                  ),

                  // --- CLASSIFICATION CHIP ---
                  Center(
                    child: Chip(
                      label: Text(
                        result.classificationResult,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isManipulated
                              ? Colors.red.shade900
                              : Colors.green.shade900,
                        ),
                      ),
                      backgroundColor: isManipulated
                          ? Colors.red.shade100
                          : Colors.green.shade100,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- THESIS FEATURE: INFERENCE SPEED DISPLAY ---
                  // Only show if Debug Mode is ON
                  if (SettingsService().isDebugMode &&
                      result.metadata.containsKey('inference_speed_ms'))
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.yellow.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.yellow)),
                        child: Text(
                          "⚡ Inference: ${result.metadata['inference_speed_ms']} ms",
                          style: const TextStyle(
                              color: Colors.yellowAccent,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  if (SettingsService().isDebugMode &&
                      result.metadata.containsKey('inference_speed_ms'))
                    const SizedBox(height: 16),

                  // --- DETAILED BREAKDOWN (Real vs Fake) ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Text("Real",
                                  style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text("${realScore.toStringAsFixed(1)}%",
                                  style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey[700]), // Divider
                        Expanded(
                          child: Column(
                            children: [
                              const Text("Fake",
                                  style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text("${fakeScore.toStringAsFixed(1)}%",
                                  style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- METADATA SECTION ---
                  const Text(
                    "Technical Metadata",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: result.metadata.isEmpty
                        ? const Text("No metadata available",
                            style: TextStyle(color: Colors.grey))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: result.metadata.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      entry.key
                                          .replaceAll('_', ' ')
                                          .toUpperCase(),
                                      style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12),
                                    ),
                                    Text(
                                      entry.value.toString(),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),
          ),

          // --- BOTTOM BUTTONS AREA ---
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: isNew
                ? Row(
                    children: [
                      // --- DISCARD BUTTON (New Scan) ---
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(
                                context); // Just go back without saving
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text("Discard"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // --- SAVE BUTTON (New Scan) ---
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            await HistoryManager().addResult(result);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Saved to History!"),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                              Navigator.pop(context); // Go back home
                            }
                          },
                          icon: const Icon(Icons.save),
                          label: const Text("Save"),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 64, 164, 68),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      // --- DELETE BUTTON (History Item) ---
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await HistoryManager().deleteResult(result.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Deleted from History"),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                              Navigator.pop(context); // Go back to history list
                            }
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text("Delete"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // --- CLOSE BUTTON (History Item) ---
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text("Close"),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
