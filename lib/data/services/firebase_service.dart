import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lavamax/firebase_options.dart';
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() {
    return _instance;
  }
  FirebaseService._internal();
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Enable offline persistence
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true, // Para o usuário poder acessar "Meus agendamentos" sem internet
    );
  }
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
}
