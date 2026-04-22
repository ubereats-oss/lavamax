import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lavamax/data/models/appointment_model.dart';
import 'package:lavamax/data/models/credit_model.dart';
class AppointmentRepository {
  final FirebaseFirestore _firestore;
  AppointmentRepository(this._firestore);
  /// Cria o agendamento, reserva o slot e — opcionalmente — marca o crédito
  /// como usado, tudo numa única transação atômica.
  ///
  /// [useCreditId] deve ser o ID do documento em `credits` a ser consumido.
  /// Se null ou vazio, nenhum crédito é alterado.
  Future<void> createAppointmentAndReserveSlot(
    AppointmentModel appointment, {
    String? useCreditId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final slotRef =
          _firestore.collection('slots').doc(appointment.slotId);
      final slotDoc = await transaction.get(slotRef);
      if (!slotDoc.exists) {
        throw Exception('Horario nao encontrado.');
      }
      final slotData = slotDoc.data() as Map<String, dynamic>;
      if (!(slotData['is_available'] as bool? ?? false)) {
        throw Exception(
            'Este horario acabou de ser reservado por outro cliente. '
            'Por favor, escolha outro.');
      }
      // Consome o crédito dentro da transação (atomicamente)
      if (useCreditId != null && useCreditId.isNotEmpty) {
        final creditRef =
            _firestore.collection('credits').doc(useCreditId);
        final creditDoc = await transaction.get(creditRef);
        if (creditDoc.exists &&
            creditDoc.data()?['status'] ==
                'active') {
          transaction.update(creditRef, {
            'status': 'used',
            'used_at': FieldValue.serverTimestamp(),
          });
        }
      }
      final appointmentRef =
          _firestore.collection('appointments').doc(appointment.id);
      transaction.set(appointmentRef, appointment.toFirestore());
      transaction.update(slotRef, {
        'is_available': false,
        'appointment_id': appointment.id,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }
  Future<List<AppointmentModel>> getAppointmentsByCustomer(
      String customerId) async {
    try {
      final snapshot = await _firestore
          .collection('appointments')
          .where('customer_id', isEqualTo: customerId)
          .get();
      final list = snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
      list.sort(
          (a, b) => b.appointmentDate.compareTo(a.appointmentDate));
      return list;
    } catch (e) {
      throw Exception('Erro ao buscar agendamentos: $e');
    }
  }
  /// Busca todos os agendamentos (admin). Limitado a 200 por carga.
  Future<List<AppointmentModel>> getAllAppointments({
    int limit = 200,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('appointments')
          .orderBy('appointment_date', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar agendamentos: $e');
    }
  }
  Future<AppointmentModel?> getAppointmentById(
      String appointmentId) async {
    try {
      final doc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();
      if (doc.exists) return AppointmentModel.fromFirestore(doc);
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar agendamento: $e');
    }
  }
  Future<void> updateAppointmentStatus(
      String appointmentId, String status) async {
    try {
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update({
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erro ao atualizar agendamento: $e');
    }
  }
  /// Cancela o agendamento, libera o slot e gera crédito para o cliente.
  /// O crédito é criado após a transação (limitação do SDK: queries de
  /// coleção não são permitidas dentro de transações Firestore). O erro
  /// é propagado normalmente — sem catch silencioso.
  Future<void> cancelAppointment(
    AppointmentModel appointment,
    String customerName,
  ) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final appointmentRef = _firestore
            .collection('appointments')
            .doc(appointment.id);
        final appointmentDoc =
            await transaction.get(appointmentRef);
        if (!appointmentDoc.exists) {
          throw Exception('Agendamento nao encontrado.');
        }
        transaction.update(appointmentRef, {
          'status': 'canceled',
          'updated_at': FieldValue.serverTimestamp(),
        });
        final slotId = appointment.slotId;
        if (slotId.isNotEmpty) {
          final slotRef =
              _firestore.collection('slots').doc(slotId);
          transaction.update(slotRef, {
            'is_available': true,
            'appointment_id': null,
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      });
      // Cria o crédito após a transação — erro é propagado (sem catch silencioso)
      final credit = CreditModel(
        id: '',
        customerId: appointment.customerId,
        customerName: customerName,
        branchId: appointment.branchId,
        branchName: appointment.branchName,
        originAppointmentId: appointment.id,
        serviceName: appointment.serviceName,
        status: 'active',
        createdAt: DateTime.now(),
      );
      await _firestore.collection('credits').add(credit.toFirestore());
    } catch (e) {
      throw Exception('Erro ao cancelar agendamento: $e');
    }
  }
  /// Remove o documento permanentemente e libera o slot se necessário.
  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final appointmentRef = _firestore
            .collection('appointments')
            .doc(appointmentId);
        final appointmentDoc =
            await transaction.get(appointmentRef);
        if (!appointmentDoc.exists) {
          throw Exception('Agendamento nao encontrado.');
        }
        final data = appointmentDoc.data()!;
        final status = data['status'] as String? ?? '';
        final slotId = data['slot_id'] as String?;
        if (status != 'canceled' &&
            slotId != null &&
            slotId.isNotEmpty) {
          final slotRef =
              _firestore.collection('slots').doc(slotId);
          transaction.update(slotRef, {
            'is_available': true,
            'appointment_id': null,
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
        transaction.delete(appointmentRef);
      });
    } catch (e) {
      throw Exception('Erro ao excluir agendamento: $e');
    }
  }
  /// Cancela agendamentos ativos (liberando slots) e exclui todos os
  /// agendamentos do cliente. Usado ao excluir um usuário.
  /// Não gera crédito — a exclusão é uma ação administrativa.
  Future<int> cancelAndDeleteAllByCustomer(String customerId) async {
    try {
      final snap = await _firestore
          .collection('appointments')
          .where('customer_id', isEqualTo: customerId)
          .get();
      if (snap.docs.isEmpty) return 0;
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? '';
        final slotId = data['slot_id'] as String? ?? '';
        if (status != 'canceled' &&
            status != 'completed' &&
            slotId.isNotEmpty) {
          final slotRef =
              _firestore.collection('slots').doc(slotId);
          batch.update(slotRef, {
            'is_available': true,
            'appointment_id': null,
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
        batch.delete(doc.reference);
      }
      await batch.commit();
      return snap.docs.length;
    } catch (e) {
      throw Exception('Erro ao excluir agendamentos do usuario: $e');
    }
  }
}
