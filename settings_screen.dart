import 'package:flutter/material.dart';
import 'package:my_flutter_app/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = SettingsService();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Thesis Defense Controls",
            style: TextStyle(
                color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // --- DEBUG MODE TOGGLE ---
          ListTile(
            tileColor: Colors.grey[900],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title:
                const Text("Debug Mode", style: TextStyle(color: Colors.white)),
            subtitle: const Text("Show inference speed & tech specs",
                style: TextStyle(color: Colors.grey)),
            trailing: Switch(
              value: settings.isDebugMode,
              activeColor: Colors.green,
              onChanged: (val) {
                setState(() {
                  settings.toggleDebugMode(val);
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // --- CONFIDENCE THRESHOLD SLIDER ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Sensitivity Threshold",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    Text("${settings.fakeThreshold.toInt()}%",
                        style: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const Text(
                  "Images with a Fake score above this will be marked as 'Fake'.",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Slider(
                  value: settings.fakeThreshold,
                  min: 10.0,
                  max: 90.0,
                  divisions: 8,
                  activeColor: Colors.green,
                  label: "${settings.fakeThreshold.toInt()}%",
                  onChanged: (val) {
                    setState(() {
                      settings.setThreshold(val);
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
