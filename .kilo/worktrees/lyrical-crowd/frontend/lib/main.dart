import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'providers/mood_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase. Replace with real keys when deployed.
  await Supabase.initialize(
    url: 'https://xeidzrhpckazimixmixh.supabase.co',
    anonKey: 'sb_publishable_DZKFZIqsAOIr4MCms3fzZA_yluSgyGs',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MoodProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final moodProvider = Provider.of<MoodProvider>(context);

    // Dynamic Theme wrapper that listens to mood
    return MaterialApp(
      title: 'PsyBuddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(moodProvider.currentEmotion),
      home: const SplashScreen(),
    );
  }
}
