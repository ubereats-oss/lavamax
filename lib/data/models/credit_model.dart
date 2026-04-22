import 'package:cloud_firestore/cloud_firestore.dart';
class CreditModel {
  final String id;
  final String customerId;
  final String customerName;
  final String branchId;
  final String branchName;
  final String originAppointmentId;
  final String serviceName;
  final String status; // 'active' | 'used' | 'canceled'
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? usedAt;
  CreditModel({
    required this.id,
    required this.customerId,
    this.customerName = '',
    required this.branchId,
    required this.branchName,
    required this.originAppointmentId,
    required this.serviceName,
    required this.status,
    required this.createdAt,
    this.expiresAt,
    this.usedAt,
  });
  bool get isActive => status == 'active';
  factory CreditModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CreditModel(
      id: doc.id,
      customerId: data['customer_id'] ?? '',
      customerName: data['customer_name'] ?? '',
      branchId: data['branch_id'] ?? '',
      branchName: data['branch_name'] ?? '',
      originAppointmentId: data['origin_appointment_id'] ?? '',
      serviceName: data['service_name'] ?? '',
      status: data['status'] ?? 'active',
      createdAt:
          (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expires_at'] as Timestamp?)?.toDate(),
      usedAt: (data['used_at'] as Timestamp?)?.toDate(),
    );
  }
  Map<String, dynamic> toFirestore() {
    return {
      'customer_id': customerId,
      'customer_name': customerName,
      'branch_id': branchId,
      'branch_name': branchName,
      'origin_appointment_id': originAppointmentId,
      'service_name': serviceName,
      'status': status,
      'created_at': FieldValue.serverTimestamp(),
      'expires_at': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'used_at': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
    };
  }
  CreditModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? branchId,
    String? branchName,
    String? originAppointmentId,
    String? serviceName,
    String? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? usedAt,
  }) {
    return CreditModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      originAppointmentId: originAppointmentId ?? this.originAppointmentId,
      serviceName: serviceName ?? this.serviceName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      usedAt: usedAt ?? this.usedAt,
    );
  }
}
