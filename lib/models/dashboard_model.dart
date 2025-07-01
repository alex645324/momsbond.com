import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardModel {
  final bool isLoading;
  final String? errorMessage;
  final String currentUserId;
  final String username;
  final List<ConnectionData> connections;
  final List<InvitationData> invitations;
  final Map<String, bool> userAvailability;
  final List<MatchData> availableMatches;
  final bool isMatching;
  final String matchingStatus;

  const DashboardModel({
    this.isLoading = true,
    this.errorMessage,
    this.currentUserId = '',
    this.username = 'User',
    this.connections = const [],
    this.invitations = const [],
    this.userAvailability = const {},
    this.availableMatches = const [],
    this.isMatching = false,
    this.matchingStatus = '',
  });

  DashboardModel copyWith({
    bool? isLoading,
    String? errorMessage,
    String? currentUserId,
    String? username,
    List<ConnectionData>? connections,
    List<InvitationData>? invitations,
    Map<String, bool>? userAvailability,
    List<MatchData>? availableMatches,
    bool? isMatching,
    String? matchingStatus,
  }) {
    return DashboardModel(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      currentUserId: currentUserId ?? this.currentUserId,
      username: username ?? this.username,
      connections: connections ?? this.connections,
      invitations: invitations ?? this.invitations,
      userAvailability: userAvailability ?? this.userAvailability,
      availableMatches: availableMatches ?? this.availableMatches,
      isMatching: isMatching ?? this.isMatching,
      matchingStatus: matchingStatus ?? this.matchingStatus,
    );
  }

  bool get hasError => errorMessage != null;
  bool get hasConnections => connections.isNotEmpty;
  int get activeConnectionsCount => connections.where((c) => c.isActive).length;
  
  // Colors for the circular connections display
  static const List<Color> connectionColors = [
    Color(0xFFEFD4E2), // Pink
    Color(0xFFEDE4C6), // Cream
    Color(0xFFD8DAC5), // Sage
    Color(0xFFDFE0E2), // Light grey
    Color(0xFFD9D9D9), // Grey
  ];
}

class ConnectionData {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final bool isAvailable;
  final int inactiveDays;
  final bool isActive;
  final String conversationId;
  final Map<String, dynamic> matchData;
  final Color displayColor;
  final int connectionStrength;
  final DateTime lastInteraction;
  final int totalConversations;
  final bool isInWarningState;
  final double visualOpacity;

  const ConnectionData({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.isAvailable = false,
    this.inactiveDays = 0,
    this.isActive = true,
    required this.conversationId,
    this.matchData = const {},
    this.displayColor = const Color(0xFFD9D9D9),
    this.connectionStrength = 100,
    required this.lastInteraction,
    this.totalConversations = 1,
    this.isInWarningState = false,
    this.visualOpacity = 1.0,
  });

  ConnectionData copyWith({
    String? id,
    String? otherUserId,
    String? otherUserName,
    bool? isAvailable,
    int? inactiveDays,
    bool? isActive,
    String? conversationId,
    Map<String, dynamic>? matchData,
    Color? displayColor,
    int? connectionStrength,
    DateTime? lastInteraction,
    int? totalConversations,
    bool? isInWarningState,
    double? visualOpacity,
  }) {
    return ConnectionData(
      id: id ?? this.id,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      isAvailable: isAvailable ?? this.isAvailable,
      inactiveDays: inactiveDays ?? this.inactiveDays,
      isActive: isActive ?? this.isActive,
      conversationId: conversationId ?? this.conversationId,
      matchData: matchData ?? this.matchData,
      displayColor: displayColor ?? this.displayColor,
      connectionStrength: connectionStrength ?? this.connectionStrength,
      lastInteraction: lastInteraction ?? this.lastInteraction,
      totalConversations: totalConversations ?? this.totalConversations,
      isInWarningState: isInWarningState ?? this.isInWarningState,
      visualOpacity: visualOpacity ?? this.visualOpacity,
    );
  }

  static ConnectionData fromFirebaseData(
    String docId,
    Map<String, dynamic> data,
    String currentUserId,
    int colorIndex,
  ) {
    final bool isUserA = data['userAId'] == currentUserId;
    final String otherUserId = isUserA ? (data['userBId'] ?? '') : (data['userAId'] ?? '');
    final String otherUserName = isUserA ? (data['userBName'] ?? 'User') : (data['userAName'] ?? 'User');
    
    DateTime now = DateTime.now();
    DateTime lastInteractionDate = now;
    
    // Safe Timestamp parsing with error handling
    try {
      if (data.containsKey('lastConversationEnd') && data['lastConversationEnd'] != null) {
        final timestamp = data['lastConversationEnd'];
        if (timestamp is Timestamp) {
          lastInteractionDate = timestamp.toDate();
        } else if (timestamp is DateTime) {
          lastInteractionDate = timestamp;
        } else {
          print("ConnectionData: Invalid lastConversationEnd type: ${timestamp.runtimeType}");
        }
      } else if (data.containsKey('matchedAt') && data['matchedAt'] != null) {
        final timestamp = data['matchedAt'];
        if (timestamp is Timestamp) {
          lastInteractionDate = timestamp.toDate();
        } else if (timestamp is DateTime) {
          lastInteractionDate = timestamp;
        } else {
          print("ConnectionData: Invalid matchedAt type: ${timestamp.runtimeType}");
        }
      }
    } catch (e) {
      print("ConnectionData: Error parsing timestamps for ${docId}: $e");
      // lastInteractionDate remains as 'now' (safe fallback)
    }
    
    int daysSinceInteraction = now.difference(lastInteractionDate).inDays;
    
    int totalConversations = data['totalConversations'] ?? 1;
    
    int baseStrength = data['connectionStrength'] ?? 100;
    int currentStrength = _calculateConnectionStrength(
      baseStrength: baseStrength,
      daysSinceInteraction: daysSinceInteraction,
      totalConversations: totalConversations,
    );
    
    bool isInWarning = currentStrength < 20;
    double opacity = _calculateVisualOpacity(currentStrength);
    
    bool isActive = currentStrength > 10;
    
    final Color displayColor = DashboardModel.connectionColors[
      colorIndex % DashboardModel.connectionColors.length
    ];

    return ConnectionData(
      id: docId,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      inactiveDays: daysSinceInteraction,
      isActive: isActive,
      conversationId: data['conversationId'] ?? '',
      matchData: data,
      displayColor: displayColor,
      connectionStrength: currentStrength,
      lastInteraction: lastInteractionDate,
      totalConversations: totalConversations,
      isInWarningState: isInWarning,
      visualOpacity: opacity,
    );
  }

  static int _calculateConnectionStrength({
    required int baseStrength,
    required int daysSinceInteraction,
    required int totalConversations,
  }) {
    // Decay logic removed: simply return the stored baseStrength without deductions
    return baseStrength.clamp(0, 100);
  }

  static double _calculateVisualOpacity(int strength) {
    // Always full opacity now that decay is removed
    return 1.0;
  }

  String get displayName => otherUserName.isNotEmpty ? otherUserName : 'User';
  String get statusText {
    if (!isActive) return 'Connection Fading';
    if (isInWarningState) return 'Needs Attention';
    if (isAvailable) return 'Available';
    return 'tap to talk again';
  }
  
  String get strengthDescription {
    if (connectionStrength >= 80) return 'Strong Connection';
    if (connectionStrength >= 60) return 'Good Connection';
    if (connectionStrength >= 40) return 'Moderate Connection';
    if (connectionStrength >= 20) return 'Weak Connection';
    return 'Connection Fading';
  }
  
  String get engagementPrompt {
    if (connectionStrength < 20) {
      return 'Reconnect now to save this connection!';
    } else if (connectionStrength < 40) {
      return 'Start a conversation to strengthen your bond';
    }
    return 'Keep the connection alive';
  }
}

class InvitationData {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final String matchId;
  final String conversationId;
  final DateTime timestamp;

  const InvitationData({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.matchId,
    required this.conversationId,
    required this.timestamp,
  });

  static InvitationData fromFirebaseData(String docId, Map<String, dynamic> data) {
    return InvitationData(
      id: docId,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'User',
      receiverId: data['receiverId'] ?? '',
      receiverName: data['receiverName'] ?? 'User',
      matchId: data['matchId'] ?? '',
      conversationId: data['conversationId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class NotificationData {
  final String type;
  final String message;
  final bool read;
  final DateTime timestamp;

  const NotificationData({
    required this.type,
    required this.message,
    this.read = false,
    required this.timestamp,
  });

  static NotificationData fromMap(Map<String, dynamic> data) {
    return NotificationData(
      type: data['type'] ?? '',
      message: data['message'] ?? '',
      read: data['read'] ?? false,
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
    );
  }
}

// Simple MatchData class for potential matches
class MatchData {
  final String userId;
  final String username;
  final String momStage;
  final DateTime lastActive;
  final bool isOnline;

  const MatchData({
    required this.userId,
    required this.username,
    required this.momStage,
    required this.lastActive,
    this.isOnline = false,
  });
} 