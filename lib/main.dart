import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:take_note/screens/notes.dart';
import 'package:take_note/providers/NoteNotifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (context) => NoteNotifier(),
      child: NoteApp(),
    ),
  );
  
}

const Color _cream = Color(0xFFFDF6EC);      
const Color _warmWhite = Color(0xFFFFFBF5); 
const Color _terracotta = Color(0xFFE07A5F); 
const Color _sage = Color(0xFF81A684);  
const Color _brown = Color(0xFF4A3F35); 

class NoteApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Take Note',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _cream,
        fontFamily: 'Georgia', // swap for a warmer Google Font if you add one

        colorScheme: ColorScheme.fromSeed(
          seedColor: _terracotta,
          brightness: Brightness.light,
          surface: _warmWhite,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: _cream,
          foregroundColor: _brown,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: _brown,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),

        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: _brown, fontSize: 16),
          bodyMedium: TextStyle(color: _brown, fontSize: 14),
          titleMedium: TextStyle(
            color: _brown,
            fontWeight: FontWeight.w600,
          ),
        ),

        cardTheme: CardThemeData(
          color: _warmWhite,
          elevation: 2,
          shadowColor: _brown.withOpacity(0.15),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _warmWhite,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _brown.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _terracotta, width: 1.5),
          ),
          labelStyle: TextStyle(color: _brown.withOpacity(0.6)),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _terracotta,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _terracotta,
          foregroundColor: Colors.white,
        ),

        iconTheme: IconThemeData(color: _brown.withOpacity(0.6)),
      ),
      home: Notes(),
    );
  }
}
