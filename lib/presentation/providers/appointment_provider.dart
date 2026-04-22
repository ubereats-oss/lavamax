import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavamax/data/models/appointment_model.dart';
import 'package:lavamax/data/repositories/appointment_repository.dart';
import 'package:lavamax/data/services/firebase_service.dart';
final appointmentRepositoryProvider = Provider((ref) {
  return AppointmentRepository(FirebaseService().firestore);
});
final customerAppointmentsProvider = FutureProvider.family<List<AppointmentModel>, String>((ref, customerId) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.getAppointmentsByCustomer(customerId);
});
