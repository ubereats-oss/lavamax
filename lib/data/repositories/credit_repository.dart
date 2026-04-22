import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lavamax/data/models/credit_model.dart';
class CreditRepository {
  final FirebaseFirestore _db;
  CreditRepository(this._db);
  static const int _defaultMaxCredits = 2;
  /// Retorna o limite máximo de créditos ativos por cliente,
  /// conforme configurado pelo admin em config/credits.
  Future<int> getMaxCredits() async {
    try {
      final doc =
          await _db.collection('config').doc('credits').get();
      if (doc.exists) {
        return (doc.data()?['max_credits_per_customer'] as int?) ??
            _defaultMaxCredits;
      }
    } catch (_) {}
    return _defaultMaxCredits;
  }
  Future<void> setMaxCredits(int value) async {
    await _db
        .collection('config')
        .doc('credits')
        .set({'max_credits_per_customer': value}, SetOptions(merge: true));
  }
  /// Verifica se o cliente já atingiu o limite de créditos ativos.
  /// Usado para bloquear o cancelamento antes de executá-lo.
  Future<bool> hasReachedLimit(String customerId) async {
    final maxCredits = await getMaxCredits();
    final activeSnap = await _db
        .collection('credits')
        .where('customer_id', isEqualTo: customerId)
        .where('status', isEqualTo: 'active')
        .get();
    return activeSnap.docs.length >= maxCredits;
  }
  /// Retorna créditos ativos do cliente numa filial específica.
  Future<List<CreditModel>> getActiveCredits(
      String customerId, String branchId) async {
    final snap = await _db
        .collection('credits')
        .where('customer_id', isEqualTo: customerId)
        .where('branch_id', isEqualTo: branchId)
        .where('status', isEqualTo: 'active')
        .get();
    return snap.docs.map(CreditModel.fromFirestore).toList();
  }
  /// Retorna todos os créditos do cliente (qualquer status).
  Future<List<CreditModel>> getCreditsForCustomer(
      String customerId) async {
    final snap = await _db
        .collection('credits')
        .where('customer_id', isEqualTo: customerId)
        .get();
    final list = snap.docs.map(CreditModel.fromFirestore).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
  /// Retorna todos os créditos (admin).
  Future<List<CreditModel>> getAllCredits() async {
    final snap = await _db.collection('credits').get();
    final list = snap.docs.map(CreditModel.fromFirestore).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
  /// Cria um crédito. Verifica o limite antes de criar.
  /// Lança exceção se o limite já foi atingido.
  Future<void> createCredit(CreditModel credit) async {
    final maxCredits = await getMaxCredits();
    final activeSnap = await _db
        .collection('credits')
        .where('customer_id', isEqualTo: credit.customerId)
        .where('status', isEqualTo: 'active')
        .get();
    if (activeSnap.docs.length >= maxCredits) {
      throw Exception(
          'Limite de creditos atingido para este cliente.');
    }
    await _db.collection('credits').add(credit.toFirestore());
  }
  /// Marca o primeiro crédito ativo do cliente na filial como 'used'.
  /// Retorna o id do crédito usado, ou null se não havia crédito.
  Future<String?> useCredit(
      String customerId, String branchId) async {
    final actives = await getActiveCredits(customerId, branchId);
    if (actives.isEmpty) return null;
    final credit = actives.first;
    await _db.collection('credits').doc(credit.id).update({
      'status': 'used',
      'used_at': FieldValue.serverTimestamp(),
    });
    return credit.id;
  }
  /// Cancela um crédito manualmente (admin).
  Future<void> cancelCredit(String creditId) async {
    await _db.collection('credits').doc(creditId).update({
      'status': 'canceled',
    });
  }
  /// Reativa um crédito cancelado (admin).
  Future<void> reactivateCredit(String creditId) async {
    await _db.collection('credits').doc(creditId).update({
      'status': 'active',
      'used_at': null,
    });
  }
}
