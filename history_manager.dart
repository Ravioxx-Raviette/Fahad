import 'package:my_flutter_app/database_helper.dart';
import 'package:my_flutter_app/models/verification_model.dart';

class HistoryManager {
  static final HistoryManager _instance = HistoryManager._internal();
  factory HistoryManager() => _instance;
  HistoryManager._internal();

  // Save a result to SQLite
  Future<void> addResult(VerificationResult result) async {
    await DatabaseHelper.instance.create(result);
  }

  // Fetch all results from SQLite
  Future<List<VerificationResult>> getHistory() async {
    return await DatabaseHelper.instance.readAllResults();
  }

  // --- NEW: Delete a specific result by ID ---
  Future<void> deleteResult(int id) async {
    await DatabaseHelper.instance.delete(id);
  }
}
