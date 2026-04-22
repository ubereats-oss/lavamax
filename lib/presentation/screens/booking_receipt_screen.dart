import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lavamax/core/constants/app_colors.dart';
import 'package:lavamax/core/constants/app_dimensions.dart';
import 'package:lavamax/core/utils/formatters.dart';
import 'package:lavamax/data/models/appointment_model.dart';
import 'package:lavamax/data/models/branch_model.dart';
import 'package:lavamax/data/models/service_model.dart';
import 'package:lavamax/data/models/vehicle_model.dart';
class BookingReceiptScreen extends StatelessWidget {
  final AppointmentModel appointment;
  final BranchModel branch;
  final ServiceModel service;
  final VehicleModel vehicle;
  /// true quando o agendamento foi realizado usando um crédito.
  final bool usedCredit;
  const BookingReceiptScreen({
    super.key,
    required this.appointment,
    required this.branch,
    required this.service,
    required this.vehicle,
    this.usedCredit = false,
  });
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    final date = dateFormat.format(appointment.appointmentDate);
    final time = timeFormat.format(appointment.appointmentDate);
    final code = appointment.id.substring(0, 8).toUpperCase();
    final hasConflict = appointment.consultantConflict;
    final plateFormatted = formatPlate(vehicle.plate);
    final priceFormatted = formatBrl(service.price);
    final phoneFormatted = appointment.consultantPhone.isNotEmpty
        ? formatPhone(appointment.consultantPhone)
        : '';
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        title: const Text('Comprovante'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Compartilhar',
            onPressed: () => _share(date, time, code, hasConflict,
                plateFormatted, priceFormatted, phoneFormatted),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
        child: Column(
          children: [
            const SizedBox(height: AppDimensions.paddingLarge),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
                size: 48,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            const Text(
              'Agendamento Confirmado!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Codigo: $code',
              style: const TextStyle(
                  color: AppColors.grey600, fontSize: 13),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            // Badge de crédito utilizado
            if (usedCredit)
              Container(
                margin: const EdgeInsets.only(
                    bottom: AppDimensions.paddingMedium),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success, width: 1),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.card_giftcard,
                        color: AppColors.success, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Credito utilizado — este agendamento foi realizado sem cobrança.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Aviso de conflito
            if (hasConflict)
              Container(
                margin: const EdgeInsets.only(
                    bottom: AppDimensions.paddingMedium),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppColors.warning, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Aviso: ${appointment.consultantName} ja tem um atendimento '
                        'neste horario. Isso pode causar atraso no seu atendimento.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusLarge),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.all(AppDimensions.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionTitle('Detalhes do Servico'),
                    const Divider(),
                    _row('Filial', branch.name),
                    _row('Servico', service.name),
                    _row('Data', date),
                    _row('Horario', time),
                    _row('Duracao', '${service.durationMinutes} minutos'),
                    _row(
                      'Preco',
                      usedCredit ? 'Gratis (credito)' : priceFormatted,
                    ),
                    if (appointment.consultantName.isNotEmpty) ...[
                      const SizedBox(height: AppDimensions.paddingMedium),
                      _sectionTitle('Consultor'),
                      const Divider(),
                      _row('Nome', appointment.consultantName),
                      if (phoneFormatted.isNotEmpty)
                        _row('Telefone', phoneFormatted),
                    ],
                    const SizedBox(height: AppDimensions.paddingMedium),
                    _sectionTitle('Veiculo'),
                    const Divider(),
                    _row('Marca/Modelo',
                        '${vehicle.brand} ${vehicle.model}'),
                    _row('Ano', '${vehicle.year}'),
                    _row('Placa', plateFormatted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            ElevatedButton.icon(
              onPressed: () => _share(date, time, code, hasConflict,
                  plateFormatted, priceFormatted, phoneFormatted),
              icon: const Icon(Icons.share),
              label: const Text('Compartilhar Comprovante'),
              style: ElevatedButton.styleFrom(
                minimumSize:
                    const Size.fromHeight(AppDimensions.buttonHeight),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
              style: OutlinedButton.styleFrom(
                minimumSize:
                    const Size.fromHeight(AppDimensions.buttonHeight),
              ),
              child: const Text('Voltar ao Inicio'),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
          ],
        ),
      ),
    );
  }
  Widget _sectionTitle(String title) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: AppColors.grey800,
        ),
      ),
    );
  }
  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.paddingSmall / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.grey600)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  void _share(
    String date,
    String time,
    String code,
    bool hasConflict,
    String plate,
    String price,
    String phone,
  ) {
    final conflictWarning = hasConflict
        ? '\n⚠️ Aviso: ${appointment.consultantName} ja tem atendimento neste horario. Pode haver atraso.'
        : '';
    final creditInfo =
        usedCredit ? '\n🎁 Credito utilizado — sem cobrança.' : '';
    final consultantLine = appointment.consultantName.isNotEmpty
        ? '${appointment.consultantName}${phone.isNotEmpty ? ' ($phone)' : ''}'
        : 'N/A';
    final text = '''
*Comprovante LavaMax*
📋 Codigo: $code
🏢 Filial: ${branch.name}
🔧 Servico: ${service.name}
📅 Data: $date
⏰ Horario: $time
💰 Preco: ${usedCredit ? 'Gratis (credito)' : price}
🚗 Veiculo: ${vehicle.brand} ${vehicle.model} ($plate)
👤 Consultor: $consultantLine$creditInfo$conflictWarning
''';
    Share.share(text);
  }
}
