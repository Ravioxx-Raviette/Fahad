// lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_flutter_app/models/verification_model.dart';
import 'package:my_flutter_app/history_manager.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<VerificationResult>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _refreshHistory();
  }

  void _refreshHistory() {
    setState(() {
      _historyFuture = HistoryManager().getHistory();
    });
  }

  // Delete function
  Future<void> _deleteItem(int id) async {
    await HistoryManager().deleteResult(id);
    _refreshHistory(); // Reload the list
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Item deleted")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Verification History',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<VerificationResult>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 80,
                    color: Colors.grey[800],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No History Found',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final results = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              // We calculate this status...
              final isManipulated =
                  result.classificationResult.contains('Manipulated') ||
                  result.classificationResult.contains('Fake');

              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[800]!),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),

                  // Thumbnail
                  leading: result.imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            result.imageBytes!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.image, color: Colors.grey),

                  // Title - NOW USING THE VARIABLE TO COLOR THE TEXT
                  title: Text(
                    result.classificationResult,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      // Green if real, Red if fake
                      color: isManipulated
                          ? Colors.redAccent
                          : Colors.greenAccent,
                    ),
                  ),

                  // Date
                  subtitle: Text(
                    DateFormat.yMMMd().add_jm().format(result.verificationDate),
                    style: TextStyle(color: Colors.grey[500]),
                  ),

                  // DELETE BUTTON
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent, // Red trash can
                    ),
                    onPressed: () => _deleteItem(result.id),
                  ),

                  onTap: () {
                    // Navigate to details (view only)
                    Navigator.of(context)
                        .pushNamed(
                          '/result',
                          arguments: {'result': result, 'isNew': false},
                        )
                        .then(
                          (_) => _refreshHistory(),
                        ); // Refresh when coming back
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
