import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/firebase_service.dart';
import 'auth_provider.dart';
final userRepositoryProvider = Provider<UserRepository>(
  (_) => UserRepository(FirebaseService().firestore),
);
// Stream do documento do usuario logado no Firestore.
final userRoleProvider = StreamProvider<UserModel?>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.read(userRepositoryProvider).watchUser(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, _) => Stream.value(null),
  );
});
