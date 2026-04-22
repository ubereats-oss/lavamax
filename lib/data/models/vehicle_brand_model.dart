import 'package:cloud_firestore/cloud_firestore.dart';
class VehicleBrandModel {
  final String id;
  final String name;
  final List<String> models;
  final bool isActive;
  VehicleBrandModel({
    required this.id,
    required this.name,
    required this.models,
    required this.isActive,
  });
  factory VehicleBrandModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VehicleBrandModel(
      id: doc.id,
      name: data['name'] ?? '',
      models: List<String>.from(data['models'] ?? []),
      isActive: data['is_active'] ?? true,
    );
  }
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'models': models,
      'is_active': isActive,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}
