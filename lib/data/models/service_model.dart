import 'package:cloud_firestore/cloud_firestore.dart';
class ServiceModel {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final double price;
  final int durationMinutes;
  final String category;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl = '',
    required this.price,
    required this.durationMinutes,
    required this.category,
    required this.isActive,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });
  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      iconUrl: data['icon_url'] as String? ?? '',
      price: (data['price'] as num? ?? 0.0).toDouble(),
      durationMinutes: data['duration_minutes'] as int? ?? 30,
      category: data['category'] as String? ?? '',
      isActive: data['is_active'] as bool? ?? true,
      sortOrder: data['sort_order'] as int? ?? 0,
      createdAt:
          (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'icon_url': iconUrl,
      'price': price,
      'duration_minutes': durationMinutes,
      'category': category,
      'is_active': isActive,
      'sort_order': sortOrder,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
  ServiceModel copyWith({
    String? id,
    String? name,
    String? description,
    String? iconUrl,
    double? price,
    int? durationMinutes,
    String? category,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
