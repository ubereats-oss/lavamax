import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavamax/data/models/service_model.dart';
import 'package:lavamax/data/repositories/service_repository.dart';
import 'package:lavamax/data/services/firebase_service.dart';
final serviceRepositoryProvider = Provider((ref) {
  return ServiceRepository(FirebaseService().firestore);
});
final servicesProvider = FutureProvider((ref) async {
  final repository = ref.watch(serviceRepositoryProvider);
  return repository.getAllServices();
});
final selectedServiceProvider = StateProvider<ServiceModel?>((ref) => null);
