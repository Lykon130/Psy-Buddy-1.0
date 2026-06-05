import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'providers/mood_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xeidzrhpckazimixmixh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhlaWR6cmhwY2themltaXhtaXhoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU4ODY4OTYsImV4cCI6MjA5MTQ2Mjg5Nn0.NnRW5tpUtlA2HMCDZa6l7ef_Q9xg8lwwU9bcUqcF0x0',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MoodProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'PsyBuddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(moodProvider.currentEmotion),
      darkTheme: AppTheme.darkTheme(moodProvider.currentEmotion),
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
    );
  }
}
