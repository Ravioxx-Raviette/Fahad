import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_flutter_app/history_manager.dart';
import 'package:my_flutter_app/models/verification_model.dart';
import 'package:permission_handler/permission_handler.dart';
// --- NEW IMPORTS ---
import 'package:my_flutter_app/screens/settings_screen.dart';
import 'package:my_flutter_app/screens/batch_verification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.storage,
      Permission.photos,
      Permission.mediaLibrary,
    ].request();
  }

  void _refreshData() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Icon(
            Icons.check_circle_outline,
            color: Color.fromARGB(255, 54, 103, 57),
            size: 30,
          ),
        ),
        leadingWidth: 46,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FAHAD',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Text(
              'Image Verification',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        // --- NEW: SETTINGS BUTTON ---
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) => _refreshData());
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Action Cards ---
              _buildActionCard(
                context: context,
                icon: Icons.upload_file_outlined,
                title: 'Verify Image',
                subtitle: 'Upload and analyze',
                onTap: () async {
                  await Navigator.pushNamed(context, '/upload');
                  _refreshData();
                },
              ),
              const SizedBox(height: 12),

              // --- NEW: BATCH VERIFICATION CARD ---
              _buildActionCard(
                context: context,
                icon: Icons.layers_outlined,
                title: 'Batch Verify',
                subtitle: 'Scan multiple images',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const BatchVerificationScreen()),
                  );
                  _refreshData();
                },
              ),
              const SizedBox(height: 12),

              _buildActionCard(
                context: context,
                icon: Icons.history_outlined,
                title: 'View History',
                subtitle: 'Past verifications',
                onTap: () async {
                  await Navigator.pushNamed(context, '/history');
                  _refreshData();
                },
              ),
              const SizedBox(height: 32),

              // --- Header Text ---
              const Text(
                'Recent Verifications',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // --- Database List ---
              FutureBuilder<List<VerificationResult>>(
                future: HistoryManager().getHistory(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.green));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(
                          child: Text(
                        "No recent verifications found.",
                        style: TextStyle(color: Colors.grey),
                      )),
                    );
                  }

                  final results = snapshot.data!;
                  final recentResults = results.take(3).toList();

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentResults.length,
                    itemBuilder: (context, index) {
                      final result = recentResults[index];
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
                            vertical: 10,
                            horizontal: 16,
                          ),
                          leading: Icon(
                            isManipulated
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_outline_rounded,
                            color: isManipulated
                                ? Colors.redAccent
                                : Colors.greenAccent,
                            size: 36,
                          ),
                          title: Text(
                            result.imageFilename,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            DateFormat.yMMMd()
                                .add_jm()
                                .format(result.verificationDate),
                            style: const TextStyle(color: Colors.grey),
                          ),
                          onTap: () {
                            Navigator.of(context).pushNamed('/result',
                                arguments: {'result': result});
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[800]!),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.green.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 36,
                color: const Color.fromARGB(255, 64, 164, 68),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
