import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'Database_logic/firebase_options.dart';
import 'Database_logic/simple_auth_manager.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/loading_viewmodel.dart';
import 'viewmodels/welcome_viewmodel.dart';
import 'viewmodels/stage_viewmodel.dart';
import 'viewmodels/challenges_viewmodel.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'viewmodels/messages_viewmodel.dart';
import 'views/homepage_view.dart';
import 'views/dashboard_view.dart';
import 'views/loading_view.dart';
import 'views/login_view.dart';
import 'views/stage_selection_view.dart';
import 'views/challenges_view.dart';
import 'config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase (this should be quick)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");
  } catch (e) {
    print("Firebase initialization failed: $e");
  }
  
  // Don't wait for AuthManager either - initialize in background
  final authManager = SimpleAuthManager();
  authManager.initialize().catchError((e) {
    print("AuthManager initialization failed: $e");
  });
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoadingViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => StageViewModel()),
        ChangeNotifierProvider(create: (_) => ChallengesViewModel()),
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ChangeNotifierProvider(create: (_) => MessagesViewModel()),
      ],
      child: MaterialApp(
        title: 'Mother Connection Platform',
        theme: ThemeData(
          primarySwatch: Colors.brown,
          scaffoldBackgroundColor: const Color(0xFFF2EDE7),
        ),
        debugShowCheckedModeBanner: false,
        home: const AppInitializer(),
        routes: {
          '/loading': (context) => const LoadingView(),
          '/homepage': (context) => const HomepageView(),
          '/login': (context) => const LoginView(),
          '/stage-selection': (context) => const StageSelectionView(),
          '/challenges': (context) => const ChallengesView(isMismatch: false),
          '/dashboard': (context) => const DashboardView(),
          // Note: MessagesView is not included in basic routes as it requires specific conversation data
          // Navigation to MessagesView should be done programmatically from DashboardView with proper initData
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  final SimpleAuthManager _authManager = SimpleAuthManager();
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    print("\n" + "="*50);
    print("AppInitializer: Starting app initialization - ${DateTime.now()}");
    print("="*50);

    try {
      // Initialize auth manager
      await _authManager.initialize();
      
      // Check if user is authenticated and has completed onboarding
      if (_authManager.isAuthenticated) {
        print("AppInitializer: User is authenticated: ${_authManager.currentUsername}");
        
        final hasCompleted = await _authManager.hasCompletedOnboarding();
        
        if (hasCompleted) {
          print("AppInitializer: User completed onboarding - navigating to Dashboard");
          // Use WidgetsBinding to avoid navigation conflicts
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/dashboard');
            }
          });
        } else {
          // Check if user has momStage to determine if they're new or returning
          final userData = await _authManager.getUserData();
          
          // Check if user has a valid momStage (not null and not empty)
          bool hasMomStage = false;
          if (userData != null && userData.containsKey('momStage')) {
            final momStageValue = userData['momStage'];
            if (momStageValue != null) {
              if (momStageValue is List && momStageValue.isNotEmpty) {
                hasMomStage = true;
              } else if (momStageValue is String && momStageValue.isNotEmpty) {
                hasMomStage = true;
              }
            }
          }
          
          if (hasMomStage) {
            // Returning user - send directly to dashboard
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/dashboard');
              }
            });
          } else {
            // New user who needs to complete mother stage selection
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/stage-selection');
              }
            });
          }
        }
      } else {
        print("AppInitializer: No authenticated user - showing Homepage");
        // No navigation needed - just show the homepage
      }
    } catch (e) {
      print("AppInitializer: Error during initialization: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
    
    print("="*50 + "\n");
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Color(0xFFF2EDE7),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF574F4E)),
              ),
              SizedBox(height: 20),
              Text(
                UITexts.initializingApp,
                style: TextStyle(
                  fontFamily: "Nuosu SIL",
                  fontSize: 14,
                  color: Color(0xFF574F4E),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show homepage directly to avoid navigation conflicts
    return const HomepageView();
  }
}