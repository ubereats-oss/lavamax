import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/consultant_model.dart';
class ConsultantRepository {
  final FirebaseFirestore _db;
  ConsultantRepository(this._db);
  Stream<List<ConsultantModel>> watchByBranch(String branchId) {
    return _db
        .collection('consultants')
        .where('branch_id', isEqualTo: branchId)
        .where('is_active', isEqualTo: true)
        .snapshots()
        .map((s) {
      final list = s.docs.map(ConsultantModel.fromFirestore).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }
  Future<List<ConsultantModel>> getByBranch(String branchId) async {
    final snap = await _db
        .collection('consultants')
        .where('branch_id', isEqualTo: branchId)
        .where('is_active', isEqualTo: true)
        .get();
    final list = snap.docs.map(ConsultantModel.fromFirestore).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }
  /// Verifica se o consultor já tem agendamento no mesmo slot (mesmo horário).
  Future<bool> hasConflictAtSlot(
      String consultantId, DateTime slotTime) async {
    final snap = await _db
        .collection('appointments')
        .where('consultant_id', isEqualTo: consultantId)
        .where('appointment_date',
            isEqualTo: Timestamp.fromDate(slotTime))
        .get();
    return snap.docs.isNotEmpty;
  }
  /// Retorna o consultor mais disponível no dia usando UMA única query de
  /// agendamentos por filial — elimina o padrão N+1 da versão anterior.
  ///
  /// Índice composto necessário no Firestore:
  ///   Coleção: appointments | Campos: branch_id ASC · appointment_date ASC
  Future<ConsultantModel?> getMostAvailable(
      String branchId, DateTime day) async {
    final consultants = await getByBranch(branchId);
    if (consultants.isEmpty) return null;
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    // Uma única query para todos os agendamentos do dia nesta filial
    final snap = await _db
        .collection('appointments')
        .where('branch_id', isEqualTo: branchId)
        .where('appointment_date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('appointment_date',
            isLessThan: Timestamp.fromDate(end))
        .get();
    // Conta agendamentos por consultor em Dart (zero queries extras)
    final counts = <String, int>{
      for (final c in consultants) c.id: 0,
    };
    for (final doc in snap.docs) {
      final cId = doc.data()['consultant_id'] as String?;
      if (cId != null && counts.containsKey(cId)) {
        counts[cId] = counts[cId]! + 1;
      }
    }
    ConsultantModel? best;
    int bestCount = 999;
    for (final c in consultants) {
      final count = counts[c.id] ?? 0;
      if (count < bestCount) {
        bestCount = count;
        best = c;
      }
    }
    return best;
  }
  Future<void> create(ConsultantModel consultant) async {
    await _db.collection('consultants').add(consultant.toFirestore());
  }
  Future<void> update(String id, Map<String, dynamic> data) async {
    await _db.collection('consultants').doc(id).update(data);
  }
  Future<void> delete(String id) async {
    await _db.collection('consultants').doc(id).delete();
  }
}
