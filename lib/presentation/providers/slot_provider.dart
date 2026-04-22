import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavamax/data/models/slot_model.dart';
import 'package:lavamax/data/repositories/slot_repository.dart';
import 'package:lavamax/data/services/firebase_service.dart';
final slotRepositoryProvider = Provider((ref) {
  return SlotRepository(FirebaseService().firestore);
});
final selectedDateProvider = StateProvider<DateTime?>((ref) => null);
final availableSlotsProvider = FutureProvider.family<List<SlotModel>, (String, DateTime)>((ref, params) async {
  final repository = ref.watch(slotRepositoryProvider);
  final (branchId, date) = params;
  return repository.getAvailableSlotsByBranch(branchId, date);
});
final selectedSlotProvider = StateProvider<SlotModel?>((ref) => null);
