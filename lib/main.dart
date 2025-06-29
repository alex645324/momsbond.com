import 'package:flutter/material.dart';
import 'Screens/Initial.dart'; // Import your initial page
import 'Screens/NewMoms.dart'; // Import other pages as needed
import 'Screens/MomStage.dart';
import 'Screens/QuestionSet1.dart';
import 'Screens/QuestionSet2.dart';
import 'Screens/Loading.dart';
import 'Screens/Dashboard.dart';
import 'Screens/ChatPage.dart'; // Import the Conv.dart file
import 'Database_logic/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Database_logic/db.dart'; // Fixed import path
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this import
import 'Screens/GoogleSignInPage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'Database_logic/auth_manager.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types; // Import for User type
import 'package:http/http.dart' as http;
import 'dart:convert';
// Create a route observer
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
// In main.dart, add this at the top level
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Create a loading screen widget
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF2EDE7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,  // Corrected from mainAlignment
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              "Initializing app...",
              style: TextStyle(
                fontFamily: "Nuosu SIL",
                fontSize: 18,
                color: Color(0xFF574F4E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Run the app with a FutureBuilder to handle initialization
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // Then update the MaterialApp in MyApp class
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mom Support App',
      navigatorKey: navigatorKey, // Add this line
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF2EDE7),
      ),
      home: FutureBuilder(
  future: _initializeApp(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const LoadingScreen();
    }
    
    if (snapshot.hasError) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2EDE7),
        body: Center(
          child: Text(
            "Error initializing app: ${snapshot.error}",
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
    
    // Check user status after initialization
    return FutureBuilder<bool>(
      future: _checkExistingConnections(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }
        
        bool isReturningUser = userSnapshot.data ?? false;
        
        if (isReturningUser) {
          print("Routing to Dashboard for returning user");
          return const Dashboard();
        } else {
          print("Routing to GoogleSignInPage for new/incomplete user");
          return const GoogleSignInPage();
        }
      },
    );
  },
),
    );
  }


  
Future<bool> _checkExistingConnections() async {
  try {
    print("\n" + "="*50);
    print("CHECKING USER STATUS - ${DateTime.now()}");
    print("="*50);
    
    // Check if user is signed in
    bool isSignedIn = await AuthManager().isUserSignedIn();
    print("User signed in: $isSignedIn");
    
    if (!isSignedIn) {
      print("User not signed in - going to GoogleSignInPage");
      print("="*50 + "\n");
      return false;
    }
    
    final userId = AuthManager().getUserId();
    print("User ID: $userId");
    
    // Check if the user has completed onboarding
    final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .get();
    
    print("User document exists: ${userDoc.exists}");
    
    if (!userDoc.exists) {
      print("User document doesn't exist - needs onboarding");
      print("="*50 + "\n");
      return false;
    }
    
    final userData = userDoc.data() as Map<String, dynamic>;
    print("User data keys: ${userData.keys.toList()}");
    
    // Check specific fields
    bool hasMomStage = userData.containsKey('momStage');
    bool hasQuestionSet1 = userData.containsKey('questionSet1');
    bool hasQuestionSet2 = userData.containsKey('questionSet2');
    
    print("Has momStage: $hasMomStage");
    print("Has questionSet1: $hasQuestionSet1");  
    print("Has questionSet2: $hasQuestionSet2");
    
    bool hasCompletedOnboarding = hasMomStage && (hasQuestionSet1 || hasQuestionSet2);
    
    print("Has completed onboarding: $hasCompletedOnboarding");
    
    if (hasCompletedOnboarding) {
      print("RETURNING USER DETECTED - going to Dashboard");
      print("="*50 + "\n");
      return true;
    } else {
      print("User needs to complete onboarding");
      print("="*50 + "\n");
      return false;
    }
    
  } catch (e) {
    print('Error checking user status: $e');
    print("="*50 + "\n");
    return false;
  }
}

// Helper method to check if the current user has completed onboarding
Future<bool> _checkCurrentUserOnboarding(String userId) async {
  try {
    final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .get();
    
    if (userDoc.exists) {
      final userData = userDoc.data();
      return userData != null && 
             userData.containsKey('username') && 
             userData.containsKey('momStage');
    }
    return false;
  } catch (e) {
    print('Error checking current user onboarding: $e');
    return false;
  }
}
  
Future<void> _initializeApp() async {
  try {
    // Initialize Firebase first
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
    
    // Initialize auth manager (which sets persistence)
    await AuthManager().initialize();
    
    // Wait longer for auth state to be ready on web
    print('Waiting for auth state to be ready...');
    await Future.delayed(const Duration(seconds: 2)); // Increased delay
    
    // Force check the current user one more time
    final currentUser = FirebaseAuth.instance.currentUser;
    print('Final auth check - Current user: ${currentUser?.uid ?? 'null'}');
    
    print('App initialization complete');
  } catch (e) {
    print('Error initializing app: $e');
    throw e;
  }
}
}