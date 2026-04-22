import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavamax/data/models/vehicle_brand_model.dart';
import 'package:lavamax/data/models/vehicle_model.dart';
import 'package:lavamax/data/repositories/vehicle_repository.dart';
import 'package:lavamax/data/services/firebase_service.dart';
final vehicleRepositoryProvider = Provider((ref) {
  return VehicleRepository(FirebaseService().firestore);
});
final vehicleBrandsProvider = FutureProvider<List<VehicleBrandModel>>((ref) async {
  final repo = ref.watch(vehicleRepositoryProvider);
  return repo.getActiveBrands();
});
final userVehiclesProvider = FutureProvider<List<VehicleModel>>((ref) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return [];
  final repo = ref.watch(vehicleRepositoryProvider);
  final vehicles = await repo.getVehiclesByUser(uid);
  final brands = await repo.getActiveBrands();
  final brandMap = {for (final b in brands) b.id: b.name};
  return vehicles
      .map((v) => v.copyWith(brand: brandMap[v.brandId] ?? ''))
      .toList();
});
final selectedVehicleProvider = StateProvider<VehicleModel?>((ref) => null);
