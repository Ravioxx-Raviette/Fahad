import 'dart:convert';
import 'dart:typed_data';

class VerificationResult {
  final int id;
  final String imageFilename;
  final DateTime verificationDate;
  final double credibilityScore;
  final String classificationResult;
  final Map<String, dynamic> metadata;
  final Uint8List? imageBytes;

  VerificationResult({
    required this.id,
    required this.imageFilename,
    required this.verificationDate,
    required this.credibilityScore,
    required this.classificationResult,
    required this.metadata,
    this.imageBytes,
  });

  // Convert a VerificationResult object into a Map object (for SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imageFilename': imageFilename,
      'verificationDate': verificationDate.toIso8601String(),
      'credibilityScore': credibilityScore,
      'classificationResult': classificationResult,
      // SQLite cannot store Maps, so we encode it as a JSON string
      'metadata': jsonEncode(metadata),
      // SQLite stores bytes as BLOBs
      'imageBytes': imageBytes,
    };
  }

  // Convert a Map object (from SQLite) into a VerificationResult object
  factory VerificationResult.fromMap(Map<String, dynamic> map) {
    return VerificationResult(
      id: map['id'],
      imageFilename: map['imageFilename'],
      verificationDate: DateTime.parse(map['verificationDate']),
      credibilityScore: map['credibilityScore'],
      classificationResult: map['classificationResult'],
      metadata: jsonDecode(map['metadata']),
      imageBytes: map['imageBytes'],
    );
  }
}
