import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// Service that manages admin configuration and applies live settings
class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Current admin configuration
  static Map<String, dynamic> _adminConfig = {
    'conversationDuration': 30, // seconds
    'connectionDecayDays': 7,
    'warningThresholdHours': 24,
    'quickExpirationMode': false,
    'quickExpirationMinutes': 30,
  };
  
  // Stream subscription for live updates
  static StreamSubscription<DocumentSnapshot>? _configSubscription;
  
  // Stream controllers for broadcasting config changes
  static final StreamController<Map<String, dynamic>> _configController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  /// Initialize admin service and start listening for configuration changes
  static Future<void> initialize() async {
    try {
      // Load initial configuration
      await _loadAdminConfig();
      
      // Start listening for real-time updates
      _startConfigListener();
      
      print('AdminService: Initialized successfully');
    } catch (e) {
      print('AdminService: Error during initialization: $e');
    }
  }
  
  /// Load admin configuration from Firebase
  static Future<void> _loadAdminConfig() async {
    try {
      final configDoc = await _firestore.collection('admin').doc('config').get();
      
      if (configDoc.exists) {
        final data = configDoc.data();
        if (data != null) {
          _adminConfig = Map<String, dynamic>.from(data);
          print('AdminService: Configuration loaded from Firebase');
        }
      } else {
        // Create default configuration
        await _firestore.collection('admin').doc('config').set(_adminConfig);
        print('AdminService: Created default admin configuration');
      }
    } catch (e) {
      print('AdminService: Error loading configuration: $e');
    }
  }
  
  /// Start listening for real-time configuration changes
  static void _startConfigListener() {
    _configSubscription = _firestore
        .collection('admin')
        .doc('config')
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null) {
            _adminConfig = Map<String, dynamic>.from(data);
            _configController.add(_adminConfig);
            print('AdminService: Configuration updated in real-time');
          }
        }
      },
      onError: (error) {
        print('AdminService: Error listening to configuration changes: $error');
      },
    );
  }
  
  /// Get current conversation duration in seconds
  static int getConversationDuration() {
    return _adminConfig['conversationDuration'] as int? ?? 30;
  }
  
  /// Get connection decay period in days
  static int getConnectionDecayDays() {
    return _adminConfig['connectionDecayDays'] as int? ?? 7;
  }
  
  /// Get warning threshold in hours
  static int getWarningThresholdHours() {
    return _adminConfig['warningThresholdHours'] as int? ?? 24;
  }
  
  /// Check if quick expiration mode is enabled
  static bool isQuickExpirationMode() {
    return _adminConfig['quickExpirationMode'] as bool? ?? false;
  }
  
  /// Get quick expiration time in minutes
  static int getQuickExpirationMinutes() {
    return _adminConfig['quickExpirationMinutes'] as int? ?? 30;
  }
  
  /// Get the effective decay period (considers quick expiration mode)
  static Duration getEffectiveDecayPeriod() {
    if (isQuickExpirationMode()) {
      return Duration(minutes: getQuickExpirationMinutes());
    } else {
      return Duration(days: getConnectionDecayDays());
    }
  }
  
  /// Stream of configuration changes
  static Stream<Map<String, dynamic>> get configStream => _configController.stream;
  
  /// Update user status and last active timestamp
  static Future<void> updateUserStatus(String userId, String status) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': status,
        'lastActive': FieldValue.serverTimestamp(),
      });
      
      print('AdminService: Updated user $userId status to $status');
    } catch (e) {
      print('AdminService: Error updating user status: $e');
    }
  }
  
  /// Calculate connection strength based on admin settings
  static int calculateConnectionStrength(DateTime lastContact) {
    final now = DateTime.now();
    final timeSinceContact = now.difference(lastContact);
    final effectiveDecayPeriod = getEffectiveDecayPeriod();
    
    if (timeSinceContact >= effectiveDecayPeriod) {
      return 0; // Expired
    }
    
    // Calculate percentage remaining (100% at creation, 0% at expiration)
    final decayProgress = timeSinceContact.inMilliseconds / effectiveDecayPeriod.inMilliseconds;
    final strength = (100 * (1 - decayProgress)).round();
    
    return strength.clamp(0, 100);
  }
  
  /// Check if a connection needs a warning
  static bool needsConnectionWarning(DateTime lastContact) {
    final now = DateTime.now();
    final timeSinceContact = now.difference(lastContact);
    final warningThreshold = Duration(hours: getWarningThresholdHours());
    
    return timeSinceContact >= warningThreshold;
  }
  
  /// Create or update a connection with decay tracking
  static Future<void> createConnection({
    required String userAId,
    required String userBId,
    required String userAName,
    required String userBName,
  }) async {
    try {
      final connectionData = {
        'userA': userAId,
        'userB': userBId,
        'userAName': userAName,
        'userBName': userBName,
        'createdAt': FieldValue.serverTimestamp(),
        'lastContact': FieldValue.serverTimestamp(),
        'status': 'active',
        'strength': 100,
      };
      
      await _firestore.collection('matches').add(connectionData);
      print('AdminService: Created new connection between $userAName and $userBName');
    } catch (e) {
      print('AdminService: Error creating connection: $e');
    }
  }
  
  /// Update connection strength and last contact time
  static Future<void> updateConnectionContact(String connectionId) async {
    try {
      final strength = 100; // Reset to full strength on contact
      
      await _firestore.collection('matches').doc(connectionId).update({
        'lastContact': FieldValue.serverTimestamp(),
        'strength': strength,
        'status': 'active',
      });
      
      print('AdminService: Updated connection $connectionId contact time');
    } catch (e) {
      print('AdminService: Error updating connection contact: $e');
    }
  }
  
  /// Get all connections for a user with current strength
  static Future<List<Map<String, dynamic>>> getUserConnections(String userId) async {
    try {
      final connections = await _firestore
          .collection('matches')
          .where('userA', isEqualTo: userId)
          .get();
      
      final connections2 = await _firestore
          .collection('matches')
          .where('userB', isEqualTo: userId)
          .get();
      
      final allConnections = [...connections.docs, ...connections2.docs];
      
      return allConnections.map((doc) {
        final data = doc.data();
        final lastContact = (data['lastContact'] as Timestamp?)?.toDate() ?? 
                           (data['createdAt'] as Timestamp?)?.toDate() ?? 
                           DateTime.now();
        
        final currentStrength = calculateConnectionStrength(lastContact);
        final needsWarning = needsConnectionWarning(lastContact);
        
        return {
          'id': doc.id,
          'userA': data['userA'],
          'userB': data['userB'],
          'userAName': data['userAName'] ?? 'Unknown',
          'userBName': data['userBName'] ?? 'Unknown',
          'lastContact': lastContact,
          'strength': currentStrength,
          'needsWarning': needsWarning,
          'status': currentStrength > 0 ? 'active' : 'expired',
          ...data,
        };
      }).toList();
    } catch (e) {
      print('AdminService: Error getting user connections: $e');
      return [];
    }
  }
  
  /// Monitor and update connection strengths (background task)
  static Future<void> updateAllConnectionStrengths() async {
    try {
      final connectionsSnapshot = await _firestore.collection('matches').get();
      
      for (final doc in connectionsSnapshot.docs) {
        final data = doc.data();
        final lastContact = (data['lastContact'] as Timestamp?)?.toDate() ?? 
                           (data['createdAt'] as Timestamp?)?.toDate() ?? 
                           DateTime.now();
        
        final currentStrength = calculateConnectionStrength(lastContact);
        final status = currentStrength > 0 ? 'active' : 'expired';
        
        // Update if strength has changed
        if ((data['strength'] as int? ?? 100) != currentStrength) {
          await _firestore.collection('matches').doc(doc.id).update({
            'strength': currentStrength,
            'status': status,
          });
        }
      }
      
      print('AdminService: Updated all connection strengths');
    } catch (e) {
      print('AdminService: Error updating connection strengths: $e');
    }
  }
  
  /// Start a timer for conversation management
  static Timer startConversationTimer({
    required String matchId,
    required VoidCallback onTimeUp,
  }) {
    final duration = Duration(seconds: getConversationDuration());
    
    print('AdminService: Starting conversation timer for ${duration.inSeconds} seconds');
    
    return Timer(duration, () {
      print('AdminService: Conversation time up for match $matchId');
      onTimeUp();
    });
  }
  
  /// Get configuration as a formatted string for display
  static String getConfigSummary() {
    return '''
Conversation Duration: ${getConversationDuration()}s
Connection Decay: ${getConnectionDecayDays()} days
Warning Threshold: ${getWarningThresholdHours()} hours
Quick Expiration: ${isQuickExpirationMode() ? 'ON (${getQuickExpirationMinutes()}m)' : 'OFF'}
''';
  }
  
  /// Dispose of resources
  static void dispose() {
    _configSubscription?.cancel();
    _configController.close();
  }
} 