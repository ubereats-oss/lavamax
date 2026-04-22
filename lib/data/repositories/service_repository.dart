import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lavamax/data/models/service_model.dart';
class ServiceRepository {
  final FirebaseFirestore _firestore;
  ServiceRepository(this._firestore);
  Future<List<ServiceModel>> getAllServices() async {
    try {
      final snapshot = await _firestore
          .collection('services')
          .where('is_active', isEqualTo: true)
          .get();
      return snapshot.docs
          .map((doc) => ServiceModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar serviços: $e');
    }
  }
  Future<ServiceModel?> getServiceById(String serviceId) async {
    try {
      final doc = await _firestore.collection('services').doc(serviceId).get();
      if (doc.exists) {
        return ServiceModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar serviço: $e');
    }
  }
  Future<void> createService(ServiceModel service) async {
    try {
      await _firestore.collection('services').doc(service.id).set(service.toFirestore());
    } catch (e) {
      throw Exception('Erro ao criar serviço: $e');
    }
  }
}
