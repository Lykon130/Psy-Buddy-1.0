import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'journal_screen.dart';
import 'dream_screen.dart';

class DisclaimerScreen extends StatefulWidget {
  final String username;
  const DisclaimerScreen({super.key, required this.username});

  @override
  State<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends State<DisclaimerScreen> {
  String selectedPersona = "empath"; // default

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Disclaimer")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  "\t\t\tThis app is not a substitute for professional medical advice.\n "
                  "\t\t\tAlways seek the advice of physician or qualified health provider.\n "
                  "\t\t\tWith any questions you may have regarding a medical condition.\n\n"
                  "\t\t\tBy proceeding, you acknowledge that you understand and agree to the terms.",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Persona selection
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("Empath"),
                  selected: selectedPersona == "empath",
                  onSelected: (_) => setState(() => selectedPersona = "empath"),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text("Coach"),
                  selected: selectedPersona == "coach",
                  onSelected: (_) => setState(() => selectedPersona = "coach"),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      username: widget.username,
                      persona: selectedPersona,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: const Text("Go to Chat"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => JournalScreen(username: widget.username),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: const Text("Go to Journal"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DreamScreen(username: widget.username),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: const Text("Go to Dream Journal"),
            ),
          ],
        ),
      ),
    );
  }
}
