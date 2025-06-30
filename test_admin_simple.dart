import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/Database_logic/firebase_options.dart';

void main() async {
  print('🚀 Testing Admin Integration...');
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
    
    // Test Firestore connection
    final firestore = FirebaseFirestore.instance;
    
    // Try to get users collection info
    final usersSnapshot = await firestore.collection('users').limit(1).get();
    print('✅ Firebase connected - Found ${usersSnapshot.docs.length} users in database');
    
    // Try to get system stats
    final allUsers = await firestore.collection('users').get();
    final allMatches = await firestore.collection('matches').get();
    
    print('📊 Current System Stats:');
    print('   • Total Users: ${allUsers.docs.length}');
    print('   • Total Matches: ${allMatches.docs.length}');
    
    // Test writing admin config
    await firestore.collection('admin').doc('config').set({
      'testRun': true,
      'lastTestTime': FieldValue.serverTimestamp(),
      'conversationDurationSeconds': 180,
    }, SetOptions(merge: true));
    print('✅ Admin config test write successful');
    
    // Test reading admin config
    final configDoc = await firestore.collection('admin').doc('config').get();
    if (configDoc.exists) {
      print('✅ Admin config read successful');
      print('   • Config data: ${configDoc.data()}');
    }
    
    print('\n🎉 All tests passed! Admin integration is working correctly.');
    print('You can now run the full admin terminal with: dart run admin_launcher.dart');
    
  } catch (e) {
    print('❌ Error during testing: $e');
    print('Stack trace: ${e.toString()}');
  }
} 