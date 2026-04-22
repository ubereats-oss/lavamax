class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String identifier;
  final String identifierType; // 'username' | 'cpf' | 'phone'
  final String phone;
  final String whatsapp;
  final String address;
  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.identifier,
    required this.identifierType,
    this.phone = '',
    this.whatsapp = '',
    this.address = '',
  });
  bool get isMaster => role == 'master';
  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'user',
      identifier: map['identifier'] as String? ?? '',
      identifierType: map['identifier_type'] as String? ?? 'username',
      phone: map['phone'] as String? ?? '',
      whatsapp: map['whatsapp'] as String? ?? '',
      address: map['address'] as String? ?? '',
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'identifier': identifier,
      'identifier_type': identifierType,
      'phone': phone,
      'whatsapp': whatsapp,
      'address': address,
    };
  }
}
