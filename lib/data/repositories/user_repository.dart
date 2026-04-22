import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
class UserRepository {
  final FirebaseFirestore _db;
  UserRepository(this._db);
  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }
  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(uid, doc.data()!);
  }
  Stream<UserModel?> watchUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return UserModel.fromMap(uid, snap.data()!);
    });
  }
  Future<List<UserModel>> getAllUsers() async {
    final snap = await _db.collection('users').get();
    final list = snap.docs
        .map((d) => UserModel.fromMap(d.id, d.data()))
        .toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }
  Future<void> updateRole(String uid, String role) async {
    await _db.collection('users').doc(uid).update({'role': role});
  }
  /// Atualiza apenas o nome do usuário no Firestore.
  /// O email de autenticação (Firebase Auth) só pode ser alterado pelo próprio
  /// usuário — o admin não tem acesso via client SDK.
  Future<void> updateName(String uid, {required String name}) async {
    await _db.collection('users').doc(uid).update({'name': name});
  }
  /// Exclui apenas o documento do Firestore.
  /// A conta Firebase Auth não pode ser removida pelo admin via client SDK —
  /// ela permanece inativa até o próximo login do usuário.
  Future<void> deleteUserData(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }
}
