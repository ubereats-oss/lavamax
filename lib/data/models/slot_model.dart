import 'package:cloud_firestore/cloud_firestore.dart';
class SlotModel {
  final String id;
  final String branchId;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable;
  final String? appointmentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  SlotModel({
    required this.id,
    required this.branchId,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    this.appointmentId,
    required this.createdAt,
    required this.updatedAt,
  });
  factory SlotModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SlotModel(
      id: doc.id,
      branchId: data['branch_id'] ?? '',
      startTime: (data['start_time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['end_time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAvailable: data['is_available'] ?? true,
      appointmentId: data['appointment_id'],
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  Map<String, dynamic> toFirestore() {
    return {
      'branch_id': branchId,
      'start_time': startTime,
      'end_time': endTime,
      'is_available': isAvailable,
      'appointment_id': appointmentId,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
  SlotModel copyWith({
    String? id,
    String? branchId,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAvailable,
    String? appointmentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SlotModel(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAvailable: isAvailable ?? this.isAvailable,
      appointmentId: appointmentId ?? this.appointmentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
