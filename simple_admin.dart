import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'lib/Database_logic/firebase_options.dart';

// Enhanced Admin Terminal with Live Firebase Integration
class AdminTerminal {
  late FirebaseFirestore _firestore;
  Timer? _refreshTimer;
  
  // Admin configuration settings
  Map<String, dynamic> _adminConfig = {
    'conversationDuration': 30, // seconds
    'connectionDecayDays': 7,
    'warningThresholdHours': 24,
    'quickExpirationMode': false,
    'quickExpirationMinutes': 30,
  };
  
  // Real-time data
  Map<String, dynamic> _systemStats = {
    'totalUsers': 0,
    'activeUsers': 0,
    'usersInConversation': 0,
    'usersWaiting': 0,
    'activeConnections': 0,
    'activityPercentage': 0.0,
  };
  
  List<Map<String, dynamic>> _userDetails = [];
  List<Map<String, dynamic>> _connections = [];

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _firestore = FirebaseFirestore.instance;
      await _loadAdminConfig();
      await _refreshData();
      _startAutoRefresh();
      _printSuccess('Firebase connected successfully!');
    } catch (e) {
      _printError('Firebase initialization failed: $e');
    }
  }

  Future<void> _loadAdminConfig() async {
    try {
      final doc = await _firestore.collection('admin').doc('config').get();
      if (doc.exists) {
        _adminConfig = Map<String, dynamic>.from(doc.data()!);
      } else {
        // Create default config
        await _firestore.collection('admin').doc('config').set(_adminConfig);
      }
    } catch (e) {
      _printWarning('Using default admin config: $e');
    }
  }

  Future<void> _saveAdminConfig() async {
    try {
      await _firestore.collection('admin').doc('config').set(_adminConfig);
      _printSuccess('Admin configuration saved!');
    } catch (e) {
      _printError('Failed to save config: $e');
    }
  }

  Future<void> _refreshData() async {
    await _loadSystemStats();
    await _loadUserDetails();
    await _loadConnections();
  }

  Future<void> _loadSystemStats() async {
    try {
      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();
      final totalUsers = usersSnapshot.docs.length;
      
      // Calculate active users (last 30 seconds)
      final now = DateTime.now();
      final activeThreshold = now.subtract(Duration(seconds: 30));
      
      int activeUsers = 0;
      int usersInConversation = 0;
      int usersWaiting = 0;
      
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final lastActive = (data['lastActive'] as Timestamp?)?.toDate();
        final status = data['status'] as String? ?? 'offline';
        
        if (lastActive != null && lastActive.isAfter(activeThreshold)) {
          activeUsers++;
        }
        
        if (status == 'in_conversation') {
          usersInConversation++;
        } else if (status == 'waiting') {
          usersWaiting++;
        }
      }
      
      // Get active connections
      final connectionsSnapshot = await _firestore.collection('matches').get();
      final activeConnections = connectionsSnapshot.docs.where((doc) {
        final data = doc.data();
        final status = data['status'] as String? ?? 'inactive';
        return status == 'active';
      }).length;
      
      // Calculate activity percentage
      final activityPercentage = totalUsers > 0 ? (activeUsers / totalUsers) * 100 : 0.0;
      
      _systemStats = {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'usersInConversation': usersInConversation,
        'usersWaiting': usersWaiting,
        'activeConnections': activeConnections,
        'activityPercentage': activityPercentage,
      };
    } catch (e) {
      _printError('Failed to load system stats: $e');
    }
  }

  Future<void> _loadUserDetails() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      _userDetails = usersSnapshot.docs.map((doc) {
        final data = doc.data();
        final lastActive = (data['lastActive'] as Timestamp?)?.toDate();
        
        return {
          'id': doc.id,
          'username': data['username'] ?? 'Unknown',
          'status': data['status'] ?? 'offline',
          'lastActive': lastActive ?? DateTime.now(),
          'momStage': data['momStage'] ?? 'unknown',
        };
      }).toList();
      
      // Sort by last active (most recent first)
      _userDetails.sort((a, b) => (b['lastActive'] as DateTime).compareTo(a['lastActive'] as DateTime));
    } catch (e) {
      _printError('Failed to load user details: $e');
    }
  }

  Future<void> _loadConnections() async {
    try {
      final connectionsSnapshot = await _firestore.collection('matches').get();
      _connections = connectionsSnapshot.docs.map((doc) {
        final data = doc.data();
        final lastContact = (data['lastContact'] as Timestamp?)?.toDate();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        
        // Calculate connection strength based on decay
        final strength = _calculateConnectionStrength(lastContact ?? createdAt ?? DateTime.now());
        
        return {
          'id': doc.id,
          'userA': data['userA'] ?? 'Unknown',
          'userB': data['userB'] ?? 'Unknown',
          'strength': strength,
          'lastContact': lastContact ?? createdAt ?? DateTime.now(),
          'status': data['status'] ?? 'inactive',
        };
      }).toList();
      
      // Sort by strength (strongest first)
      _connections.sort((a, b) => (b['strength'] as int).compareTo(a['strength'] as int));
    } catch (e) {
      _printError('Failed to load connections: $e');
    }
  }

  int _calculateConnectionStrength(DateTime lastContact) {
    final now = DateTime.now();
    final daysSinceContact = now.difference(lastContact).inDays;
    final maxDecayDays = _adminConfig['connectionDecayDays'] as int;
    
    if (daysSinceContact >= maxDecayDays) {
      return 0;
    }
    
    // Linear decay from 100% to 0%
    final strength = 100 - ((daysSinceContact / maxDecayDays) * 100);
    return math.max(0, strength.round());
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      await _refreshData();
    });
  }

  void _clearScreen() {
    print('\x1B[2J\x1B[0;0H');
  }

  void _printHeader() {
    _clearScreen();
    print('\x1B[32m\x1B[1m'); // Green + Bold
    print('╔══════════════════════════════════════════════════════════════════╗');
    print('║  ███╗   ███╗ ██████╗ ███╗   ███╗███████╗    █████╗ ██████╗ ███╗   ███╗██╗███╗   ██╗ ║');
    print('║  ████╗ ████║██╔═══██╗████╗ ████║██╔════╝   ██╔══██╗██╔══██╗████╗ ████║██║████╗  ██║ ║');
    print('║  ██╔████╔██║██║   ██║██╔████╔██║███████╗   ███████║██║  ██║██╔████╔██║██║██╔██╗ ██║ ║');
    print('║  ██║╚██╔╝██║██║   ██║██║╚██╔╝██║╚════██║   ██╔══██║██║  ██║██║╚██╔╝██║██║██║╚██╗██║ ║');
    print('║  ██║ ╚═╝ ██║╚██████╔╝██║ ╚═╝ ██║███████║   ██║  ██║██████╔╝██║ ╚═╝ ██║██║██║ ╚████║ ║');
    print('║  ╚═╝     ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝   ╚═╝  ╚═╝╚═════╝ ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝ ║');
    print('║\x1B[93m                     Enhanced Platform Administration Terminal v2.0                     \x1B[32m║');
    print('╚══════════════════════════════════════════════════════════════════╝\x1B[0m');
    print('');
  }

  void _printSystemStatus() {
    final stats = _systemStats;
    print('\x1B[36m┌──────────────────── LIVE SYSTEM STATUS ────────────────────┐\x1B[0m');
    print('\x1B[36m│\x1B[0m 🔌 Firebase: \x1B[32mCONNECTED\x1B[0m    📊 Database: \x1B[92mmymomsapp-59faa\x1B[0m \x1B[36m│\x1B[0m');
    print('\x1B[36m│\x1B[0m 👥 Total Users: \x1B[33m${stats['totalUsers']}\x1B[0m       ⚡ Active: \x1B[33m${stats['activeUsers']}\x1B[0m             \x1B[36m│\x1B[0m');
    print('\x1B[36m│\x1B[0m 💬 In Conversation: \x1B[33m${stats['usersInConversation']}\x1B[0m   ⏳ Waiting: \x1B[33m${stats['usersWaiting']}\x1B[0m           \x1B[36m│\x1B[0m');
    print('\x1B[36m│\x1B[0m 🔗 Active Connections: \x1B[33m${stats['activeConnections']}\x1B[0m  ⏱️ Timer: \x1B[93m${_adminConfig['conversationDuration']}s\x1B[0m     \x1B[36m│\x1B[0m');
    
    // Activity percentage bar
    final activityPercent = stats['activityPercentage'] as double;
    final barLength = 20;
    final filledLength = (activityPercent / 100 * barLength).round();
    String activityBar = '';
    
    for (int i = 0; i < barLength; i++) {
      if (i < filledLength) {
        if (activityPercent > 70) {
          activityBar += '\x1B[92m█\x1B[0m'; // Bright green
        } else if (activityPercent > 40) {
          activityBar += '\x1B[93m█\x1B[0m'; // Yellow
        } else {
          activityBar += '\x1B[91m█\x1B[0m'; // Red
        }
      } else {
        activityBar += '\x1B[2m░\x1B[0m'; // Dim
      }
    }
    
    print('\x1B[36m│\x1B[0m 📈 Activity: $activityBar \x1B[33m${activityPercent.toStringAsFixed(1)}%\x1B[0m       \x1B[36m│\x1B[0m');
    print('\x1B[36m└────────────────────────────────────────────────────────────┘\x1B[0m');
    print('');
  }

  void _printMainMenu() {
    print('\x1B[32m\x1B[1m┌─────────────────── ADMIN MENU ────────────────────┐\x1B[0m');
    print('\x1B[32m│\x1B[0m  \x1B[93m[1]\x1B[0m 💬 Conversation Time Management               \x1B[32m│\x1B[0m');
    print('\x1B[32m│\x1B[0m  \x1B[93m[2]\x1B[0m 👥 Active User Monitoring                     \x1B[32m│\x1B[0m');
    print('\x1B[32m│\x1B[0m  \x1B[93m[3]\x1B[0m 🔗 Connection Streak Management               \x1B[32m│\x1B[0m');
    print('\x1B[32m│\x1B[0m  \x1B[93m[4]\x1B[0m 🔄 Refresh All Data                           \x1B[32m│\x1B[0m');
    print('\x1B[32m│\x1B[0m  \x1B[93m[5]\x1B[0m 🚪 Exit Terminal                              \x1B[32m│\x1B[0m');
    print('\x1B[32m└────────────────────────────────────────────────────┘\x1B[0m');
    print('');
  }

  Future<void> _showConversationTimeManagement() async {
    _printHeader();
    print('\x1B[36m💬 CONVERSATION TIME MANAGEMENT\x1B[0m');
    print('');
    print('Current setting: \x1B[93m${_adminConfig['conversationDuration']} seconds\x1B[0m');
    print('');
    print('\x1B[32m┌─────────────── PRESET OPTIONS ───────────────┐\x1B[0m');
    print('\x1B[32m│\x1B[0m  \x1B[93m[1]\x1B[0m ⚡ 15 seconds (Quick test)              \x1B[32m│\x1B[0m');
    print('\x1B[32m│\x1B[0m  \x1B[93m[2]\x1B[0m 🎯 30 seconds (Default)                \x1B[32m│\x1B[0m');
    print('\x1B[32m│\x1B[0m  \x1B[93m[3]\x1B[0m ⏰ 60 seconds (1 minute)               \x1B[32m│\x1B[0m');
    print('\x1B[32m│\x1B[0m  \x1B[93m[4]\x1B[0m 🕐 300 seconds (5 minutes)             \x1B[32m│\x1B[0m');
    print('\x1B[32m│\x1B[0m  \x1B[93m[5]\x1B[0m 🕙 600 seconds (10 minutes)            \x1B[32m│\x1B[0m');
    print('\x1B[32m│\x1B[0m  \x1B[93m[6]\x1B[0m ✏️  Custom duration (10-3600 seconds)  \x1B[32m│\x1B[0m');
    print('\x1B[32m│\x1B[0m  \x1B[93m[7]\x1B[0m ⬅️  Back to main menu                  \x1B[32m│\x1B[0m');
    print('\x1B[32m└───────────────────────────────────────────────┘\x1B[0m');
    print('');
    _printPrompt('Select option');

    final input = stdin.readLineSync();
    
    switch (input?.trim()) {
      case '1':
        await _updateConversationDuration(15);
        break;
      case '2':
        await _updateConversationDuration(30);
        break;
      case '3':
        await _updateConversationDuration(60);
        break;
      case '4':
        await _updateConversationDuration(300);
        break;
      case '5':
        await _updateConversationDuration(600);
        break;
      case '6':
        await _customConversationDuration();
        break;
      case '7':
        return;
      default:
        _printError('Invalid option');
        await Future.delayed(Duration(seconds: 1));
        await _showConversationTimeManagement();
    }
  }

  Future<void> _updateConversationDuration(int seconds) async {
    _adminConfig['conversationDuration'] = seconds;
    await _saveAdminConfig();
    _printSuccess('Conversation duration updated to $seconds seconds');
    print('This will apply to all new conversations started after now.');
    print('');
    print('Press Enter to continue...');
    stdin.readLineSync();
  }

  Future<void> _customConversationDuration() async {
    print('');
    _printPrompt('Enter custom duration (10-3600 seconds)');
    final input = stdin.readLineSync();
    
    try {
      final seconds = int.parse(input ?? '');
      if (seconds >= 10 && seconds <= 3600) {
        await _updateConversationDuration(seconds);
      } else {
        _printError('Duration must be between 10 and 3600 seconds');
        await Future.delayed(Duration(seconds: 2));
        await _customConversationDuration();
      }
    } catch (e) {
      _printError('Invalid number format');
      await Future.delayed(Duration(seconds: 2));
      await _customConversationDuration();
    }
  }

  Future<void> _showActiveUserMonitoring() async {
    _printHeader();
    _printSystemStatus();
    
    print('\x1B[36m👥 ACTIVE USER MONITORING\x1B[0m');
    print('');
    
    if (_userDetails.isEmpty) {
      print('No users found in database.');
      print('');
      print('Press Enter to continue...');
      stdin.readLineSync();
      return;
    }
    
    print('\x1B[32m┌─── USERNAME ───────┬─── STATUS ──────┬─── LAST ACTIVE ──┬─ MOM STAGE ──┐\x1B[0m');
    
    final now = DateTime.now();
    for (int i = 0; i < math.min(_userDetails.length, 15); i++) {
      final user = _userDetails[i];
      final username = (user['username'] as String).padRight(15);
      final status = user['status'] as String;
      final lastActive = user['lastActive'] as DateTime;
      final momStage = (user['momStage'] as String).padRight(12);
      
      // Format last active time
      final timeDiff = now.difference(lastActive);
      String timeStr;
      if (timeDiff.inSeconds < 60) {
        timeStr = '${timeDiff.inSeconds}s ago'.padLeft(15);
      } else if (timeDiff.inMinutes < 60) {
        timeStr = '${timeDiff.inMinutes}m ago'.padLeft(15);
      } else if (timeDiff.inHours < 24) {
        timeStr = '${timeDiff.inHours}h ago'.padLeft(15);
      } else {
        timeStr = '${timeDiff.inDays}d ago'.padLeft(15);
      }
      
      // Color-coded status
      String statusDisplay;
      switch (status) {
        case 'online':
          statusDisplay = '\x1B[92m●\x1B[0m ${status.padRight(14)}';
          break;
        case 'in_conversation':
          statusDisplay = '\x1B[93m●\x1B[0m ${status.padRight(14)}';
          break;
        case 'waiting':
          statusDisplay = '\x1B[94m●\x1B[0m ${status.padRight(14)}';
          break;
        default:
          statusDisplay = '\x1B[91m●\x1B[0m ${status.padRight(14)}';
      }
      
      print('\x1B[32m│\x1B[0m $username \x1B[32m│\x1B[0m $statusDisplay \x1B[32m│\x1B[0m $timeStr \x1B[32m│\x1B[0m $momStage \x1B[32m│\x1B[0m');
    }
    
    print('\x1B[32m└────────────────────┴─────────────────┴──────────────────┴──────────────┘\x1B[0m');
    
    if (_userDetails.length > 15) {
      print('');
      print('Showing first 15 users. Total: ${_userDetails.length}');
    }
    
    print('');
    print('\x1B[93m[R]\x1B[0m Refresh data  \x1B[93m[B]\x1B[0m Back to menu');
    _printPrompt('Select option');
    
    final input = stdin.readLineSync();
    switch (input?.toLowerCase().trim()) {
      case 'r':
        await _refreshData();
        await _showActiveUserMonitoring();
        break;
      case 'b':
        return;
      default:
        await _showActiveUserMonitoring();
    }
  }

  Future<void> _showConnectionStreakManagement() async {
    _printHeader();
    
    print('\x1B[36m🔗 CONNECTION STREAK MANAGEMENT\x1B[0m');
    print('');
    print('Configuration: \x1B[93m${_adminConfig['connectionDecayDays']} days decay\x1B[0m, \x1B[93m${_adminConfig['warningThresholdHours']}h warning\x1B[0m');
    print('');
    
    if (_connections.isEmpty) {
      print('No connections found in database.');
      print('');
      print('Press Enter to continue...');
      stdin.readLineSync();
      return;
    }
    
    print('\x1B[32m┌─── CONNECTION ─────────────┬─── STRENGTH ──┬─── STATUS ───┬─ LAST CONTACT ─┐\x1B[0m');
    
    final now = DateTime.now();
    for (int i = 0; i < math.min(_connections.length, 10); i++) {
      final conn = _connections[i];
      final userA = conn['userA'] as String;
      final userB = conn['userB'] as String;
      final strength = conn['strength'] as int;
      final lastContact = conn['lastContact'] as DateTime;
      final status = conn['status'] as String;
      
      final connectionName = '${userA.substring(0, math.min(6, userA.length))}↔${userB.substring(0, math.min(6, userB.length))}';
      final connectionDisplay = connectionName.padRight(25);
      
      // Visual strength bar
      final barLength = 10;
      final filledLength = (strength / 100 * barLength).round();
      String strengthBar = '';
      
      for (int j = 0; j < barLength; j++) {
        if (j < filledLength) {
          if (strength > 70) {
            strengthBar += '\x1B[92m█\x1B[0m';
          } else if (strength > 40) {
            strengthBar += '\x1B[93m█\x1B[0m';
          } else {
            strengthBar += '\x1B[91m█\x1B[0m';
          }
        } else {
          strengthBar += '\x1B[2m░\x1B[0m';
        }
      }
      
      final strengthDisplay = '$strengthBar \x1B[33m${strength}%\x1B[0m';
      
      // Status with color
      String statusDisplay;
      switch (status) {
        case 'active':
          statusDisplay = '\x1B[92m${status.padRight(11)}\x1B[0m';
          break;
        case 'inactive':
          statusDisplay = '\x1B[91m${status.padRight(11)}\x1B[0m';
          break;
        default:
          statusDisplay = '\x1B[93m${status.padRight(11)}\x1B[0m';
      }
      
      // Time since last contact
      final timeDiff = now.difference(lastContact);
      String timeStr;
      if (timeDiff.inHours < 24) {
        timeStr = '${timeDiff.inHours}h ago'.padLeft(14);
      } else {
        timeStr = '${timeDiff.inDays}d ago'.padLeft(14);
      }
      
      print('\x1B[32m│\x1B[0m $connectionDisplay \x1B[32m│\x1B[0m $strengthDisplay \x1B[32m│\x1B[0m $statusDisplay \x1B[32m│\x1B[0m $timeStr \x1B[32m│\x1B[0m');
    }
    
    print('\x1B[32m└────────────────────────────┴───────────────┴──────────────┴────────────────┘\x1B[0m');
    
    if (_connections.length > 10) {
      print('');
      print('Showing first 10 connections. Total: ${_connections.length}');
    }
    
    print('');
    print('\x1B[32m┌──────────── MANAGEMENT OPTIONS ────────────┐\x1B[0m');
    print('\x1B[32m│\x1B[0m  \x1B[93m[1]\x1B[0m 🔧 Update decay settings                \x1B[32m│\x1B[0m');
    print('\x1B[32m│\x1B[0m  \x1B[93m[2]\x1B[0m 📊 View decay algorithm demo            \x1B[32m│\x1B[0m');
    print('\x1B[32m│\x1B[0m  \x1B[93m[3]\x1B[0m ⚡ Quick expiration mode                \x1B[32m│\x1B[0m');
    print('\x1B[32m│\x1B[0m  \x1B[93m[4]\x1B[0m 🔄 Refresh connections                  \x1B[32m│\x1B[0m');
    print('\x1B[32m│\x1B[0m  \x1B[93m[5]\x1B[0m ⬅️  Back to main menu                   \x1B[32m│\x1B[0m');
    print('\x1B[32m└─────────────────────────────────────────────┘\x1B[0m');
    print('');
    _printPrompt('Select option');
    
    final input = stdin.readLineSync();
    switch (input?.trim()) {
      case '1':
        await _updateDecaySettings();
        break;
      case '2':
        await _showDecayAlgorithmDemo();
        break;
      case '3':
        await _quickExpirationMode();
        break;
      case '4':
        await _refreshData();
        await _showConnectionStreakManagement();
        break;
      case '5':
        return;
      default:
        await _showConnectionStreakManagement();
    }
  }

  Future<void> _updateDecaySettings() async {
    print('');
    print('\x1B[36mCURRENT SETTINGS:\x1B[0m');
    print('• Decay period: \x1B[93m${_adminConfig['connectionDecayDays']} days\x1B[0m');
    print('• Warning threshold: \x1B[93m${_adminConfig['warningThresholdHours']} hours\x1B[0m');
    print('');
    
    _printPrompt('Enter new decay period (1-30 days)');
    final daysInput = stdin.readLineSync();
    
    try {
      final days = int.parse(daysInput ?? '');
      if (days >= 1 && days <= 30) {
        _adminConfig['connectionDecayDays'] = days;
        
        _printPrompt('Enter warning threshold (1-168 hours)');
        final hoursInput = stdin.readLineSync();
        
        final hours = int.parse(hoursInput ?? '');
        if (hours >= 1 && hours <= 168) {
          _adminConfig['warningThresholdHours'] = hours;
          await _saveAdminConfig();
          
          _printSuccess('Decay settings updated!');
          print('• New decay period: $days days');
          print('• New warning threshold: $hours hours');
          print('');
          print('Press Enter to continue...');
          stdin.readLineSync();
        } else {
          _printError('Hours must be between 1 and 168');
          await Future.delayed(Duration(seconds: 2));
        }
      } else {
        _printError('Days must be between 1 and 30');
        await Future.delayed(Duration(seconds: 2));
      }
    } catch (e) {
      _printError('Invalid number format');
      await Future.delayed(Duration(seconds: 2));
    }
  }

  Future<void> _showDecayAlgorithmDemo() async {
    _printHeader();
    print('\x1B[36m📊 CONNECTION DECAY ALGORITHM DEMONSTRATION\x1B[0m');
    print('');
    print('\x1B[93mFormula:\x1B[0m strength = 100 - ((daysSinceContact / maxDecayDays) × 100)');
    print('\x1B[93mSettings:\x1B[0m ${_adminConfig['connectionDecayDays']} days decay period');
    print('');
    
    print('\x1B[32m┌─── DAYS ───┬─── STRENGTH ───┬─── VISUAL ────────────┬─── STATUS ───┐\x1B[0m');
    
    final maxDays = _adminConfig['connectionDecayDays'] as int;
    for (int day = 0; day <= maxDays; day += math.max(1, maxDays ~/ 10)) {
      final strength = math.max(0, 100 - ((day / maxDays) * 100).round());
      
      // Visual bar
      final barLength = 15;
      final filledLength = (strength / 100 * barLength).round();
      String strengthBar = '';
      
      for (int i = 0; i < barLength; i++) {
        if (i < filledLength) {
          if (strength > 70) {
            strengthBar += '\x1B[92m█\x1B[0m';
          } else if (strength > 40) {
            strengthBar += '\x1B[93m█\x1B[0m';
          } else {
            strengthBar += '\x1B[91m█\x1B[0m';
          }
        } else {
          strengthBar += '\x1B[2m░\x1B[0m';
        }
      }
      
      // Status
      String status;
      if (strength > 70) {
        status = '\x1B[92mStrong\x1B[0m  ';
      } else if (strength > 40) {
        status = '\x1B[93mFair\x1B[0m    ';
      } else if (strength > 0) {
        status = '\x1B[91mWeak\x1B[0m    ';
      } else {
        status = '\x1B[90mExpired\x1B[0m';
      }
      
      final dayStr = day.toString().padLeft(6);
      final strengthStr = '${strength}%'.padLeft(9);
      
      print('\x1B[32m│\x1B[0m $dayStr \x1B[32m│\x1B[0m $strengthStr \x1B[32m│\x1B[0m $strengthBar \x1B[32m│\x1B[0m $status \x1B[32m│\x1B[0m');
    }
    
    print('\x1B[32m└────────────┴────────────────┴───────────────────────┴──────────────┘\x1B[0m');
    print('');
    print('\x1B[36mNOTES:\x1B[0m');
    print('• Connections decay linearly over time');
    print('• At 0% strength, connections are marked as expired');
    print('• Users are warned when connections drop below threshold');
    print('• Quick expiration mode can be enabled for testing');
    print('');
    print('Press Enter to continue...');
    stdin.readLineSync();
  }

  Future<void> _quickExpirationMode() async {
    print('');
    print('\x1B[93m⚠️  QUICK EXPIRATION MODE\x1B[0m');
    print('This mode rapidly expires connections for testing purposes.');
    print('');
    print('Current status: \x1B[93m${_adminConfig['quickExpirationMode'] ? 'ENABLED' : 'DISABLED'}\x1B[0m');
    
    if (_adminConfig['quickExpirationMode'] as bool) {
      print('Current setting: \x1B[93m${_adminConfig['quickExpirationMinutes']} minutes\x1B[0m');
      print('');
      print('\x1B[93m[1]\x1B[0m Disable quick expiration mode');
      print('\x1B[93m[2]\x1B[0m Change expiration time (10-120 minutes)');
      print('\x1B[93m[3]\x1B[0m Back');
    } else {
      print('');
      print('\x1B[93m[1]\x1B[0m Enable quick expiration mode');
      print('\x1B[93m[2]\x1B[0m Back');
    }
    
    print('');
    _printPrompt('Select option');
    
    final input = stdin.readLineSync();
    switch (input?.trim()) {
      case '1':
        _adminConfig['quickExpirationMode'] = !(_adminConfig['quickExpirationMode'] as bool);
        await _saveAdminConfig();
        
        if (_adminConfig['quickExpirationMode'] as bool) {
          _printSuccess('Quick expiration mode ENABLED');
          print('Connections will now expire in ${_adminConfig['quickExpirationMinutes']} minutes');
        } else {
          _printSuccess('Quick expiration mode DISABLED');
          print('Connections will use normal ${_adminConfig['connectionDecayDays']} day decay');
        }
        print('');
        print('Press Enter to continue...');
        stdin.readLineSync();
        break;
        
      case '2':
        if (_adminConfig['quickExpirationMode'] as bool) {
          _printPrompt('Enter expiration time (10-120 minutes)');
          final minutesInput = stdin.readLineSync();
          
          try {
            final minutes = int.parse(minutesInput ?? '');
            if (minutes >= 10 && minutes <= 120) {
              _adminConfig['quickExpirationMinutes'] = minutes;
              await _saveAdminConfig();
              _printSuccess('Quick expiration time updated to $minutes minutes');
              print('');
              print('Press Enter to continue...');
              stdin.readLineSync();
            } else {
              _printError('Minutes must be between 10 and 120');
              await Future.delayed(Duration(seconds: 2));
            }
          } catch (e) {
            _printError('Invalid number format');
            await Future.delayed(Duration(seconds: 2));
          }
        }
        break;
    }
  }

  void _printSuccess(String message) {
    print('\x1B[32m✅ SUCCESS:\x1B[0m $message');
  }

  void _printError(String message) {
    print('\x1B[31m❌ ERROR:\x1B[0m $message');
  }

  void _printInfo(String message) {
    print('\x1B[36mℹ️  INFO:\x1B[0m $message');
  }

  void _printWarning(String message) {
    print('\x1B[33m⚠️  WARNING:\x1B[0m $message');
  }

  void _printPrompt(String prompt) {
    stdout.write('\x1B[92m\x1B[1m» \x1B[0m$prompt: ');
  }

  Future<void> start() async {
    await initialize();
    
    bool isRunning = true;
    while (isRunning) {
      _printHeader();
      _printSystemStatus();
      _printMainMenu();
      _printPrompt('Select option');
      
      final input = stdin.readLineSync();
      
      switch (input?.trim()) {
        case '1':
          await _showConversationTimeManagement();
          break;
        case '2':
          await _showActiveUserMonitoring();
          break;
        case '3':
          await _showConnectionStreakManagement();
          break;
        case '4':
          await _refreshData();
          _printSuccess('All data refreshed!');
          await Future.delayed(Duration(seconds: 1));
          break;
        case '5':
          _printInfo('Shutting down admin terminal...');
          _refreshTimer?.cancel();
          isRunning = false;
          break;
        default:
          _printError('Invalid option. Please select 1-5.');
          await Future.delayed(Duration(seconds: 1));
      }
    }
  }
}

void main() async {
  final terminal = AdminTerminal();
  await terminal.start();
} 