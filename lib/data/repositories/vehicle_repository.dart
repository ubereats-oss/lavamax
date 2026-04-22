import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lavamax/data/models/vehicle_brand_model.dart';
import 'package:lavamax/data/models/vehicle_model.dart';
class VehicleRepository {
  final FirebaseFirestore _firestore;
  VehicleRepository(this._firestore);
  Future<List<VehicleBrandModel>> getActiveBrands() async {
    try {
      final snapshot = await _firestore
          .collection('vehicle_brands')
          .orderBy('name')
          .get();
      return snapshot.docs
          .map((doc) => VehicleBrandModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar marcas');
    }
  }
  CollectionReference _vehiclesRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('vehicles');
  Future<List<VehicleModel>> getVehiclesByUser(String userId) async {
    try {
      final snapshot = await _vehiclesRef(userId)
          .orderBy('created_at', descending: false)
          .get();
      return snapshot.docs
          .map((doc) => VehicleModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar veiculos');
    }
  }
  Future<VehicleModel> addVehicle(String userId, VehicleModel vehicle) async {
    try {
      final ref = _vehiclesRef(userId).doc();
      await ref.set(vehicle.toFirestore());
      final doc = await ref.get();
      return VehicleModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Erro ao adicionar veiculo');
    }
  }
  Future<void> deleteVehicle(String userId, String vehicleId) async {
    try {
      await _vehiclesRef(userId).doc(vehicleId).delete();
    } catch (e) {
      throw Exception('Erro ao remover veiculo');
    }
  }
}
