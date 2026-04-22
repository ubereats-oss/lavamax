import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavamax/data/models/branch_model.dart';
import 'package:lavamax/data/repositories/branch_repository.dart';
import 'package:lavamax/data/services/firebase_service.dart';
final branchRepositoryProvider = Provider((ref) {
  return BranchRepository(FirebaseService().firestore);
});
/// StreamProvider — escuta o Firestore em tempo real.
/// Qualquer alteração no console (ex: adicionar allowed_brand)
/// é refletida imediatamente no app sem reinstalar.
final branchesProvider = StreamProvider<List<BranchModel>>((ref) {
  final repository = ref.watch(branchRepositoryProvider);
  return repository.watchAllBranches();
});
final selectedBranchProvider = StateProvider<BranchModel?>((ref) => null);
