import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:fitspot/firebase_options.dart';
import 'package:fitspot/theme.dart';
import 'package:fitspot/widgets/auth_wrapper.dart';
import 'package:fitspot/screens/auth_screen.dart';
import 'package:fitspot/firestore/firebase_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => FirebaseProvider(),
      child: MaterialApp(
        title: 'FitSpot',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
        routes: {
          '/auth': (context) => const AuthScreen(),
        },
      ),
    );
  }
}
