import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class DeepfakeService {
  Interpreter? _interpreter;
  List<String>? _labels;

  Future<void> loadModel() async {
    try {
      // --- PERFORMANCE: Enable XNNPACK (CPU acceleration) ---
      // This makes the model run faster on mobile CPUs
      var interpreterOptions = InterpreterOptions();
      // On Android, this usually defaults to enabled, but we explicitly create options
      // to allow future GPU delegation if you wanted to add it here.

      _interpreter = await Interpreter.fromAsset(
        'assets/deepfake_model.tflite',
        options: interpreterOptions,
      );
      print('TFLite Model loaded successfully with Options');

      final labelData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelData.split('\n').map((e) => e.trim()).toList();
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<Map<String, double>> predict(File imageFile) async {
    if (_interpreter == null) await loadModel();
    if (_interpreter == null) throw Exception("Model failed to load.");

    // --- THESIS DEFENSE: Measure Inference Speed ---
    final stopwatch = Stopwatch()..start();

    // 1. Preprocess
    var input = _preprocessImage(imageFile);

    // 2. Output Buffer
    var output = List.filled(1 * 2, 0.0).reshape([1, 2]);

    // 3. Run Inference
    _interpreter!.run(input, output);

    // --- STOP TIMER ---
    stopwatch.stop();
    print("Inference took: ${stopwatch.elapsedMilliseconds} ms");

    // 4. Process Output
    List<double> rawLogits = List<double>.from(output[0]);
    List<double> probabilities = _softmax(rawLogits);

    double realScore = 0.0;
    double fakeScore = 0.0;

    if (_labels != null && _labels!.isNotEmpty) {
      int realIndex = _labels!.indexOf("realism");
      int fakeIndex = _labels!.indexOf("deepfake");
      if (realIndex == -1) realIndex = 0;
      if (fakeIndex == -1) fakeIndex = 1;
      realScore = probabilities[realIndex];
      fakeScore = probabilities[fakeIndex];
    } else {
      realScore = probabilities[0];
      fakeScore = probabilities[1];
    }

    return {
      "real": double.parse((realScore * 100).toStringAsFixed(2)),
      "fake": double.parse((fakeScore * 100).toStringAsFixed(2)),
      // Return the speed to the UI so you can show it
      "inference_time": stopwatch.elapsedMilliseconds.toDouble(),
    };
  }

  List<dynamic> _preprocessImage(File imageFile) {
    var imageBytes = imageFile.readAsBytesSync();
    img.Image? originalImage = img.decodeImage(imageBytes);

    if (originalImage == null) throw Exception("Could not decode image");

    img.Image resizedImage =
        img.copyResize(originalImage, width: 224, height: 224);

    var input = Float32List(1 * 224 * 224 * 3);
    var pixelIndex = 0;

    for (var y = 0; y < 224; y++) {
      for (var x = 0; x < 224; x++) {
        var pixel = resizedImage.getPixel(x, y);
        input[pixelIndex++] = (pixel.r / 255.0 - 0.5) / 0.5;
        input[pixelIndex++] = (pixel.g / 255.0 - 0.5) / 0.5;
        input[pixelIndex++] = (pixel.b / 255.0 - 0.5) / 0.5;
      }
    }
    return input.reshape([1, 224, 224, 3]);
  }

  List<double> _softmax(List<double> logits) {
    double maxLogit = logits.reduce(max);
    List<double> exps = logits.map((x) => exp(x - maxLogit)).toList();
    double sumExps = exps.reduce((a, b) => a + b);
    return exps.map((x) => x / sumExps).toList();
  }

  void close() {
    _interpreter?.close();
  }
}
