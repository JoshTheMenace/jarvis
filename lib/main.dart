import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'hud_screen.dart';

// TODO: Replace with your actual Gemini API key
const String GEMINI_API_KEY = 'AIzaSyC9FnbVw__DFvhCO9CJYzyVa6mvJtL0sE0';

// Picovoice access key for wake word detection
const String PICOVOICE_ACCESS_KEY = 'sWaWJE1czYJouPlr8yNxVb3Uv5VF5GseiVOyoQg+V08g+Wzhe5I5bw==';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set to fullscreen immersive mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

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
      title: 'JARVIS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.cyanAccent,
        colorScheme: ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.blueAccent,
          surface: Colors.black,
        ),
        useMaterial3: true,
      ),
      home: const JarvisHUDScreen(
        apiKey: GEMINI_API_KEY,
        picovoiceKey: PICOVOICE_ACCESS_KEY,
      ),
    );
  }
}
