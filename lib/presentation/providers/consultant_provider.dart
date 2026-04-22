import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/consultant_model.dart';
import '../../data/repositories/consultant_repository.dart';
import '../../data/services/firebase_service.dart';
final consultantRepositoryProvider = Provider<ConsultantRepository>(
  (_) => ConsultantRepository(FirebaseService().firestore),
);
/// Lista de consultores ativos de uma filial (stream em tempo real).
final branchConsultantsProvider =
    StreamProvider.family<List<ConsultantModel>, String>((ref, branchId) {
  return ref.watch(consultantRepositoryProvider).watchByBranch(branchId);
});
/// Consultor selecionado para o agendamento em andamento.
final selectedConsultantProvider =
    StateProvider<ConsultantModel?>((ref) => null);
/// Indica se o consultor selecionado tem conflito de horário.
final consultantHasConflictProvider = StateProvider<bool>((ref) => false);
