import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lavamax/data/models/branch_model.dart';
class BranchRepository {
  final FirebaseFirestore _firestore;
  BranchRepository(this._firestore);
  /// Stream em tempo real — qualquer alteração no Firestore
  /// é refletida imediatamente no app, sem reinstalar.
  Stream<List<BranchModel>> watchAllBranches() {
    return _firestore
        .collection('branches')
        .where('is_active', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => BranchModel.fromFirestore(doc))
            .toList());
  }
  Future<List<BranchModel>> getAllBranches() async {
    try {
      final snapshot = await _firestore
          .collection('branches')
          .where('is_active', isEqualTo: true)
          .get();
      return snapshot.docs
          .map((doc) => BranchModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar filiais: $e');
    }
  }
  Future<BranchModel?> getBranchById(String branchId) async {
    try {
      final doc =
          await _firestore.collection('branches').doc(branchId).get();
      if (doc.exists) {
        return BranchModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar filial: $e');
    }
  }
  Future<void> createBranch(BranchModel branch) async {
    try {
      await _firestore
          .collection('branches')
          .doc(branch.id)
          .set(branch.toFirestore());
    } catch (e) {
      throw Exception('Erro ao criar filial: $e');
    }
  }
  Future<void> updateBranch(BranchModel branch) async {
    try {
      await _firestore
          .collection('branches')
          .doc(branch.id)
          .update(branch.toFirestore());
    } catch (e) {
      throw Exception('Erro ao atualizar filial: $e');
    }
  }
}
