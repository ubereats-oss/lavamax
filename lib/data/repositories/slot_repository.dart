import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lavamax/data/models/slot_model.dart';
class SlotRepository {
  final FirebaseFirestore _firestore;
  SlotRepository(this._firestore);
  Future<List<SlotModel>> getAvailableSlotsByBranch(
    String branchId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final snapshot = await _firestore
          .collection('slots')
          .where('branch_id', isEqualTo: branchId)
          .where('is_available', isEqualTo: true)
          .where('start_time', isGreaterThanOrEqualTo: startOfDay)
          .where('start_time', isLessThan: endOfDay)
          .orderBy('start_time')
          .get();
      return snapshot.docs
          .map((doc) => SlotModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar horários disponíveis: $e');
    }
  }
  /// Não usar diretamente. A reserva atômica é feita via
  /// [AppointmentRepository.createAppointmentAndReserveSlot].
  @Deprecated('Use AppointmentRepository.createAppointmentAndReserveSlot')
  Future<void> reserveSlot(String slotId, String appointmentId) async {
    try {
      await _firestore.collection('slots').doc(slotId).update({
        'is_available': false,
        'appointment_id': appointmentId,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erro ao reservar horário: $e');
    }
  }
  /// Não usar diretamente. A liberação atômica é feita via
  /// [AppointmentRepository.cancelAppointment].
  @Deprecated('Use AppointmentRepository.cancelAppointment')
  Future<void> releaseSlot(String slotId) async {
    try {
      await _firestore.collection('slots').doc(slotId).update({
        'is_available': true,
        'appointment_id': null,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erro ao liberar horário: $e');
    }
  }
}
