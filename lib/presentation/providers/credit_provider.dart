import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/credit_repository.dart';
import '../../data/services/firebase_service.dart';
final creditRepositoryProvider = Provider<CreditRepository>(
  (_) => CreditRepository(FirebaseService().firestore),
);
