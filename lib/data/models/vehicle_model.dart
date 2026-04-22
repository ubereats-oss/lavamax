import 'package:cloud_firestore/cloud_firestore.dart';
class VehicleModel {
  final String id;
  final String brandId;
  final String brand; // resolvido em runtime via brandId — não salvo no Firestore
  final String model;
  final int year;
  final String plate;
  final DateTime createdAt;
  VehicleModel({
    required this.id,
    required this.brandId,
    this.brand = '',
    required this.model,
    required this.year,
    required this.plate,
    required this.createdAt,
  });
  String get displayName => '$brand $model ($year) — $plate';
  factory VehicleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VehicleModel(
      id: doc.id,
      brandId: data['brand_id'] ?? '',
      brand: '',
      model: data['model'] ?? '',
      year: data['year'] ?? 0,
      plate: data['plate'] ?? '',
      createdAt:
          (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  Map<String, dynamic> toFirestore() {
    return {
      'brand_id': brandId,
      'model': model,
      'year': year,
      'plate': plate.toUpperCase(),
      'created_at': FieldValue.serverTimestamp(),
    };
  }
  VehicleModel copyWith({
    String? id,
    String? brandId,
    String? brand,
    String? model,
    int? year,
    String? plate,
    DateTime? createdAt,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      brandId: brandId ?? this.brandId,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      plate: plate ?? this.plate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
