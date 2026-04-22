import 'package:cloud_firestore/cloud_firestore.dart';
class AppointmentModel {
  final String id;
  final String customerId;
  final String branchId;
  final String branchName;
  final String serviceId;
  final String serviceName;
  final String slotId;
  final String vehicleId;
  final String consultantId;
  final String consultantName;
  final String consultantPhone;
  final bool consultantConflict;
  final DateTime appointmentDate;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  AppointmentModel({
    required this.id,
    required this.customerId,
    required this.branchId,
    this.branchName = '',
    required this.serviceId,
    this.serviceName = '',
    required this.slotId,
    required this.vehicleId,
    required this.consultantId,
    required this.consultantName,
    this.consultantPhone = '',
    required this.consultantConflict,
    required this.appointmentDate,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppointmentModel(
      id: doc.id,
      customerId: data['customer_id'] ?? '',
      branchId: data['branch_id'] ?? '',
      branchName: data['branch_name'] ?? '',
      serviceId: data['service_id'] ?? '',
      serviceName: data['service_name'] ?? '',
      slotId: data['slot_id'] ?? '',
      vehicleId: data['vehicle_id'] ?? '',
      consultantId: data['consultant_id'] ?? '',
      consultantName: data['consultant_name'] ?? '',
      consultantPhone: data['consultant_phone'] ?? '',
      consultantConflict: data['consultant_conflict'] as bool? ?? false,
      appointmentDate:
          (data['appointment_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
      notes: data['notes'],
      createdAt:
          (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  Map<String, dynamic> toFirestore() {
    return {
      'customer_id': customerId,
      'branch_id': branchId,
      'branch_name': branchName,
      'service_id': serviceId,
      'service_name': serviceName,
      'slot_id': slotId,
      'vehicle_id': vehicleId,
      'consultant_id': consultantId,
      'consultant_name': consultantName,
      'consultant_phone': consultantPhone,
      'consultant_conflict': consultantConflict,
      'appointment_date': Timestamp.fromDate(appointmentDate),
      'status': status,
      'notes': notes,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
  AppointmentModel copyWith({
    String? id,
    String? customerId,
    String? branchId,
    String? branchName,
    String? serviceId,
    String? serviceName,
    String? slotId,
    String? vehicleId,
    String? consultantId,
    String? consultantName,
    String? consultantPhone,
    bool? consultantConflict,
    DateTime? appointmentDate,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      slotId: slotId ?? this.slotId,
      vehicleId: vehicleId ?? this.vehicleId,
      consultantId: consultantId ?? this.consultantId,
      consultantName: consultantName ?? this.consultantName,
      consultantPhone: consultantPhone ?? this.consultantPhone,
      consultantConflict: consultantConflict ?? this.consultantConflict,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
