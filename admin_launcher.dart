import 'package:firebase_core/firebase_core.dart';
import 'lib/Database_logic/firebase_options.dart';
import 'lib/admin/admin_terminal.dart';

void main() async {
  // Initialize Firebase for the main app first
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Start the admin terminal
  final terminal = AdminTerminal();
  await terminal.start();
}
