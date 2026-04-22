import 'package:cloud_firestore/cloud_firestore.dart';
class ConsultantModel {
  final String id;
  final String name;
  final String phone;
  final String branchId;
  final int dailyLimit;
  final bool isActive;
  const ConsultantModel({
    required this.id,
    required this.name,
    this.phone = '',
    required this.branchId,
    required this.dailyLimit,
    required this.isActive,
  });
  factory ConsultantModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ConsultantModel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      branchId: d['branch_id'] as String? ?? '',
      dailyLimit: d['daily_limit'] as int? ?? 16,
      isActive: d['is_active'] as bool? ?? true,
    );
  }
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'branch_id': branchId,
      'daily_limit': dailyLimit,
      'is_active': isActive,
    };
  }
}
