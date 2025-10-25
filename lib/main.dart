import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'home_screen_v2.dart';

// TODO: Replace with your actual Gemini API key
const String GEMINI_API_KEY = 'AIzaSyC9FnbVw__DFvhCO9CJYzyVa6mvJtL0sE0';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request permissions
  await _requestPermissions();

  runApp(const MyApp());
}

Future<void> _requestPermissions() async {
  // Request camera and microphone permissions
  final cameraStatus = await Permission.camera.request();
  final microphoneStatus = await Permission.microphone.request();

  if (cameraStatus.isDenied || microphoneStatus.isDenied) {
    print('Permissions denied. The app may not function correctly.');
  }

  if (cameraStatus.isPermanentlyDenied || microphoneStatus.isPermanentlyDenied) {
    print('Permissions permanently denied. Please enable them in settings.');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jarvis - Gemini Live',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GeminiLiveChatScreen(apiKey: GEMINI_API_KEY),
    );
  }
}
