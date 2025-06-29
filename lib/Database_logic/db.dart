import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseLogic {
  // A singleton approach (Optional)
  static final FirebaseLogic _instance = FirebaseLogic._internal();
  factory FirebaseLogic() => _instance;
  FirebaseLogic._internal();

  // Get the currently signed-in user's ID
  static Future<String?> getCurrentUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid; // Returns null if no user is signed in
  }

  // Sign in anonymously (if user hasn't signed in before)
  static Future<void> signInAnonymously() async {
    UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
    print("User signed in anonymously with UID: ${userCredential.user?.uid}");
  }

  // Save the user's name in Firestore
  static Future<void> saveUserName(String name) async {
    String? userId = await getCurrentUserId();

    if (userId == null) {
      // If the user isn't signed in, sign them in first
      await signInAnonymously();
      userId = await getCurrentUserId(); // Get the new user's ID
    }

    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'username': name,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)); // Merge avoids overwriting existing data

    print("User profile updated: $userId");
  }

  // Save the user's mom stage in Firestore
  static Future<void> saveMomStage(List<String> stages) async {
    String? userId = await getCurrentUserId();
    if (userId == null) {
      print("No user logged in. Cannot save mom stage.");
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'momStage': stages,
    });

    print("Mom stage updated for user: $userId");
  }
}
