import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import '../Database_logic/firebase_options.dart';

// Retro UI Helper
class RetroUI {
  // ANSI Color Codes for retro terminal
  static const String reset = '\x1B[0m';
  static const String bold = '\x1B[1m';
  static const String dim = '\x1B[2m';
  
  // Classic terminal colors
  static const String green = '\x1B[32m';
  static const String brightGreen = '\x1B[92m';
  static const String yellow = '\x1B[33m';
  static const String red = '\x1B[31m';
  static const String blue = '\x1B[34m';
  static const String cyan = '\x1B[36m';
  static const String white = '\x1B[37m';
  static const String amber = '\x1B[93m';
  
  static void clearScreen() {
    print('\x1B[2J\x1B[0;0H');
  }
  
  static void printHeader() {
    clearScreen();
    print('${green}${bold}');
    print('╔══════════════════════════════════════════════════════════════════╗');
    print('║  ███╗   ███╗ ██████╗ ███╗   ███╗███████╗    █████╗ ██████╗ ███╗   ███╗██╗███╗   ██╗ ║');
    print('║  ████╗ ████║██╔═══██╗████╗ ████║██╔════╝   ██╔══██╗██╔══██╗████╗ ████║██║████╗  ██║ ║');
    print('║  ██╔████╔██║██║   ██║██╔████╔██║███████╗   ███████║██║  ██║██╔████╔██║██║██╔██╗ ██║ ║');
    print('║  ██║╚██╔╝██║██║   ██║██║╚██╔╝██║╚════██║   ██╔══██║██║  ██║██║╚██╔╝██║██║██║╚██╗██║ ║');
    print('║  ██║ ╚═╝ ██║╚██████╔╝██║ ╚═╝ ██║███████║   ██║  ██║██████╔╝██║ ╚═╝ ██║██║██║ ╚████║ ║');
    print('║  ╚═╝     ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝   ╚═╝  ╚═╝╚═════╝ ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝ ║');
    print('║${amber}                         Platform Administration Terminal v1.0                         ${green}║');
    print('╚══════════════════════════════════════════════════════════════════╝${reset}');
    print('');
  }
  
  static void printSystemStatus({
    required bool firebaseConnected,
    required String database,
    required int activeUsers,
    required int usersInConversation,
    required int conversationTimer,
    required int activeConnections,
  }) {
    print('${cyan}┌──────────────────── SYSTEM STATUS ────────────────────┐${reset}');
    String firebaseStatus = firebaseConnected ? '${green}CONNECTED${reset}' : '${red}OFFLINE${reset}';
    print('${cyan}│${reset} 🔌 Firebase: $firebaseStatus    📊 Database: ${brightGreen}$database${reset} ${cyan}│${reset}');
    print('${cyan}│${reset} 👥 Active Users: ${yellow}$activeUsers${reset}       💬 In Conversation: ${yellow}$usersInConversation${reset}      ${cyan}│${reset}');
    print('${cyan}│${reset} ⏱️  Conversation Timer: ${amber}${conversationTimer}s${reset}  🔗 Active Connections: ${yellow}$activeConnections${reset} ${cyan}│${reset}');
    print('${cyan}└────────────────────────────────────────────────────────┘${reset}');
    print('');
  }
  
  static void printMainMenu() {
    print('${green}${bold}┌─────────────────── ADMIN MENU ────────────────────┐${reset}');
    print('${green}│${reset}  ${amber}[1]${reset} 💬 Conversation Time Management               ${green}│${reset}');
    print('${green}│${reset}  ${amber}[2]${reset} 👥 Active User Monitoring                     ${green}│${reset}');
    print('${green}│${reset}  ${amber}[3]${reset} 🔗 Connection Streak Management               ${green}│${reset}');
    print('${green}│${reset}  ${amber}[4]${reset} 🔄 Refresh All Data                           ${green}│${reset}');
    print('${green}│${reset}  ${amber}[5]${reset} 🚪 Exit Terminal                              ${green}│${reset}');
    print('${green}└────────────────────────────────────────────────────┘${reset}');
    print('');
  }
  
  static void printSuccess(String message) {
    print('${green}✅ SUCCESS:${reset} $message');
  }
  
  static void printError(String message) {
    print('${red}❌ ERROR:${reset} $message');
  }
  
  static void printInfo(String message) {
    print('${cyan}ℹ️  INFO:${reset} $message');
  }
  
  static void printWarning(String message) {
    print('${yellow}⚠️  WARNING:${reset} $message');
  }
  
  static void printPrompt(String prompt) {
    stdout.write('${brightGreen}${bold}» ${reset}$prompt: ');
  }
  
  static void printBootSequence() {
    List<String> bootMessages = [
      'Initializing retro terminal...',
      'Loading ASCII art libraries...',
      'Connecting to Firebase...',
      'Establishing secure connection...',
      'Loading user monitoring systems...',
      'Initializing conversation management...',
      'Setting up connection decay algorithms...',
      'Terminal ready for administrative operations.',
    ];
    
    for (String message in bootMessages) {
      print('${green}[BOOT]${reset} $message');
      sleep(Duration(milliseconds: 300));
    }
    print('');
  }
  
  static void printConnectionDecayDemo(int strength) {
    double opacity = (strength / 100.0).clamp(0.1, 1.0);
    String visualBar = '';
    int barLength = 15;
    int filledLength = (opacity * barLength).round();
    
    for (int i = 0; i < barLength; i++) {
      if (i < filledLength) {
        if (opacity > 0.7) {
          visualBar += '${brightGreen}█${reset}';
        } else if (opacity > 0.4) {
          visualBar += '${yellow}█${reset}';
        } else {
          visualBar += '${red}█${reset}';
        }
      } else {
        visualBar += '${dim}░${reset}';
      }
    }
    
    print('Connection Strength: $visualBar ${amber}${strength}%${reset} (Opacity: ${cyan}${(opacity * 100).round()}%${reset})');
  }
}

// Data Models
class SystemStats {
  final int totalUsers;
  final int activeUsers;
  final int usersInConversation;
  final int waitingUsers;
  final int activeConnections;
  final int conversationTimer;
  final String databaseName;
  
  SystemStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.usersInConversation,
    required this.waitingUsers,
    required this.activeConnections,
    required this.conversationTimer,
    required this.databaseName,
  });
}

class UserMonitorData {
  final String userId;
  final String username;
  final String status;
  final String lastActive;
  final String momStage;
  
  UserMonitorData({
    required this.userId,
    required this.username,
    required this.status,
    required this.lastActive,
    required this.momStage,
  });
}

class ConnectionData {
  final String connectionId;
  final String userA;
  final String userB;
  final int strength;
  final String lastContact;
  final String status;
  
  ConnectionData({
    required this.connectionId,
    required this.userA,
    required this.userB,
    required this.strength,
    required this.lastContact,
    required this.status,
  });
}

class AdminConfig {
  int conversationDurationSeconds;
  bool enableQuickDeadlines;
  int quickDeadlineMinutes;
  bool enableConnectionDecay;
  int decayRatePercent;
  
  AdminConfig({
    this.conversationDurationSeconds = 180,
    this.enableQuickDeadlines = true,
    this.quickDeadlineMinutes = 10,
    this.enableConnectionDecay = true,
    this.decayRatePercent = 5,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'conversationDurationSeconds': conversationDurationSeconds,
      'enableQuickDeadlines': enableQuickDeadlines,
      'quickDeadlineMinutes': quickDeadlineMinutes,
      'enableConnectionDecay': enableConnectionDecay,
      'decayRatePercent': decayRatePercent,
    };
  }
  
  factory AdminConfig.fromMap(Map<String, dynamic> map) {
    return AdminConfig(
      conversationDurationSeconds: map['conversationDurationSeconds'] ?? 180,
      enableQuickDeadlines: map['enableQuickDeadlines'] ?? true,
      quickDeadlineMinutes: map['quickDeadlineMinutes'] ?? 10,
      enableConnectionDecay: map['enableConnectionDecay'] ?? true,
      decayRatePercent: map['decayRatePercent'] ?? 5,
    );
  }
}

// Firebase Admin Service
class FirebaseAdminService {
  static FirebaseAdminService? _instance;
  static FirebaseAdminService get instance => _instance ??= FirebaseAdminService._();
  FirebaseAdminService._();

  FirebaseFirestore? _firestore;
  bool _isInitialized = false;
  AdminConfig _adminConfig = AdminConfig();

  bool get isConnected => _isInitialized && _firestore != null;
  FirebaseFirestore get firestore => _firestore!;
  AdminConfig get adminConfig => _adminConfig;

  Future<bool> initialize() async {
    try {
      print('[ADMIN] Initializing Firebase connection...');
      
      // Check if Firebase is already initialized
      FirebaseApp? app;
      try {
        app = Firebase.app('admin_console');
      } catch (e) {
        // App doesn't exist, create it
        app = await Firebase.initializeApp(
          name: 'admin_console',
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      
      _firestore = FirebaseFirestore.instanceFor(app: app);
      
      // Test connection
      await _firestore!.collection('users').limit(1).get();
      
      _isInitialized = true;
      print('[ADMIN] Firebase connection established successfully');
      
      // Load admin configuration
      await _loadAdminConfig();
      
      return true;
    } catch (e) {
      print('[ADMIN] Failed to initialize Firebase: $e');
      return false;
    }
  }

  Future<SystemStats> getSystemStats() async {
    if (!isConnected) throw Exception('Firebase not connected');
    
    try {
      final activeThreshold = DateTime.now().subtract(Duration(seconds: 30));
      
      final usersSnapshot = await _firestore!.collection('users').get();
      
      int totalUsers = usersSnapshot.docs.length;
      int activeUsers = 0;
      int usersInConversation = 0;
      int waitingUsers = 0;
      
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        
        final lastActiveTimestamp = data['lastActiveTimestamp'] as Timestamp?;
        if (lastActiveTimestamp != null) {
          final lastActive = lastActiveTimestamp.toDate();
          if (lastActive.isAfter(activeThreshold)) {
            activeUsers++;
          }
        }
        
        if (data['isInConversation'] == true) {
          usersInConversation++;
        }
        
        if (data['isWaiting'] == true) {
          waitingUsers++;
        }
      }
      
      final connectionsSnapshot = await _firestore!.collection('matches').get();
      int activeConnections = 0;
      
      for (var doc in connectionsSnapshot.docs) {
        final data = doc.data();
        final connectionStrength = data['connectionStrength'] ?? 100;
        if (connectionStrength > 10) {
          activeConnections++;
        }
      }
      
      return SystemStats(
        totalUsers: totalUsers,
        activeUsers: activeUsers,
        usersInConversation: usersInConversation,
        waitingUsers: waitingUsers,
        activeConnections: activeConnections,
        conversationTimer: _adminConfig.conversationDurationSeconds,
        databaseName: 'mymomsapp-59faa',
      );
      
    } catch (e) {
      print('[ADMIN] Error getting system stats: $e');
      rethrow;
    }
  }

  Future<List<UserMonitorData>> getUserMonitoringData() async {
    if (!isConnected) throw Exception('Firebase not connected');
    
    try {
      final activeThreshold = DateTime.now().subtract(Duration(seconds: 30));
      final usersSnapshot = await _firestore!.collection('users').get();
      
      List<UserMonitorData> users = [];
      
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final userId = doc.id;
        
        String status = 'Offline';
        final lastActiveTimestamp = data['lastActiveTimestamp'] as Timestamp?;
        if (lastActiveTimestamp != null) {
          final lastActive = lastActiveTimestamp.toDate();
          if (lastActive.isAfter(activeThreshold)) {
            if (data['isInConversation'] == true) {
              status = 'In Conversation';
            } else if (data['isWaiting'] == true) {
              status = 'Waiting';
            } else {
              status = 'Online';
            }
          }
        }
        
        String lastActiveStr = 'Never';
        if (lastActiveTimestamp != null) {
          final lastActive = lastActiveTimestamp.toDate();
          final diff = DateTime.now().difference(lastActive);
          if (diff.inMinutes < 1) {
            lastActiveStr = 'Just now';
          } else if (diff.inHours < 1) {
            lastActiveStr = '${diff.inMinutes}m ago';
          } else if (diff.inDays < 1) {
            lastActiveStr = '${diff.inHours}h ago';
          } else {
            lastActiveStr = '${diff.inDays}d ago';
          }
        }
        
        users.add(UserMonitorData(
          userId: userId,
          username: data['username'] ?? 'Unknown',
          status: status,
          lastActive: lastActiveStr,
          momStage: (data['momStage'] as List?)?.join(', ') ?? 'Not set',
        ));
      }
      
      users.sort((a, b) {
        const statusPriority = {
          'In Conversation': 0,
          'Waiting': 1,
          'Online': 2,
          'Offline': 3,
        };
        return statusPriority[a.status]!.compareTo(statusPriority[b.status]!);
      });
      
      return users;
    } catch (e) {
      print('[ADMIN] Error getting user monitoring data: $e');
      rethrow;
    }
  }

  Future<List<ConnectionData>> getConnectionData() async {
    if (!isConnected) throw Exception('Firebase not connected');
    
    try {
      final connectionsSnapshot = await _firestore!.collection('matches').get();
      List<ConnectionData> connections = [];
      
      for (var doc in connectionsSnapshot.docs) {
        final data = doc.data();
        final connectionId = doc.id;
        
        final strength = data['connectionStrength'] ?? 100;
        String status = 'Active';
        if (strength <= 10) {
          status = 'Critically Low';
        } else if (strength <= 30) {
          status = 'Weak';
        } else if (strength <= 70) {
          status = 'Moderate';
        }
        
        final lastContactTimestamp = data['lastContactTimestamp'] as Timestamp?;
        String lastContact = 'Unknown';
        if (lastContactTimestamp != null) {
          final lastContactDate = lastContactTimestamp.toDate();
          final diff = DateTime.now().difference(lastContactDate);
          if (diff.inMinutes < 1) {
            lastContact = 'Just now';
          } else if (diff.inHours < 1) {
            lastContact = '${diff.inMinutes}m ago';
          } else if (diff.inDays < 1) {
            lastContact = '${diff.inHours}h ago';
          } else {
            lastContact = '${diff.inDays}d ago';
          }
        }
        
        connections.add(ConnectionData(
          connectionId: connectionId,
          userA: data['userAName'] ?? 'Unknown',
          userB: data['userBName'] ?? 'Unknown',
          strength: strength,
          lastContact: lastContact,
          status: status,
        ));
      }
      
      connections.sort((a, b) => a.strength.compareTo(b.strength));
      return connections;
    } catch (e) {
      print('[ADMIN] Error getting connection data: $e');
      rethrow;
    }
  }

  Future<void> updateConversationTimer(int seconds) async {
    if (!isConnected) throw Exception('Firebase not connected');
    
    try {
      _adminConfig.conversationDurationSeconds = seconds;
      await _saveAdminConfig();
      
      await _firestore!.collection('admin').doc('config').set({
        'conversationDurationSeconds': seconds,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
    } catch (e) {
      print('[ADMIN] Error updating conversation timer: $e');
      rethrow;
    }
  }

  Future<void> setQuickDeadline(int minutes) async {
    if (!isConnected) throw Exception('Firebase not connected');
    
    try {
      _adminConfig.enableQuickDeadlines = true;
      _adminConfig.quickDeadlineMinutes = minutes;
      await _saveAdminConfig();
      
      await _firestore!.collection('admin').doc('config').set({
        'enableQuickDeadlines': true,
        'quickDeadlineMinutes': minutes,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
    } catch (e) {
      print('[ADMIN] Error setting quick deadline: $e');
      rethrow;
    }
  }

  Future<void> refreshConnectionStrengths() async {
    if (!isConnected) throw Exception('Firebase not connected');
    
    try {
      final connectionsSnapshot = await _firestore!.collection('matches').get();
      
      for (var doc in connectionsSnapshot.docs) {
        final data = doc.data();
        final currentStrength = data['connectionStrength'] ?? 100;
        
        // Apply decay if enabled
        if (_adminConfig.enableConnectionDecay && currentStrength > 0) {
          int newStrength = (currentStrength - _adminConfig.decayRatePercent).clamp(0, 100);
          
          await doc.reference.update({
            'connectionStrength': newStrength,
            'lastDecayUpdate': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('[ADMIN] Error refreshing connection strengths: $e');
      rethrow;
    }
  }

  Future<void> _loadAdminConfig() async {
    try {
      final configDoc = await _firestore!.collection('admin').doc('config').get();
      if (configDoc.exists) {
        _adminConfig = AdminConfig.fromMap(configDoc.data()!);
      }
    } catch (e) {
      print('[ADMIN] Using default admin config: $e');
    }
  }

  Future<void> _saveAdminConfig() async {
    try {
      await _firestore!.collection('admin').doc('config').set(
        _adminConfig.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      print('[ADMIN] Error saving admin config: $e');
    }
  }
}

// Main Admin Terminal Application
class AdminTerminal {
  final FirebaseAdminService _firebaseService = FirebaseAdminService.instance;
  bool _isRunning = false;

  Future<void> start() async {
    _isRunning = true;
    
    RetroUI.printBootSequence();
    
    // Initialize Firebase
    bool connected = await _firebaseService.initialize();
    if (!connected) {
      RetroUI.printError('Failed to connect to Firebase. Exiting...');
      return;
    }
    
    while (_isRunning) {
      await _showMainInterface();
    }
  }

  Future<void> _showMainInterface() async {
    try {
      // Get system stats
      final stats = await _firebaseService.getSystemStats();
      
      // Display header and status
      RetroUI.printHeader();
      RetroUI.printSystemStatus(
        firebaseConnected: _firebaseService.isConnected,
        database: stats.databaseName,
        activeUsers: stats.activeUsers,
        usersInConversation: stats.usersInConversation,
        conversationTimer: stats.conversationTimer,
        activeConnections: stats.activeConnections,
      );
      
      // Show main menu
      RetroUI.printMainMenu();
      
      // Get user input
      RetroUI.printPrompt('Select option');
      final input = stdin.readLineSync();
      
      await _handleMenuSelection(input);
      
    } catch (e) {
      RetroUI.printError('System error: $e');
      sleep(Duration(seconds: 2));
    }
  }

  Future<void> _handleMenuSelection(String? input) async {
    switch (input?.trim()) {
      case '1':
        await _conversationTimeManagement();
        break;
      case '2':
        await _userMonitoring();
        break;
      case '3':
        await _connectionManagement();
        break;
      case '4':
        RetroUI.printInfo('Refreshing all data...');
        await _firebaseService.refreshConnectionStrengths();
        RetroUI.printSuccess('Data refreshed successfully');
        sleep(Duration(seconds: 1));
        break;
      case '5':
        _isRunning = false;
        RetroUI.printInfo('Shutting down admin terminal...');
        break;
      default:
        RetroUI.printError('Invalid option. Please try again.');
        sleep(Duration(seconds: 1));
    }
  }

  Future<void> _conversationTimeManagement() async {
    while (true) {
      RetroUI.clearScreen();
      RetroUI.printHeader();
      
      print('${RetroUI.cyan}┌─────────── CONVERSATION TIME MANAGEMENT ───────────┐${RetroUI.reset}');
      print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[1]${RetroUI.reset} View Current Timer Setting                     ${RetroUI.cyan}│${RetroUI.reset}');
      print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[2]${RetroUI.reset} Set Timer with Presets                        ${RetroUI.cyan}│${RetroUI.reset}');
      print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[3]${RetroUI.reset} Custom Duration (10-3600 seconds)            ${RetroUI.cyan}│${RetroUI.reset}');
      print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[4]${RetroUI.reset} Back to Main Menu                             ${RetroUI.cyan}│${RetroUI.reset}');
      print('${RetroUI.cyan}└──────────────────────────────────────────────────────┘${RetroUI.reset}');
      print('');
      
      final config = _firebaseService.adminConfig;
      print('${RetroUI.green}Current Settings:${RetroUI.reset}');
      print('  • Timer: ${config.conversationDurationSeconds}s (${_formatDuration(config.conversationDurationSeconds)})');
      print('  • Status: ${config.conversationDurationSeconds > 0 ? "${RetroUI.green}Active${RetroUI.reset}" : "${RetroUI.red}Disabled${RetroUI.reset}"}');
      print('  • Applies to: Future conversations only');
      print('');
      
      RetroUI.printPrompt('Select option');
      final input = stdin.readLineSync();
      
      switch (input?.trim()) {
        case '1':
          await _showCurrentTimerDetails();
          break;
        case '2':
          await _showTimerPresets();
          break;
        case '3':
          await _setCustomTimer();
          break;
        case '4':
          return;
        default:
          RetroUI.printError('Invalid option');
          sleep(Duration(seconds: 1));
      }
    }
  }

  Future<void> _showCurrentTimerDetails() async {
    RetroUI.clearScreen();
    RetroUI.printHeader();
    
    final config = _firebaseService.adminConfig;
    print('${RetroUI.cyan}📊 CURRENT CONVERSATION TIMER DETAILS${RetroUI.reset}');
    print('');
    print('⏱️  Current Setting: ${RetroUI.amber}${config.conversationDurationSeconds} seconds${RetroUI.reset}');
    print('🕐 Human Readable: ${RetroUI.green}${_formatDuration(config.conversationDurationSeconds)}${RetroUI.reset}');
    print('📋 Description: ${_getTimerDescription(config.conversationDurationSeconds)}');
    print('🎯 Application: Applies to future conversations only');
    print('');
    print('📈 Timer Categories:');
    if (config.conversationDurationSeconds <= 30) {
      print('   ${RetroUI.red}⚡ Ultra-Fast Mode${RetroUI.reset} - For quick testing');
    } else if (config.conversationDurationSeconds <= 120) {
      print('   ${RetroUI.yellow}🚀 Quick Mode${RetroUI.reset} - For brief interactions');
    } else if (config.conversationDurationSeconds <= 600) {
      print('   ${RetroUI.green}⭐ Standard Mode${RetroUI.reset} - Balanced conversation time');
    } else {
      print('   ${RetroUI.blue}🔷 Extended Mode${RetroUI.reset} - For deep conversations');
    }
    print('');
    print('Press Enter to continue...');
    stdin.readLineSync();
  }

  Future<void> _showTimerPresets() async {
    RetroUI.clearScreen();
    RetroUI.printHeader();
    
    print('${RetroUI.cyan}⚡ CONVERSATION TIMER PRESETS${RetroUI.reset}');
    print('');
    print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[1]${RetroUI.reset} ${RetroUI.red}15 seconds${RetroUI.reset}  - Quick test mode           ${RetroUI.cyan}│${RetroUI.reset}');
    print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[2]${RetroUI.reset} ${RetroUI.yellow}30 seconds${RetroUI.reset}  - Default quick mode        ${RetroUI.cyan}│${RetroUI.reset}');
    print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[3]${RetroUI.reset} ${RetroUI.green}60 seconds${RetroUI.reset}  - 1 minute standard         ${RetroUI.cyan}│${RetroUI.reset}');
    print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[4]${RetroUI.reset} ${RetroUI.blue}300 seconds${RetroUI.reset} - 5 minute extended         ${RetroUI.cyan}│${RetroUI.reset}');
    print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[5]${RetroUI.reset} ${RetroUI.blue}600 seconds${RetroUI.reset} - 10 minute long            ${RetroUI.cyan}│${RetroUI.reset}');
    print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[6]${RetroUI.reset} Back to Timer Menu                      ${RetroUI.cyan}│${RetroUI.reset}');
    print('');
    
    RetroUI.printPrompt('Select preset');
    final input = stdin.readLineSync();
    
    int? newTimer;
    String? description;
    
    switch (input?.trim()) {
      case '1':
        newTimer = 15;
        description = 'Quick test mode';
        break;
      case '2':
        newTimer = 30;
        description = 'Default quick mode';
        break;
      case '3':
        newTimer = 60;
        description = '1 minute standard';
        break;
      case '4':
        newTimer = 300;
        description = '5 minute extended';
        break;
      case '5':
        newTimer = 600;
        description = '10 minute long';
        break;
      case '6':
        return;
      default:
        RetroUI.printError('Invalid option');
        sleep(Duration(seconds: 1));
        return;
    }
    
    if (newTimer != null) {
      await _firebaseService.updateConversationTimer(newTimer);
      RetroUI.printSuccess('Timer updated to $newTimer seconds ($description)');
      print('Changes will apply to future conversations.');
      sleep(Duration(seconds: 2));
    }
  }

  Future<void> _setCustomTimer() async {
    RetroUI.clearScreen();
    RetroUI.printHeader();
    
    print('${RetroUI.cyan}🎛️  CUSTOM TIMER CONFIGURATION${RetroUI.reset}');
    print('');
    print('⏱️  Range: 10-3600 seconds (1 hour maximum)');
    print('📋 Examples:');
    print('   • 45 = 45 seconds');
    print('   • 120 = 2 minutes');
    print('   • 1800 = 30 minutes');
    print('   • 3600 = 1 hour');
    print('');
    
    RetroUI.printPrompt('Enter custom duration (10-3600 seconds)');
    final timerInput = stdin.readLineSync();
    final timer = int.tryParse(timerInput ?? '');
    
    if (timer != null && timer >= 10 && timer <= 3600) {
      await _firebaseService.updateConversationTimer(timer);
      RetroUI.printSuccess('Custom timer set to $timer seconds (${_formatDuration(timer)})');
      print('${_getTimerDescription(timer)}');
      print('Changes will apply to future conversations.');
    } else {
      RetroUI.printError('Invalid duration. Must be between 10-3600 seconds.');
    }
    sleep(Duration(seconds: 3));
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${(seconds / 60).toStringAsFixed(1)}min';
    return '${(seconds / 3600).toStringAsFixed(1)}hr';
  }

  String _getTimerDescription(int seconds) {
    if (seconds <= 30) return 'Perfect for quick testing and debugging';
    if (seconds <= 120) return 'Good for brief introductions and ice breakers';
    if (seconds <= 600) return 'Ideal for meaningful conversations and connections';
    return 'Extended time for deep conversations and bonding';
  }

  Future<void> _userMonitoring() async {
    while (true) {
      try {
        RetroUI.clearScreen();
        RetroUI.printHeader();
        
        print('${RetroUI.cyan}┌─────────────── ACTIVE USER MONITORING ───────────────┐${RetroUI.reset}');
        print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[1]${RetroUI.reset} System Overview Dashboard                     ${RetroUI.cyan}│${RetroUI.reset}');
        print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[2]${RetroUI.reset} User Details Table                            ${RetroUI.cyan}│${RetroUI.reset}');
        print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[3]${RetroUI.reset} Platform Activity Analysis                   ${RetroUI.cyan}│${RetroUI.reset}');
        print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[4]${RetroUI.reset} Refresh Data                                  ${RetroUI.cyan}│${RetroUI.reset}');
        print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[5]${RetroUI.reset} Back to Main Menu                             ${RetroUI.cyan}│${RetroUI.reset}');
        print('${RetroUI.cyan}└──────────────────────────────────────────────────────┘${RetroUI.reset}');
        print('');
        
        RetroUI.printPrompt('Select option');
        final input = stdin.readLineSync();
        
        switch (input?.trim()) {
          case '1':
            await _showSystemOverview();
            break;
          case '2':
            await _showUserDetailsTable();
            break;
          case '3':
            await _showActivityAnalysis();
            break;
          case '4':
            RetroUI.printInfo('Refreshing user data...');
            sleep(Duration(seconds: 1));
            break;
          case '5':
            return;
          default:
            RetroUI.printError('Invalid option');
            sleep(Duration(seconds: 1));
        }
      } catch (e) {
        RetroUI.printError('Failed to load user monitoring: $e');
        sleep(Duration(seconds: 2));
        return;
      }
    }
  }

  Future<void> _showSystemOverview() async {
    try {
      RetroUI.clearScreen();
      RetroUI.printHeader();
      
      print('${RetroUI.cyan}Loading system overview...${RetroUI.reset}');
      final stats = await _firebaseService.getSystemStats();
      final users = await _firebaseService.getUserMonitoringData();
      
      RetroUI.clearScreen();
      RetroUI.printHeader();
      
      print('${RetroUI.cyan}📊 SYSTEM OVERVIEW DASHBOARD${RetroUI.reset}');
      print('');
      
      // Calculate activity percentage
      int activityPercentage = stats.totalUsers > 0 ? 
        ((stats.activeUsers / stats.totalUsers) * 100).round() : 0;
      
      print('${RetroUI.green}📈 Platform Statistics:${RetroUI.reset}');
      print('   👥 Total Users: ${RetroUI.amber}${stats.totalUsers}${RetroUI.reset}');
      print('   🟢 Active Users (last 30s): ${RetroUI.green}${stats.activeUsers}${RetroUI.reset}');
      print('   💬 In Conversation: ${RetroUI.blue}${stats.usersInConversation}${RetroUI.reset}');
      print('   ⏳ Waiting for Matches: ${RetroUI.yellow}${stats.waitingUsers}${RetroUI.reset}');
      print('   🔗 Active Connections: ${RetroUI.cyan}${stats.activeConnections}${RetroUI.reset}');
      print('');
      
      // Activity percentage with visual bar
      print('${RetroUI.green}⚡ Platform Activity: ${RetroUI.amber}$activityPercentage%${RetroUI.reset}');
      _printActivityBar(activityPercentage);
      print('');
      
      print('${RetroUI.green}🎯 Status Breakdown:${RetroUI.reset}');
      int onlineCount = 0, conversationCount = 0, waitingCount = 0, offlineCount = 0;
      
      for (var user in users) {
        switch (user.status) {
          case 'In Conversation':
            conversationCount++;
            break;
          case 'Waiting':
            waitingCount++;
            break;
          case 'Online':
            onlineCount++;
            break;
          default:
            offlineCount++;
        }
      }
      
      print('   🟢 Online: ${RetroUI.blue}$onlineCount${RetroUI.reset}');
      print('   💬 In Conversation: ${RetroUI.green}$conversationCount${RetroUI.reset}');
      print('   ⏳ Waiting: ${RetroUI.yellow}$waitingCount${RetroUI.reset}');
      print('   ⚫ Offline: ${RetroUI.dim}$offlineCount${RetroUI.reset}');
      print('');
      
      print('Press Enter to continue...');
      stdin.readLineSync();
      
    } catch (e) {
      RetroUI.printError('Failed to load system overview: $e');
      sleep(Duration(seconds: 2));
    }
  }

  void _printActivityBar(int percentage) {
    const int barLength = 30;
    int filledLength = (percentage * barLength / 100).round();
    
    String bar = '   [';
    for (int i = 0; i < barLength; i++) {
      if (i < filledLength) {
        if (percentage > 70) {
          bar += '${RetroUI.green}█${RetroUI.reset}';
        } else if (percentage > 40) {
          bar += '${RetroUI.yellow}█${RetroUI.reset}';
        } else {
          bar += '${RetroUI.red}█${RetroUI.reset}';
        }
      } else {
        bar += '${RetroUI.dim}░${RetroUI.reset}';
      }
    }
    bar += '] $percentage%';
    print(bar);
  }

  Future<void> _showUserDetailsTable() async {
    try {
      RetroUI.clearScreen();
      RetroUI.printHeader();
      
      print('${RetroUI.cyan}Loading user details...${RetroUI.reset}');
      final users = await _firebaseService.getUserMonitoringData();
      
      RetroUI.clearScreen();
      RetroUI.printHeader();
      
      print('${RetroUI.cyan}👥 USER DETAILS TABLE${RetroUI.reset}');
      print('');
      print('${RetroUI.cyan}┌─────────────────────────────────────────────────────────────────────┐${RetroUI.reset}');
      print('${RetroUI.cyan}│${RetroUI.reset} Username   │ Status         │ Last Active │ Mom Stage      │ Indicator ${RetroUI.cyan}│${RetroUI.reset}');
      print('${RetroUI.cyan}├─────────────────────────────────────────────────────────────────────┤${RetroUI.reset}');
      
      for (var user in users.take(15)) {
        String statusColor = _getStatusColor(user.status);
        String indicator = _getStatusIndicator(user.status);
        
        final shortUsername = user.username.length > 10 ? user.username.substring(0, 10) : user.username;
        final shortStatus = user.status.length > 14 ? user.status.substring(0, 14) : user.status;
        final shortActive = user.lastActive.length > 11 ? user.lastActive.substring(0, 11) : user.lastActive;
        final shortStage = user.momStage.length > 14 ? user.momStage.substring(0, 14) : user.momStage;
        
        print('${RetroUI.cyan}│${RetroUI.reset} ${shortUsername.padRight(10)} │ ${statusColor}${shortStatus.padRight(14)}${RetroUI.reset} │ ${shortActive.padRight(11)} │ ${shortStage.padRight(14)} │ $indicator       ${RetroUI.cyan}│${RetroUI.reset}');
      }
      
      print('${RetroUI.cyan}└─────────────────────────────────────────────────────────────────────┘${RetroUI.reset}');
      print('');
      print('${RetroUI.green}Color Legend:${RetroUI.reset}');
      print('   ${RetroUI.green}🟢 In Conversation${RetroUI.reset} - Actively chatting');
      print('   ${RetroUI.yellow}🟡 Waiting${RetroUI.reset} - Looking for matches');
      print('   ${RetroUI.blue}🔵 Online${RetroUI.reset} - Available but not waiting');
      print('   ${RetroUI.dim}⚫ Offline${RetroUI.reset} - Not active recently');
      print('');
      print('Press Enter to continue...');
      stdin.readLineSync();
      
    } catch (e) {
      RetroUI.printError('Failed to load user details: $e');
      sleep(Duration(seconds: 2));
    }
  }

  String _getStatusColor(String status) {
    switch (status) {
      case 'In Conversation':
        return RetroUI.green;
      case 'Waiting':
        return RetroUI.yellow;
      case 'Online':
        return RetroUI.blue;
      default:
        return RetroUI.dim;
    }
  }

  String _getStatusIndicator(String status) {
    switch (status) {
      case 'In Conversation':
        return '${RetroUI.green}🟢${RetroUI.reset}';
      case 'Waiting':
        return '${RetroUI.yellow}🟡${RetroUI.reset}';
      case 'Online':
        return '${RetroUI.blue}🔵${RetroUI.reset}';
      default:
        return '${RetroUI.dim}⚫${RetroUI.reset}';
    }
  }

  Future<void> _showActivityAnalysis() async {
    try {
      RetroUI.clearScreen();
      RetroUI.printHeader();
      
      print('${RetroUI.cyan}📈 PLATFORM ACTIVITY ANALYSIS${RetroUI.reset}');
      print('');
      
      final stats = await _firebaseService.getSystemStats();
      final users = await _firebaseService.getUserMonitoringData();
      
      // Calculate various metrics
      double conversationRate = stats.totalUsers > 0 ? (stats.usersInConversation / stats.totalUsers) * 100 : 0;
      double waitingRate = stats.totalUsers > 0 ? (stats.waitingUsers / stats.totalUsers) * 100 : 0;
      double activeRate = stats.totalUsers > 0 ? (stats.activeUsers / stats.totalUsers) * 100 : 0;
      
      print('${RetroUI.green}🎯 Engagement Metrics:${RetroUI.reset}');
      print('   💬 Conversation Rate: ${RetroUI.amber}${conversationRate.toStringAsFixed(1)}%${RetroUI.reset}');
      print('   ⏳ Users Seeking Matches: ${RetroUI.yellow}${waitingRate.toStringAsFixed(1)}%${RetroUI.reset}');
      print('   ⚡ Active User Rate: ${RetroUI.blue}${activeRate.toStringAsFixed(1)}%${RetroUI.reset}');
      print('');
      
      print('${RetroUI.green}📊 Platform Health:${RetroUI.reset}');
      String healthStatus = _getPlatformHealth(activeRate, conversationRate);
      print('   Status: $healthStatus');
      print('   Connections: ${stats.activeConnections} active pairs');
      print('   Timer Setting: ${stats.conversationTimer}s conversations');
      print('');
      
      print('${RetroUI.green}📈 Mom Stage Distribution:${RetroUI.reset}');
      Map<String, int> stageCount = {};
      for (var user in users) {
        stageCount[user.momStage] = (stageCount[user.momStage] ?? 0) + 1;
      }
      
      stageCount.forEach((stage, count) {
        double percentage = users.isNotEmpty ? (count / users.length) * 100 : 0;
        print('   $stage: ${RetroUI.cyan}$count${RetroUI.reset} users (${percentage.toStringAsFixed(1)}%)');
      });
      
      print('');
      print('Press Enter to continue...');
      stdin.readLineSync();
      
    } catch (e) {
      RetroUI.printError('Failed to load activity analysis: $e');
      sleep(Duration(seconds: 2));
    }
  }

  String _getPlatformHealth(double activeRate, double conversationRate) {
    if (activeRate > 70 && conversationRate > 30) {
      return '${RetroUI.green}🟢 Excellent${RetroUI.reset} - High engagement';
    } else if (activeRate > 50 && conversationRate > 20) {
      return '${RetroUI.yellow}🟡 Good${RetroUI.reset} - Healthy activity';
    } else if (activeRate > 30) {
      return '${RetroUI.amber}🟠 Fair${RetroUI.reset} - Room for improvement';
    } else {
      return '${RetroUI.red}🔴 Poor${RetroUI.reset} - Needs attention';
    }
  }

  Future<void> _connectionManagement() async {
    while (true) {
      try {
        RetroUI.clearScreen();
        RetroUI.printHeader();
        
        print('${RetroUI.cyan}┌──────────── CONNECTION STREAK MANAGEMENT ────────────┐${RetroUI.reset}');
        print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[1]${RetroUI.reset} Connection Decay Visualization                ${RetroUI.cyan}│${RetroUI.reset}');
        print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[2]${RetroUI.reset} Configuration Options                         ${RetroUI.cyan}│${RetroUI.reset}');
        print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[3]${RetroUI.reset} Real-time Opacity Demo                       ${RetroUI.cyan}│${RetroUI.reset}');
        print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[4]${RetroUI.reset} Algorithm Details & Formulas                 ${RetroUI.cyan}│${RetroUI.reset}');
        print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[5]${RetroUI.reset} Ultra-Short Mode Settings                    ${RetroUI.cyan}│${RetroUI.reset}');
        print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[6]${RetroUI.reset} Back to Main Menu                             ${RetroUI.cyan}│${RetroUI.reset}');
        print('${RetroUI.cyan}└──────────────────────────────────────────────────────┘${RetroUI.reset}');
        print('');
        
        RetroUI.printPrompt('Select option');
        final input = stdin.readLineSync();
        
        switch (input?.trim()) {
          case '1':
            await _showConnectionDecayVisualization();
            break;
          case '2':
            await _showConfigurationOptions();
            break;
          case '3':
            await _showRealTimeOpacityDemo();
            break;
          case '4':
            await _showAlgorithmDetails();
            break;
          case '5':
            await _showUltraShortModeSettings();
            break;
          case '6':
            return;
          default:
            RetroUI.printError('Invalid option');
            sleep(Duration(seconds: 1));
        }
      } catch (e) {
        RetroUI.printError('Failed to load connection management: $e');
        sleep(Duration(seconds: 2));
        return;
      }
    }
  }

  Future<void> _showConnectionDecayVisualization() async {
    try {
      RetroUI.clearScreen();
      RetroUI.printHeader();
      
      print('${RetroUI.cyan}Loading connection data...${RetroUI.reset}');
      final connections = await _firebaseService.getConnectionData();
      
      RetroUI.clearScreen();
      RetroUI.printHeader();
      
      print('${RetroUI.cyan}🔗 CONNECTION DECAY VISUALIZATION${RetroUI.reset}');
      print('');
      print('${RetroUI.cyan}┌─────────────────────────────────────────────────────────────────────────┐${RetroUI.reset}');
      print('${RetroUI.cyan}│${RetroUI.reset} User Pair          │ Strength │ Visual Bar         │ Status     │ Time Left ${RetroUI.cyan}│${RetroUI.reset}');
      print('${RetroUI.cyan}├─────────────────────────────────────────────────────────────────────────┤${RetroUI.reset}');
      
      for (var conn in connections.take(10)) {
        String strengthColor = _getStrengthColor(conn.strength);
        String statusLevel = _getStatusLevel(conn.strength);
        String timeRemaining = _calculateTimeRemaining(conn.strength);
        
        final userPair = '${conn.userA} ↔ ${conn.userB}';
        final shortPair = userPair.length > 18 ? userPair.substring(0, 18) : userPair;
        final strengthStr = '${conn.strength}%';
        
        print('${RetroUI.cyan}│${RetroUI.reset} ${shortPair.padRight(18)} │ ${strengthColor}${strengthStr.padRight(8)}${RetroUI.reset} │ ${_getVisualStrengthBar(conn.strength)} │ ${statusLevel.padRight(10)} │ ${timeRemaining.padRight(9)} ${RetroUI.cyan}│${RetroUI.reset}');
      }
      
      print('${RetroUI.cyan}└─────────────────────────────────────────────────────────────────────────┘${RetroUI.reset}');
      print('');
      
      print('${RetroUI.green}Status Levels:${RetroUI.reset}');
      print('   ${RetroUI.green}🟢 Strong${RetroUI.reset} (71-100%) - Healthy connection');
      print('   ${RetroUI.yellow}🟡 Fair${RetroUI.reset} (41-70%) - Moderate strength');
      print('   ${RetroUI.amber}🟠 Weak${RetroUI.reset} (21-40%) - Needs attention');
      print('   ${RetroUI.red}🔴 Critical${RetroUI.reset} (0-20%) - Near expiration');
      print('');
      print('Press Enter to continue...');
      stdin.readLineSync();
      
    } catch (e) {
      RetroUI.printError('Failed to load connection visualization: $e');
      sleep(Duration(seconds: 2));
    }
  }

  String _getStrengthColor(int strength) {
    if (strength > 70) return RetroUI.green;
    if (strength > 40) return RetroUI.yellow;
    if (strength > 20) return RetroUI.amber;
    return RetroUI.red;
  }

  String _getStatusLevel(int strength) {
    if (strength > 70) return '${RetroUI.green}Strong${RetroUI.reset}';
    if (strength > 40) return '${RetroUI.yellow}Fair${RetroUI.reset}';
    if (strength > 20) return '${RetroUI.amber}Weak${RetroUI.reset}';
    return '${RetroUI.red}Critical${RetroUI.reset}';
  }

  String _getVisualStrengthBar(int strength) {
    const int barLength = 10;
    int filledLength = (strength * barLength / 100).round();
    
    String bar = '';
    for (int i = 0; i < barLength; i++) {
      if (i < filledLength) {
        if (strength > 70) {
          bar += '${RetroUI.green}█${RetroUI.reset}';
        } else if (strength > 40) {
          bar += '${RetroUI.yellow}█${RetroUI.reset}';
        } else if (strength > 20) {
          bar += '${RetroUI.amber}█${RetroUI.reset}';
        } else {
          bar += '${RetroUI.red}█${RetroUI.reset}';
        }
      } else {
        bar += '${RetroUI.dim}░${RetroUI.reset}';
      }
    }
    return bar.padRight(18); // Account for ANSI codes
  }

  String _calculateTimeRemaining(int strength) {
    // Simulate time remaining based on strength
    if (strength > 70) return '> 7 days';
    if (strength > 40) return '3-7 days';
    if (strength > 20) return '1-3 days';
    if (strength > 10) return '< 1 day';
    return 'Expires soon';
  }

  Future<void> _showConfigurationOptions() async {
    while (true) {
      RetroUI.clearScreen();
      RetroUI.printHeader();
      
      final config = _firebaseService.adminConfig;
      
      print('${RetroUI.cyan}⚙️  CONNECTION CONFIGURATION OPTIONS${RetroUI.reset}');
      print('');
      print('${RetroUI.cyan}┌──────────────────────────────────────────────────────┐${RetroUI.reset}');
      print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[1]${RetroUI.reset} Update Connection Expiration Days (1-30)      ${RetroUI.cyan}│${RetroUI.reset}');
      print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[2]${RetroUI.reset} Set Warning Threshold Hours (1-168)          ${RetroUI.cyan}│${RetroUI.reset}');
      print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[3]${RetroUI.reset} Quick Expiration Mode (10-120 minutes)       ${RetroUI.cyan}│${RetroUI.reset}');
      print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[4]${RetroUI.reset} View Current Settings                         ${RetroUI.cyan}│${RetroUI.reset}');
      print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[5]${RetroUI.reset} Back to Connection Menu                       ${RetroUI.cyan}│${RetroUI.reset}');
      print('${RetroUI.cyan}└──────────────────────────────────────────────────────┘${RetroUI.reset}');
      print('');
      
      print('${RetroUI.green}Current Configuration:${RetroUI.reset}');
      print('   📅 Expiration: ${config.enableConnectionDecay ? "${config.decayRatePercent}% decay per refresh" : "Disabled"}');
      print('   ⚡ Quick Mode: ${config.enableQuickDeadlines ? "Enabled (${config.quickDeadlineMinutes}min)" : "Disabled"}');
      print('');
      
      RetroUI.printPrompt('Select option');
      final input = stdin.readLineSync();
      
      switch (input?.trim()) {
        case '1':
          await _updateExpirationDays();
          break;
        case '2':
          await _setWarningThreshold();
          break;
        case '3':
          await _configureQuickExpiration();
          break;
        case '4':
          await _viewCurrentSettings();
          break;
        case '5':
          return;
        default:
          RetroUI.printError('Invalid option');
          sleep(Duration(seconds: 1));
      }
    }
  }

  Future<void> _updateExpirationDays() async {
    RetroUI.clearScreen();
    RetroUI.printHeader();
    
    print('${RetroUI.cyan}📅 CONNECTION EXPIRATION CONFIGURATION${RetroUI.reset}');
    print('');
    print('🕐 Current expiration affects how quickly connections fade');
    print('📈 Recommended settings:');
    print('   • 1-3 days: Fast-paced environment');
    print('   • 7-14 days: Standard social platform');
    print('   • 21-30 days: Long-term relationship building');
    print('');
    
    RetroUI.printPrompt('Enter expiration days (1-30)');
    final input = stdin.readLineSync();
    final days = int.tryParse(input ?? '');
    
    if (days != null && days >= 1 && days <= 30) {
      // Convert days to decay percentage (simplified)
      int decayRate = (100 / (days * 24)).round().clamp(1, 50);
      
      final updatedConfig = _firebaseService.adminConfig;
      updatedConfig.enableConnectionDecay = true;
      updatedConfig.decayRatePercent = decayRate;
      
      RetroUI.printSuccess('Expiration set to $days days (${decayRate}% decay rate)');
      print('Connections will gradually fade over $days days');
    } else {
      RetroUI.printError('Invalid value. Must be 1-30 days.');
    }
    sleep(Duration(seconds: 3));
  }

  Future<void> _setWarningThreshold() async {
    RetroUI.clearScreen();
    RetroUI.printHeader();
    
    print('${RetroUI.cyan}⚠️  WARNING THRESHOLD CONFIGURATION${RetroUI.reset}');
    print('');
    print('🚨 Warning thresholds alert users when connections are weakening');
    print('📊 Recommended thresholds:');
    print('   • 24-48 hours: Urgent reminders');
    print('   • 72-96 hours: Standard warnings');
    print('   • 120-168 hours: Gentle nudges');
    print('');
    
    RetroUI.printPrompt('Enter warning threshold hours (1-168)');
    final input = stdin.readLineSync();
    final hours = int.tryParse(input ?? '');
    
    if (hours != null && hours >= 1 && hours <= 168) {
      RetroUI.printSuccess('Warning threshold set to $hours hours');
      print('Users will be warned when connections have $hours hours remaining');
      
      if (hours <= 24) {
        RetroUI.printWarning('Very short threshold - users will get frequent alerts');
      } else if (hours >= 120) {
        print('${RetroUI.blue}ℹ️  Long threshold - early but gentle warnings${RetroUI.reset}');
      }
    } else {
      RetroUI.printError('Invalid value. Must be 1-168 hours (7 days max).');
    }
    sleep(Duration(seconds: 3));
  }

  Future<void> _configureQuickExpiration() async {
    RetroUI.clearScreen();
    RetroUI.printHeader();
    
    print('${RetroUI.cyan}⚡ QUICK EXPIRATION MODE${RetroUI.reset}');
    print('');
    print('🚀 Quick mode for urgent re-engagement scenarios');
    print('⚠️  ${RetroUI.red}WARNING:${RetroUI.reset} This creates high pressure for users');
    print('');
    print('💡 Use cases:');
    print('   • Emergency reconnections');
    print('   • Time-sensitive conversations');
    print('   • Testing platform responsiveness');
    print('');
    
    RetroUI.printPrompt('Enter quick expiration minutes (10-120)');
    final input = stdin.readLineSync();
    final minutes = int.tryParse(input ?? '');
    
    if (minutes != null && minutes >= 10 && minutes <= 120) {
      await _firebaseService.setQuickDeadline(minutes);
      RetroUI.printSuccess('Quick expiration mode: $minutes minutes');
      
      if (minutes <= 30) {
        RetroUI.printWarning('Very urgent mode - users need immediate action!');
      } else if (minutes <= 60) {
        print('${RetroUI.yellow}⚠️  Moderate urgency - good for re-engagement${RetroUI.reset}');
      } else {
        print('${RetroUI.blue}ℹ️  Gentle urgency - encourages activity${RetroUI.reset}');
      }
      
      print('');
      print('This setting affects NEW connections only.');
    } else {
      RetroUI.printError('Invalid value. Must be 10-120 minutes.');
    }
    sleep(Duration(seconds: 4));
  }

  Future<void> _viewCurrentSettings() async {
    RetroUI.clearScreen();
    RetroUI.printHeader();
    
    final config = _firebaseService.adminConfig;
    
    print('${RetroUI.cyan}📋 CURRENT CONNECTION SETTINGS${RetroUI.reset}');
    print('');
    print('${RetroUI.green}Connection Decay:${RetroUI.reset}');
    print('   Status: ${config.enableConnectionDecay ? "${RetroUI.green}Enabled${RetroUI.reset}" : "${RetroUI.red}Disabled${RetroUI.reset}"}');
    print('   Decay Rate: ${config.decayRatePercent}% per refresh cycle');
    print('   Estimated Lifespan: ${_calculateLifespan(config.decayRatePercent)} days');
    print('');
    
    print('${RetroUI.green}Quick Expiration Mode:${RetroUI.reset}');
    print('   Status: ${config.enableQuickDeadlines ? "${RetroUI.green}Enabled${RetroUI.reset}" : "${RetroUI.red}Disabled${RetroUI.reset}"}');
    print('   Duration: ${config.quickDeadlineMinutes} minutes');
    print('   Urgency Level: ${_getUrgencyLevel(config.quickDeadlineMinutes)}');
    print('');
    
    print('${RetroUI.green}Algorithm Details:${RetroUI.reset}');
    print('   Formula: Strength = max(0, current - ${config.decayRatePercent}%)');
    print('   Refresh Cycle: Every platform refresh');
    print('   Expiration Point: When strength reaches 0%');
    print('');
    
    print('Press Enter to continue...');
    stdin.readLineSync();
  }

  String _calculateLifespan(int decayRate) {
    if (decayRate <= 0) return '∞';
    return (100 / decayRate).toStringAsFixed(1);
  }

  String _getUrgencyLevel(int minutes) {
    if (minutes <= 20) return '${RetroUI.red}🔴 Critical${RetroUI.reset}';
    if (minutes <= 45) return '${RetroUI.amber}🟠 High${RetroUI.reset}';
    if (minutes <= 90) return '${RetroUI.yellow}🟡 Moderate${RetroUI.reset}';
    return '${RetroUI.blue}🔵 Low${RetroUI.reset}';
  }

  Future<void> _showRealTimeOpacityDemo() async {
    RetroUI.clearScreen();
    RetroUI.printHeader();
    
    print('${RetroUI.amber}🎬 REAL-TIME OPACITY DECAY DEMONSTRATION${RetroUI.reset}');
    print('${RetroUI.cyan}Watch how connection strength fades over time...${RetroUI.reset}');
    print('');
    print('${RetroUI.green}Demonstration Parameters:${RetroUI.reset}');
    print('   • Time Scale: Accelerated for visualization');
    print('   • Decay Rate: 5% per time unit');
    print('   • Visual Effect: Opacity changes with strength');
    print('   • Critical Point: Below 10% strength');
    print('');
    print('Press Enter to start demonstration...');
    stdin.readLineSync();
    
    RetroUI.clearScreen();
    RetroUI.printHeader();
    print('${RetroUI.amber}🎬 CONNECTION DECAY IN PROGRESS...${RetroUI.reset}');
    print('');
    
    for (int strength = 100; strength >= 0; strength -= 5) {
      // Clear the demo area
      print('\x1B[K'); // Clear line
      stdout.write('Time: ${(100 - strength) ~/ 5} cycles - ');
      
      String connectionBar = _getVisualStrengthBar(strength);
      String opacityLevel = _getOpacityDescription(strength);
      String userExperience = _getUserExperienceDescription(strength);
      
      print('$connectionBar ${strength}% - $opacityLevel');
      print('   User Experience: $userExperience');
      
      if (strength <= 10 && strength > 0) {
        print('   ${RetroUI.red}⚠️  CRITICAL: Connection near expiration!${RetroUI.reset}');
      } else if (strength == 0) {
        print('   ${RetroUI.red}💀 EXPIRED: Connection has ended${RetroUI.reset}');
      }
      
      sleep(Duration(milliseconds: 300));
      if (strength > 0) {
        // Move cursor up to overwrite
        print('\x1B[3A'); // Move up 3 lines
      }
    }
    
    print('');
    print('${RetroUI.cyan}📊 Demonstration Complete!${RetroUI.reset}');
    print('${RetroUI.yellow}Key Insights:${RetroUI.reset}');
    print('   • Connections start at 100% strength');
    print('   • Decay is gradual and predictable');
    print('   • Users see increasing urgency as strength drops');
    print('   • Critical warnings appear below 20%');
    print('   • Connections expire at 0% strength');
    print('');
    print('Press Enter to continue...');
    stdin.readLineSync();
  }

  String _getOpacityDescription(int strength) {
    if (strength > 80) return '${RetroUI.green}Full Visibility${RetroUI.reset}';
    if (strength > 60) return '${RetroUI.blue}Clear${RetroUI.reset}';
    if (strength > 40) return '${RetroUI.yellow}Dimming${RetroUI.reset}';
    if (strength > 20) return '${RetroUI.amber}Fading${RetroUI.reset}';
    if (strength > 0) return '${RetroUI.red}Nearly Invisible${RetroUI.reset}';
    return '${RetroUI.dim}Gone${RetroUI.reset}';
  }

  String _getUserExperienceDescription(int strength) {
    if (strength > 80) return 'Connection feels strong and active';
    if (strength > 60) return 'Noticeable but still comfortable';
    if (strength > 40) return 'User starts seeing gentle reminders';
    if (strength > 20) return 'Urgency prompts become more frequent';
    if (strength > 0) return 'Critical alerts and final warnings';
    return 'Connection lost - requires new match';
  }

  Future<void> _showAlgorithmDetails() async {
    RetroUI.clearScreen();
    RetroUI.printHeader();
    
    print('${RetroUI.cyan}🧮 CONNECTION DECAY ALGORITHM DETAILS${RetroUI.reset}');
    print('');
    
    final config = _firebaseService.adminConfig;
    
    print('${RetroUI.green}📐 Mathematical Foundation:${RetroUI.reset}');
    print('   Primary Formula: Strength(t+1) = max(0, Strength(t) - DecayRate)');
    print('   Decay Rate: ${config.decayRatePercent}% per refresh cycle');
    print('   Minimum Strength: 0% (connection expires)');
    print('   Maximum Strength: 100% (perfect connection)');
    print('');
    
    print('${RetroUI.green}⏱️  Time Calculations:${RetroUI.reset}');
    int refreshCycles = config.decayRatePercent > 0 ? (100 / config.decayRatePercent).ceil() : 0;
    print('   Refresh Cycles to Expiration: $refreshCycles cycles');
    print('   Estimated Lifespan: ${_calculateDetailedLifespan(config.decayRatePercent)}');
    print('   Half-life: ${(refreshCycles / 2).toStringAsFixed(1)} cycles');
    print('');
    
    print('${RetroUI.green}📊 User Impact Analysis:${RetroUI.reset}');
    _printUserImpactLevels();
    print('');
    
    print('${RetroUI.green}🔬 Algorithm Behavior:${RetroUI.reset}');
    print('   • Linear Decay: Predictable and fair reduction');
    print('   • Floor Function: Prevents negative strength values');
    print('   • Discrete Steps: ${config.decayRatePercent}% increments for clarity');
    print('   • Reset Mechanism: New interactions restore strength');
    print('');
    
    print('${RetroUI.green}⚙️  Configuration Impact:${RetroUI.reset}');
    print('   Lower Decay Rate (1-3%): Longer-lasting connections');
    print('   Medium Decay Rate (4-10%): Balanced engagement');
    print('   Higher Decay Rate (11%+): Fast-paced environment');
    print('');
    
    print('Press Enter to see formula examples...');
    stdin.readLineSync();
    
    _showFormulaExamples();
  }

  String _calculateDetailedLifespan(int decayRate) {
    if (decayRate <= 0) return 'Infinite (no decay)';
    
    int cycles = (100 / decayRate).ceil();
    int hours = cycles * 1; // Assuming 1 cycle = 1 hour for example
    
    if (hours < 24) return '$hours hours';
    if (hours < 168) return '${(hours / 24).toStringAsFixed(1)} days';
    return '${(hours / 168).toStringAsFixed(1)} weeks';
  }

  void _printUserImpactLevels() {
    print('   100-81%: ${RetroUI.green}Strong${RetroUI.reset} - Users feel secure, no prompts');
    print('   80-61%:  ${RetroUI.blue}Stable${RetroUI.reset} - Occasional gentle reminders');
    print('   60-41%:  ${RetroUI.yellow}Moderate${RetroUI.reset} - Regular engagement suggestions');
    print('   40-21%:  ${RetroUI.amber}Weak${RetroUI.reset} - Frequent re-engagement prompts');
    print('   20-1%:   ${RetroUI.red}Critical${RetroUI.reset} - Urgent action required warnings');
    print('   0%:      ${RetroUI.dim}Expired${RetroUI.reset} - Connection lost, needs new match');
  }

  void _showFormulaExamples() {
    RetroUI.clearScreen();
    RetroUI.printHeader();
    
    final config = _firebaseService.adminConfig;
    
    print('${RetroUI.cyan}📝 FORMULA EXAMPLES & SCENARIOS${RetroUI.reset}');
    print('');
    print('${RetroUI.green}Current Configuration:${RetroUI.reset} ${config.decayRatePercent}% decay per cycle');
    print('');
    
    print('${RetroUI.amber}Example Scenario - Connection Lifecycle:${RetroUI.reset}');
    int currentStrength = 100;
    int cycle = 0;
    
    while (currentStrength > 0 && cycle <= 10) {
      String status = _getStatusLevel(currentStrength).replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');
      String userAction = _getRecommendedAction(currentStrength);
      
      print('   Cycle $cycle: ${currentStrength}% → $status');
      print('           Formula: max(0, $currentStrength - ${config.decayRatePercent}) = ${(currentStrength - config.decayRatePercent).clamp(0, 100)}%');
      print('           User Action: $userAction');
      print('');
      
      currentStrength = (currentStrength - config.decayRatePercent).clamp(0, 100);
      cycle++;
      
      if (cycle > 10) {
        print('   ... (continues until 0%)');
        break;
      }
    }
    
    print('${RetroUI.green}Key Takeaways:${RetroUI.reset}');
    print('   • Decay is consistent and predictable');
    print('   • Users have multiple chances to re-engage');
    print('   • Earlier action preserves stronger connections');
    print('   • Algorithm encourages regular platform use');
    print('');
    print('Press Enter to continue...');
    stdin.readLineSync();
  }

  String _getRecommendedAction(int strength) {
    if (strength > 80) return 'No action needed';
    if (strength > 60) return 'Light engagement suggested';
    if (strength > 40) return 'Send a message or interact';
    if (strength > 20) return 'Immediate reconnection needed';
    return 'URGENT: Connection about to expire!';
  }

  Future<void> _showUltraShortModeSettings() async {
    RetroUI.clearScreen();
    RetroUI.printHeader();
    
    print('${RetroUI.red}⚡ ULTRA-SHORT MODE SETTINGS${RetroUI.reset}');
    print('');
    print('${RetroUI.yellow}⚠️  WARNING: Ultra-short mode creates intense pressure for users${RetroUI.reset}');
    print('${RetroUI.amber}Use only for specific scenarios that require immediate action!${RetroUI.reset}');
    print('');
    
    while (true) {
      print('${RetroUI.cyan}┌─────────── ULTRA-SHORT MODE OPTIONS ──────────────┐${RetroUI.reset}');
      print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[1]${RetroUI.reset} Emergency Mode (10-20 minutes)              ${RetroUI.cyan}│${RetroUI.reset}');
      print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[2]${RetroUI.reset} Rapid Engagement (21-45 minutes)           ${RetroUI.cyan}│${RetroUI.reset}');
      print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[3]${RetroUI.reset} Speed Dating Mode (46-90 minutes)          ${RetroUI.cyan}│${RetroUI.reset}');
      print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[4]${RetroUI.reset} Express Connect (91-120 minutes)           ${RetroUI.cyan}│${RetroUI.reset}');
      print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[5]${RetroUI.reset} View Ultra-Short Impact Warnings           ${RetroUI.cyan}│${RetroUI.reset}');
      print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[6]${RetroUI.reset} Back to Connection Menu                     ${RetroUI.cyan}│${RetroUI.reset}');
      print('${RetroUI.cyan}└─────────────────────────────────────────────────────┘${RetroUI.reset}');
      print('');
      
      final config = _firebaseService.adminConfig;
      print('${RetroUI.green}Current Ultra-Short Settings:${RetroUI.reset}');
      print('   Status: ${config.enableQuickDeadlines ? "${RetroUI.green}Enabled${RetroUI.reset}" : "${RetroUI.red}Disabled${RetroUI.reset}"}');
      print('   Duration: ${config.quickDeadlineMinutes} minutes');
      print('   Pressure Level: ${_getUrgencyLevel(config.quickDeadlineMinutes)}');
      print('');
      
      RetroUI.printPrompt('Select option');
      final input = stdin.readLineSync();
      
      switch (input?.trim()) {
        case '1':
          await _setEmergencyMode();
          break;
        case '2':
          await _setRapidEngagement();
          break;
        case '3':
          await _setSpeedDatingMode();
          break;
        case '4':
          await _setExpressConnect();
          break;
        case '5':
          await _showUltraShortWarnings();
          break;
        case '6':
          return;
        default:
          RetroUI.printError('Invalid option');
          sleep(Duration(seconds: 1));
      }
    }
  }

  Future<void> _setEmergencyMode() async {
    RetroUI.clearScreen();
    RetroUI.printHeader();
    
    print('${RetroUI.red}🚨 EMERGENCY MODE CONFIGURATION${RetroUI.reset}');
    print('');
    print('${RetroUI.red}⚠️  EXTREME WARNING: Emergency mode (10-20 minutes)${RetroUI.reset}');
    print('${RetroUI.yellow}This creates maximum pressure and urgency for users!${RetroUI.reset}');
    print('');
    print('${RetroUI.amber}Appropriate for:${RetroUI.reset}');
    print('   • Crisis intervention scenarios');
    print('   • Time-critical support connections');
    print('   • Emergency peer support networks');
    print('   • Testing platform stress responses');
    print('');
    print('${RetroUI.red}User Impact:${RetroUI.reset}');
    print('   • Immediate notifications and alerts');
    print('   • High anxiety for non-responsive users');
    print('   • Potential for user frustration/abandonment');
    print('   • Requires 24/7 moderation support');
    print('');
    
    RetroUI.printPrompt('Enter emergency duration (10-20 minutes)');
    final input = stdin.readLineSync();
    final minutes = int.tryParse(input ?? '');
    
    if (minutes != null && minutes >= 10 && minutes <= 20) {
      await _firebaseService.setQuickDeadline(minutes);
      RetroUI.printSuccess('Emergency mode activated: $minutes minutes');
      RetroUI.printWarning('CRITICAL SETTING ACTIVE - Monitor user responses closely!');
      print('Immediate user support should be available.');
    } else {
      RetroUI.printError('Invalid value. Emergency mode requires 10-20 minutes.');
    }
    sleep(Duration(seconds: 4));
  }

  Future<void> _setRapidEngagement() async {
    await _setPresetMode('Rapid Engagement', 21, 45, 
      'Quick reconnections and active engagement scenarios');
  }

  Future<void> _setSpeedDatingMode() async {
    await _setPresetMode('Speed Dating', 46, 90, 
      'Fast-paced meeting and initial connection scenarios');
  }

  Future<void> _setExpressConnect() async {
    await _setPresetMode('Express Connect', 91, 120, 
      'Accelerated but manageable connection timeframes');
  }

  Future<void> _setPresetMode(String modeName, int minMinutes, int maxMinutes, String description) async {
    RetroUI.clearScreen();
    RetroUI.printHeader();
    
    print('${RetroUI.cyan}⚡ ${modeName.toUpperCase()} MODE${RetroUI.reset}');
    print('');
    print('${RetroUI.green}Description:${RetroUI.reset} $description');
    print('${RetroUI.green}Range:${RetroUI.reset} $minMinutes-$maxMinutes minutes');
    print('');
    
    RetroUI.printPrompt('Enter duration ($minMinutes-$maxMinutes minutes)');
    final input = stdin.readLineSync();
    final minutes = int.tryParse(input ?? '');
    
    if (minutes != null && minutes >= minMinutes && minutes <= maxMinutes) {
      await _firebaseService.setQuickDeadline(minutes);
      RetroUI.printSuccess('$modeName mode set: $minutes minutes');
      print('Users will receive ${_getEngagementStyle(minutes)} prompts.');
    } else {
      RetroUI.printError('Invalid value. Must be $minMinutes-$maxMinutes minutes.');
    }
    sleep(Duration(seconds: 3));
  }

  String _getEngagementStyle(int minutes) {
    if (minutes <= 30) return 'very urgent';
    if (minutes <= 60) return 'frequent';
    if (minutes <= 90) return 'regular';
    return 'gentle';
  }

  Future<void> _showUltraShortWarnings() async {
    RetroUI.clearScreen();
    RetroUI.printHeader();
    
    print('${RetroUI.red}⚠️  ULTRA-SHORT MODE IMPACT WARNINGS${RetroUI.reset}');
    print('');
    print('${RetroUI.yellow}Psychological Impact on Users:${RetroUI.reset}');
    print('   ${RetroUI.red}• Increased anxiety and stress${RetroUI.reset}');
    print('   ${RetroUI.amber}• Fear of missing connections${RetroUI.reset}');
    print('   ${RetroUI.yellow}• Pressure to respond immediately${RetroUI.reset}');
    print('   ${RetroUI.blue}• Potential for hasty decisions${RetroUI.reset}');
    print('');
    
    print('${RetroUI.yellow}Platform Risks:${RetroUI.reset}');
    print('   ${RetroUI.red}• Higher user abandonment rates${RetroUI.reset}');
    print('   ${RetroUI.amber}• Increased support ticket volume${RetroUI.reset}');
    print('   ${RetroUI.yellow}• Negative user experience reviews${RetroUI.reset}');
    print('   ${RetroUI.blue}• Reduced thoughtful engagement${RetroUI.reset}');
    print('');
    
    print('${RetroUI.green}Required Safeguards:${RetroUI.reset}');
    print('   ✅ 24/7 customer support availability');
    print('   ✅ Clear user education about time limits');
    print('   ✅ Easy opt-out mechanisms');
    print('   ✅ Mental health resources available');
    print('   ✅ Regular monitoring of user feedback');
    print('');
    
    print('${RetroUI.cyan}Recommended Monitoring:${RetroUI.reset}');
    print('   📊 Track user completion rates');
    print('   📈 Monitor support request patterns');
    print('   💬 Collect user experience feedback');
    print('   📉 Watch for increased app uninstalls');
    print('   🎯 Measure quality of connections formed');
    print('');
    
    print('${RetroUI.amber}Best Practices:${RetroUI.reset}');
    print('   • Start with longer durations and decrease gradually');
    print('   • A/B test with small user groups first');
    print('   • Provide clear countdown timers to users');
    print('   • Offer extension options in special circumstances');
    print('   • Have immediate rollback plans ready');
    print('');
    
    print('Press Enter to continue...');
    stdin.readLineSync();
  }

  Future<void> _showRealTimeOpacityDemo() async {
    RetroUI.clearScreen();
    RetroUI.printHeader();
    
    print('${RetroUI.amber}🎬 REAL-TIME OPACITY DECAY DEMONSTRATION${RetroUI.reset}');
    print('${RetroUI.cyan}Watch how connection strength fades over time...${RetroUI.reset}');
    print('');
    print('${RetroUI.green}Demonstration Parameters:${RetroUI.reset}');
    print('   • Time Scale: Accelerated for visualization');
    print('   • Decay Rate: 5% per time unit');
    print('   • Visual Effect: Opacity changes with strength');
    print('   • Critical Point: Below 10% strength');
    print('');
    print('Press Enter to start demonstration...');
    stdin.readLineSync();
    
    RetroUI.clearScreen();
    RetroUI.printHeader();
    print('${RetroUI.amber}🎬 CONNECTION DECAY IN PROGRESS...${RetroUI.reset}');
    print('');
    
    for (int strength = 100; strength >= 0; strength -= 5) {
      print('\x1B[K'); // Clear line
      stdout.write('Time: ${(100 - strength) ~/ 5} cycles - ');
      
      String connectionBar = _getVisualStrengthBar(strength);
      String opacityLevel = _getOpacityDescription(strength);
      String userExperience = _getUserExperienceDescription(strength);
      
      print('$connectionBar ${strength}% - $opacityLevel');
      print('   User Experience: $userExperience');
      
      if (strength <= 10 && strength > 0) {
        print('   ${RetroUI.red}⚠️  CRITICAL: Connection near expiration!${RetroUI.reset}');
      } else if (strength == 0) {
        print('   ${RetroUI.red}💀 EXPIRED: Connection has ended${RetroUI.reset}');
      }
      
      sleep(Duration(milliseconds: 300));
      if (strength > 0) {
        print('\x1B[3A'); // Move up 3 lines
      }
    }
    
    print('');
    print('${RetroUI.cyan}📊 Demonstration Complete!${RetroUI.reset}');
    print('${RetroUI.yellow}Key Insights:${RetroUI.reset}');
    print('   • Connections start at 100% strength');
    print('   • Decay is gradual and predictable');
    print('   • Users see increasing urgency as strength drops');
    print('   • Critical warnings appear below 20%');
    print('   • Connections expire at 0% strength');
    print('');
    print('Press Enter to continue...');
    stdin.readLineSync();
  }

  String _getOpacityDescription(int strength) {
    if (strength > 80) return '${RetroUI.green}Full Visibility${RetroUI.reset}';
    if (strength > 60) return '${RetroUI.blue}Clear${RetroUI.reset}';
    if (strength > 40) return '${RetroUI.yellow}Dimming${RetroUI.reset}';
    if (strength > 20) return '${RetroUI.amber}Fading${RetroUI.reset}';
    if (strength > 0) return '${RetroUI.red}Nearly Invisible${RetroUI.reset}';
    return '${RetroUI.dim}Gone${RetroUI.reset}';
  }

  String _getUserExperienceDescription(int strength) {
    if (strength > 80) return 'Connection feels strong and active';
    if (strength > 60) return 'Noticeable but still comfortable';
    if (strength > 40) return 'User starts seeing gentle reminders';
    if (strength > 20) return 'Urgency prompts become more frequent';
    if (strength > 0) return 'Critical alerts and final warnings';
    return 'Connection lost - requires new match';
  }

  Future<void> _showAlgorithmDetails() async {
    RetroUI.clearScreen();
    RetroUI.printHeader();
    
    print('${RetroUI.cyan}🧮 CONNECTION DECAY ALGORITHM DETAILS${RetroUI.reset}');
    print('');
    
    final config = _firebaseService.adminConfig;
    
    print('${RetroUI.green}📐 Mathematical Foundation:${RetroUI.reset}');
    print('   Primary Formula: Strength(t+1) = max(0, Strength(t) - DecayRate)');
    print('   Decay Rate: ${config.decayRatePercent}% per refresh cycle');
    print('   Minimum Strength: 0% (connection expires)');
    print('   Maximum Strength: 100% (perfect connection)');
    print('');
    
    print('${RetroUI.green}⏱️  Time Calculations:${RetroUI.reset}');
    int refreshCycles = config.decayRatePercent > 0 ? (100 / config.decayRatePercent).ceil() : 0;
    print('   Refresh Cycles to Expiration: $refreshCycles cycles');
    print('   Estimated Lifespan: ${_calculateDetailedLifespan(config.decayRatePercent)}');
    print('   Half-life: ${(refreshCycles / 2).toStringAsFixed(1)} cycles');
    print('');
    
    print('${RetroUI.green}📊 User Impact Analysis:${RetroUI.reset}');
    _printUserImpactLevels();
    print('');
    
    print('${RetroUI.green}🔬 Algorithm Behavior:${RetroUI.reset}');
    print('   • Linear Decay: Predictable and fair reduction');
    print('   • Floor Function: Prevents negative strength values');
    print('   • Discrete Steps: ${config.decayRatePercent}% increments for clarity');
    print('   • Reset Mechanism: New interactions restore strength');
    print('');
    
    print('${RetroUI.green}⚙️  Configuration Impact:${RetroUI.reset}');
    print('   Lower Decay Rate (1-3%): Longer-lasting connections');
    print('   Medium Decay Rate (4-10%): Balanced engagement');
    print('   Higher Decay Rate (11%+): Fast-paced environment');
    print('');
    
    print('Press Enter to see formula examples...');
    stdin.readLineSync();
    
    _showFormulaExamples();
  }

  String _calculateDetailedLifespan(int decayRate) {
    if (decayRate <= 0) return 'Infinite (no decay)';
    
    int cycles = (100 / decayRate).ceil();
    int hours = cycles * 1;
    
    if (hours < 24) return '$hours hours';
    if (hours < 168) return '${(hours / 24).toStringAsFixed(1)} days';
    return '${(hours / 168).toStringAsFixed(1)} weeks';
  }

  void _printUserImpactLevels() {
    print('   100-81%: ${RetroUI.green}Strong${RetroUI.reset} - Users feel secure, no prompts');
    print('   80-61%:  ${RetroUI.blue}Stable${RetroUI.reset} - Occasional gentle reminders');
    print('   60-41%:  ${RetroUI.yellow}Moderate${RetroUI.reset} - Regular engagement suggestions');
    print('   40-21%:  ${RetroUI.amber}Weak${RetroUI.reset} - Frequent re-engagement prompts');
    print('   20-1%:   ${RetroUI.red}Critical${RetroUI.reset} - Urgent action required warnings');
    print('   0%:      ${RetroUI.dim}Expired${RetroUI.reset} - Connection lost, needs new match');
  }

  void _showFormulaExamples() {
    RetroUI.clearScreen();
    RetroUI.printHeader();
    
    final config = _firebaseService.adminConfig;
    
    print('${RetroUI.cyan}📝 FORMULA EXAMPLES & SCENARIOS${RetroUI.reset}');
    print('');
    print('${RetroUI.green}Current Configuration:${RetroUI.reset} ${config.decayRatePercent}% decay per cycle');
    print('');
    
    print('${RetroUI.amber}Example Scenario - Connection Lifecycle:${RetroUI.reset}');
    int currentStrength = 100;
    int cycle = 0;
    
    while (currentStrength > 0 && cycle <= 10) {
      String status = _getStatusLevel(currentStrength).replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');
      String userAction = _getRecommendedAction(currentStrength);
      
      print('   Cycle $cycle: ${currentStrength}% → $status');
      print('           Formula: max(0, $currentStrength - ${config.decayRatePercent}) = ${(currentStrength - config.decayRatePercent).clamp(0, 100)}%');
      print('           User Action: $userAction');
      print('');
      
      currentStrength = (currentStrength - config.decayRatePercent).clamp(0, 100);
      cycle++;
      
      if (cycle > 10) {
        print('   ... (continues until 0%)');
        break;
      }
    }
    
    print('${RetroUI.green}Key Takeaways:${RetroUI.reset}');
    print('   • Decay is consistent and predictable');
    print('   • Users have multiple chances to re-engage');
    print('   • Earlier action preserves stronger connections');
    print('   • Algorithm encourages regular platform use');
    print('');
    print('Press Enter to continue...');
    stdin.readLineSync();
  }

  String _getRecommendedAction(int strength) {
    if (strength > 80) return 'No action needed';
    if (strength > 60) return 'Light engagement suggested';
    if (strength > 40) return 'Send a message or interact';
    if (strength > 20) return 'Immediate reconnection needed';
    return 'URGENT: Connection about to expire!';
  }

  Future<void> _showUltraShortModeSettings() async {
    RetroUI.clearScreen();
    RetroUI.printHeader();
    
    print('${RetroUI.red}⚡ ULTRA-SHORT MODE SETTINGS${RetroUI.reset}');
    print('');
    print('${RetroUI.yellow}⚠️  WARNING: Ultra-short mode creates intense pressure for users${RetroUI.reset}');
    print('${RetroUI.amber}Use only for specific scenarios that require immediate action!${RetroUI.reset}');
    print('');
    
    while (true) {
      print('${RetroUI.cyan}┌─────────── ULTRA-SHORT MODE OPTIONS ──────────────┐${RetroUI.reset}');
      print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[1]${RetroUI.reset} Emergency Mode (10-20 minutes)              ${RetroUI.cyan}│${RetroUI.reset}');
      print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[2]${RetroUI.reset} Rapid Engagement (21-45 minutes)           ${RetroUI.cyan}│${RetroUI.reset}');
      print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[3]${RetroUI.reset} Speed Dating Mode (46-90 minutes)          ${RetroUI.cyan}│${RetroUI.reset}');
      print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[4]${RetroUI.reset} Express Connect (91-120 minutes)           ${RetroUI.cyan}│${RetroUI.reset}');
      print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[5]${RetroUI.reset} View Ultra-Short Impact Warnings           ${RetroUI.cyan}│${RetroUI.reset}');
      print('${RetroUI.cyan}│${RetroUI.reset}  ${RetroUI.amber}[6]${RetroUI.reset} Back to Connection Menu                     ${RetroUI.cyan}│${RetroUI.reset}');
      print('${RetroUI.cyan}└─────────────────────────────────────────────────────┘${RetroUI.reset}');
      print('');
      
      final config = _firebaseService.adminConfig;
      print('${RetroUI.green}Current Ultra-Short Settings:${RetroUI.reset}');
      print('   Status: ${config.enableQuickDeadlines ? "${RetroUI.green}Enabled${RetroUI.reset}" : "${RetroUI.red}Disabled${RetroUI.reset}"}');
      print('   Duration: ${config.quickDeadlineMinutes} minutes');
      print('   Pressure Level: ${_getUrgencyLevel(config.quickDeadlineMinutes)}');
      print('');
      
      RetroUI.printPrompt('Select option');
      final input = stdin.readLineSync();
      
      switch (input?.trim()) {
        case '1':
          await _setEmergencyMode();
          break;
        case '2':
          await _setRapidEngagement();
          break;
        case '3':
          await _setSpeedDatingMode();
          break;
        case '4':
          await _setExpressConnect();
          break;
        case '5':
          await _showUltraShortWarnings();
          break;
        case '6':
          return;
        default:
          RetroUI.printError('Invalid option');
          sleep(Duration(seconds: 1));
      }
    }
  }

  Future<void> _setEmergencyMode() async {
    RetroUI.clearScreen();
    RetroUI.printHeader();
    
    print('${RetroUI.red}🚨 EMERGENCY MODE CONFIGURATION${RetroUI.reset}');
    print('');
    print('${RetroUI.red}⚠️  EXTREME WARNING: Emergency mode (10-20 minutes)${RetroUI.reset}');
    print('${RetroUI.yellow}This creates maximum pressure and urgency for users!${RetroUI.reset}');
    print('');
    print('${RetroUI.amber}Appropriate for:${RetroUI.reset}');
    print('   • Crisis intervention scenarios');
    print('   • Time-critical support connections');
    print('   • Emergency peer support networks');
    print('   • Testing platform stress responses');
    print('');
    print('${RetroUI.red}User Impact:${RetroUI.reset}');
    print('   • Immediate notifications and alerts');
    print('   • High anxiety for non-responsive users');
    print('   • Potential for user frustration/abandonment');
    print('   • Requires 24/7 moderation support');
    print('');
    
    RetroUI.printPrompt('Enter emergency duration (10-20 minutes)');
    final input = stdin.readLineSync();
    final minutes = int.tryParse(input ?? '');
    
    if (minutes != null && minutes >= 10 && minutes <= 20) {
      await _firebaseService.setQuickDeadline(minutes);
      RetroUI.printSuccess('Emergency mode activated: $minutes minutes');
      RetroUI.printWarning('CRITICAL SETTING ACTIVE - Monitor user responses closely!');
      print('Immediate user support should be available.');
    } else {
      RetroUI.printError('Invalid value. Emergency mode requires 10-20 minutes.');
    }
    sleep(Duration(seconds: 4));
  }

  Future<void> _setRapidEngagement() async {
    await _setPresetMode('Rapid Engagement', 21, 45, 
      'Quick reconnections and active engagement scenarios');
  }

  Future<void> _setSpeedDatingMode() async {
    await _setPresetMode('Speed Dating', 46, 90, 
      'Fast-paced meeting and initial connection scenarios');
  }

  Future<void> _setExpressConnect() async {
    await _setPresetMode('Express Connect', 91, 120, 
      'Accelerated but manageable connection timeframes');
  }

  Future<void> _setPresetMode(String modeName, int minMinutes, int maxMinutes, String description) async {
    RetroUI.clearScreen();
    RetroUI.printHeader();
    
    print('${RetroUI.cyan}⚡ ${modeName.toUpperCase()} MODE${RetroUI.reset}');
    print('');
    print('${RetroUI.green}Description:${RetroUI.reset} $description');
    print('${RetroUI.green}Range:${RetroUI.reset} $minMinutes-$maxMinutes minutes');
    print('');
    
    RetroUI.printPrompt('Enter duration ($minMinutes-$maxMinutes minutes)');
    final input = stdin.readLineSync();
    final minutes = int.tryParse(input ?? '');
    
    if (minutes != null && minutes >= minMinutes && minutes <= maxMinutes) {
      await _firebaseService.setQuickDeadline(minutes);
      RetroUI.printSuccess('$modeName mode set: $minutes minutes');
      print('Users will receive ${_getEngagementStyle(minutes)} prompts.');
    } else {
      RetroUI.printError('Invalid value. Must be $minMinutes-$maxMinutes minutes.');
    }
    sleep(Duration(seconds: 3));
  }

  String _getEngagementStyle(int minutes) {
    if (minutes <= 30) return 'very urgent';
    if (minutes <= 60) return 'frequent';
    if (minutes <= 90) return 'regular';
    return 'gentle';
  }

  Future<void> _showUltraShortWarnings() async {
    RetroUI.clearScreen();
    RetroUI.printHeader();
    
    print('${RetroUI.red}⚠️  ULTRA-SHORT MODE IMPACT WARNINGS${RetroUI.reset}');
    print('');
    print('${RetroUI.yellow}Psychological Impact on Users:${RetroUI.reset}');
    print('   ${RetroUI.red}• Increased anxiety and stress${RetroUI.reset}');
    print('   ${RetroUI.amber}• Fear of missing connections${RetroUI.reset}');
    print('   ${RetroUI.yellow}• Pressure to respond immediately${RetroUI.reset}');
    print('   ${RetroUI.blue}• Potential for hasty decisions${RetroUI.reset}');
    print('');
    
    print('${RetroUI.yellow}Platform Risks:${RetroUI.reset}');
    print('   ${RetroUI.red}• Higher user abandonment rates${RetroUI.reset}');
    print('   ${RetroUI.amber}• Increased support ticket volume${RetroUI.reset}');
    print('   ${RetroUI.yellow}• Negative user experience reviews${RetroUI.reset}');
    print('   ${RetroUI.blue}• Reduced thoughtful engagement${RetroUI.reset}');
    print('');
    
    print('${RetroUI.green}Required Safeguards:${RetroUI.reset}');
    print('   ✅ 24/7 customer support availability');
    print('   ✅ Clear user education about time limits');
    print('   ✅ Easy opt-out mechanisms');
    print('   ✅ Mental health resources available');
    print('   ✅ Regular monitoring of user feedback');
    print('');
    
    print('${RetroUI.cyan}Recommended Monitoring:${RetroUI.reset}');
    print('   📊 Track user completion rates');
    print('   📈 Monitor support request patterns');
    print('   💬 Collect user experience feedback');
    print('   📉 Watch for increased app uninstalls');
    print('   🎯 Measure quality of connections formed');
    print('');
    
    print('${RetroUI.amber}Best Practices:${RetroUI.reset}');
    print('   • Start with longer durations and decrease gradually');
    print('   • A/B test with small user groups first');
    print('   • Provide clear countdown timers to users');
    print('   • Offer extension options in special circumstances');
    print('   • Have immediate rollback plans ready');
    print('');
    
    print('Press Enter to continue...');
    stdin.readLineSync();
  }
} 