import 'package:cloud_firestore/cloud_firestore.dart';
class BranchModel {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String city;
  final String state;
  final double latitude;
  final double longitude;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  /// Se preenchido, apenas veículos dessa marca podem agendar nesta filial.
  /// Valor vem do campo `allowed_brand` no Firestore (ex: "Porsche").
  /// Nulo significa sem restrição de marca.
  final String? allowedBrand;
  BranchModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.allowedBrand,
  });
  factory BranchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BranchModel(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      isActive: data['is_active'] ?? true,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      allowedBrand: data['allowed_brand'] as String?,
    );
  }
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'city': city,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
      'is_active': isActive,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      if (allowedBrand != null) 'allowed_brand': allowedBrand,
    };
  }
  BranchModel copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? city,
    String? state,
    double? latitude,
    double? longitude,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? allowedBrand,
  }) {
    return BranchModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      state: state ?? this.state,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      allowedBrand: allowedBrand ?? this.allowedBrand,
    );
  }
}
