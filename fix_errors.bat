@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "PROJECT_ROOT=%cd%"
set "LIB_PATH=%PROJECT_ROOT%\lib"

echo.
echo ========================================
echo  LAVAMAX - Corrigindo Todos os Erros
echo ========================================
echo.

REM ===== 1. CORRIGIR app_theme.dart (CardTheme para CardThemeData) =====
echo Corrigindo app_theme.dart...
powershell -Command "(Get-Content '%LIB_PATH%\core\theme\app_theme.dart') -replace 'cardTheme: CardTheme\(', 'cardTheme: CardThemeData(' | Set-Content '%LIB_PATH%\core\theme\app_theme.dart'"
echo ✓ app_theme.dart corrigido

REM ===== 2. REMOVER imports não utilizados =====
echo Removendo imports não utilizados...
powershell -Command "(Get-Content '%LIB_PATH%\presentation\screens\branch_selection_screen.dart') -replace \"import 'package:lavamax/core/constants/app_colors.dart';\`n\", '' | Set-Content '%LIB_PATH%\presentation\screens\branch_selection_screen.dart'"
powershell -Command "(Get-Content '%LIB_PATH%\presentation\screens\service_selection_screen.dart') -replace \"import 'package:lavamax/core/constants/app_colors.dart';\`n\", '' | Set-Content '%LIB_PATH%\presentation\screens\service_selection_screen.dart'"
powershell -Command "(Get-Content '%LIB_PATH%\presentation\screens\slot_selection_screen.dart') -replace \"import 'package:lavamax/core/constants/app_colors.dart';\`n\", '' | Set-Content '%LIB_PATH%\presentation\screens\slot_selection_screen.dart'"
powershell -Command "(Get-Content '%LIB_PATH%\presentation\widgets\custom_app_bar.dart') -replace \"import 'package:lavamax/core/constants/app_dimensions.dart';\`n\", '' | Set-Content '%LIB_PATH%\presentation\widgets\custom_app_bar.dart'"
echo ✓ Imports não utilizados removidos

REM ===== 3. REMOVER referências a assets do pubspec.yaml =====
echo Removendo referências a assets inexistentes...
powershell -Command "(Get-Content '%PROJECT_ROOT%\pubspec.yaml') -replace '  assets:\`n    - assets/images/\`n    - assets/icons/', '' | Set-Content '%PROJECT_ROOT%\pubspec.yaml'"
echo ✓ Assets removidos do pubspec.yaml

REM ===== 4. CRIAR my_appointments_screen.dart =====
echo Criando my_appointments_screen.dart...
(
echo import 'package:flutter/material.dart';
echo import 'package:flutter_riverpod/flutter_riverpod.dart';
echo import 'package:lavamax/core/constants/app_strings.dart';
echo import 'package:lavamax/presentation/widgets/custom_app_bar.dart';
echo.
echo class MyAppointmentsScreen extends ConsumerWidget {
echo   const MyAppointmentsScreen({super.key});
echo.
echo   @override
echo   Widget build(BuildContext context, WidgetRef ref) {
echo     return Scaffold(
echo       appBar: CustomAppBar(
echo         title: AppStrings.myAppointments,
echo         showBackButton: true,
echo       ),
echo       body: const Center(
echo         child: Text('Meus Agendamentos'),
echo       ),
echo     );
echo   }
echo }
) > "%LIB_PATH%\presentation\screens\my_appointments_screen.dart"
echo ✓ my_appointments_screen.dart criado

REM ===== 5. CORRIGIR appointment_confirmation_screen.dart =====
echo Corrigindo appointment_confirmation_screen.dart...
(
echo import 'package:flutter/material.dart';
echo import 'package:flutter_riverpod/flutter_riverpod.dart';
echo import 'package:intl/intl.dart';
echo import 'package:uuid/uuid.dart';
echo import 'package:lavamax/core/constants/app_colors.dart';
echo import 'package:lavamax/core/constants/app_dimensions.dart';
echo import 'package:lavamax/core/constants/app_strings.dart';
echo import 'package:lavamax/data/models/appointment_model.dart';
echo import 'package:lavamax/presentation/providers/appointment_provider.dart';
echo import 'package:lavamax/presentation/providers/branch_provider.dart';
echo import 'package:lavamax/presentation/providers/service_provider.dart';
echo import 'package:lavamax/presentation/providers/slot_provider.dart';
echo import 'package:lavamax/presentation/widgets/custom_app_bar.dart';
echo.
echo class AppointmentConfirmationScreen extends ConsumerStatefulWidget {
echo   const AppointmentConfirmationScreen({super.key});
echo.
echo   @override
echo   ConsumerState^<AppointmentConfirmationScreen^> createState() =^>
echo       _AppointmentConfirmationScreenState();
echo }
echo.
echo class _AppointmentConfirmationScreenState
echo     extends ConsumerState^<AppointmentConfirmationScreen^> {
echo   bool _isLoading = false;
echo.
echo   @override
echo   Widget build(BuildContext context) {
echo     final selectedBranch = ref.watch(selectedBranchProvider);
echo     final selectedService = ref.watch(selectedServiceProvider);
echo     final selectedSlot = ref.watch(selectedSlotProvider);
echo.
echo     if (selectedBranch == null ^|^| selectedService == null ^|^| selectedSlot == null) {
echo       return Scaffold(
echo         appBar: CustomAppBar(title: AppStrings.appointmentDetails),
echo         body: const Center(child: Text('Erro: Dados incompletos')),
echo       );
echo     }
echo.
echo     final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
echo     final appointmentDateTime = dateFormat.format(selectedSlot.startTime);
echo.
echo     return Scaffold(
echo       appBar: CustomAppBar(
echo         title: AppStrings.appointmentDetails,
echo         showBackButton: true,
echo       ),
echo       body: SingleChildScrollView(
echo         child: Padding(
echo           padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
echo           child: Column(
echo             crossAxisAlignment: CrossAxisAlignment.stretch,
echo             children: [
echo               const SizedBox(height: AppDimensions.paddingLarge),
echo               Card(
echo                 child: Padding(
echo                   padding: const EdgeInsets.all(AppDimensions.paddingMedium),
echo                   child: Column(
echo                     crossAxisAlignment: CrossAxisAlignment.start,
echo                     children: [
echo                       Text(
echo                         'Resumo do Agendamento',
echo                         style: Theme.of(context).textTheme.titleMedium?.copyWith(
echo                           fontWeight: FontWeight.bold,
echo                         ),
echo                       ),
echo                       const SizedBox(height: AppDimensions.paddingMedium),
echo                       _buildDetailRow(context, 'Filial', selectedBranch.name),
echo                       const SizedBox(height: AppDimensions.paddingSmall),
echo                       _buildDetailRow(context, 'Serviço', selectedService.name),
echo                       const SizedBox(height: AppDimensions.paddingSmall),
echo                       _buildDetailRow(context, 'Data e Hora', appointmentDateTime),
echo                       const SizedBox(height: AppDimensions.paddingSmall),
echo                       _buildDetailRow(
echo                         context,
echo                         'Duração',
echo                         '${selectedService.durationMinutes} minutos',
echo                       ),
echo                       const SizedBox(height: AppDimensions.paddingSmall),
echo                       _buildDetailRow(
echo                         context,
echo                         'Preço',
echo                         'R\$ ${selectedService.price.toStringAsFixed(2)}',
echo                       ),
echo                     ],
echo                   ),
echo                 ),
echo               ),
echo               const SizedBox(height: AppDimensions.paddingLarge),
echo               ElevatedButton(
echo                 onPressed: _isLoading ? null : _confirmAppointment,
echo                 child: _isLoading
echo                     ? const SizedBox(
echo                         height: 20,
echo                         width: 20,
echo                         child: CircularProgressIndicator(
echo                           strokeWidth: 2,
echo                           valueColor: AlwaysStoppedAnimation^<Color^>(
echo                             AppColors.white,
echo                           ),
echo                         ),
echo                       )
echo                     : const Text(AppStrings.confirmAppointment),
echo               ),
echo               const SizedBox(height: AppDimensions.paddingMedium),
echo               OutlinedButton(
echo                 onPressed: _isLoading ? null : () =^> Navigator.of(context).pop(),
echo                 child: const Text(AppStrings.cancel),
echo               ),
echo             ],
echo           ),
echo         ),
echo       ),
echo     );
echo   }
echo.
echo   Widget _buildDetailRow(BuildContext context, String label, String value) {
echo     return Row(
echo       mainAxisAlignment: MainAxisAlignment.spaceBetween,
echo       children: [
echo         Text(
echo           label,
echo           style: Theme.of(context).textTheme.bodyMedium?.copyWith(
echo             color: AppColors.grey600,
echo           ),
echo         ),
echo         Text(
echo           value,
echo           style: Theme.of(context).textTheme.bodyMedium?.copyWith(
echo             fontWeight: FontWeight.bold,
echo           ),
echo         ),
echo       ],
echo     );
echo   }
echo.
echo   Future^<void^> _confirmAppointment() async {
echo     setState(() =^> _isLoading = true);
echo.
echo     try {
echo       final selectedBranch = ref.read(selectedBranchProvider);
echo       final selectedService = ref.read(selectedServiceProvider);
echo       final selectedSlot = ref.read(selectedSlotProvider);
echo.
echo       if (selectedBranch == null ^|^| selectedService == null ^|^| selectedSlot == null) {
echo         throw Exception('Dados incompletos');
echo       }
echo.
echo       const customerId = 'temp_customer_id';
echo.
echo       final appointment = AppointmentModel(
echo         id: const Uuid().v4(),
echo         customerId: customerId,
echo         branchId: selectedBranch.id,
echo         serviceId: selectedService.id,
echo         slotId: selectedSlot.id,
echo         appointmentDate: selectedSlot.startTime,
echo         status: 'pending',
echo         createdAt: DateTime.now(),
echo         updatedAt: DateTime.now(),
echo       );
echo.
echo       final appointmentRepository = ref.read(appointmentRepositoryProvider);
echo       await appointmentRepository.createAppointment(appointment);
echo.
echo       if (mounted) {
echo         ScaffoldMessenger.of(context).showSnackBar(
echo           const SnackBar(content: Text(AppStrings.appointmentConfirmed)),
echo         );
echo         Navigator.of(context).popUntil((route) =^> route.isFirst);
echo       }
echo     } catch (e) {
echo       if (mounted) {
echo         ScaffoldMessenger.of(context).showSnackBar(
echo           SnackBar(content: Text('Erro: $e')),
echo         );
echo       }
echo     } finally {
echo       if (mounted) {
echo         setState(() =^> _isLoading = false);
echo       }
echo     }
echo   }
echo }
) > "%LIB_PATH%\presentation\screens\appointment_confirmation_screen.dart"
echo ✓ appointment_confirmation_screen.dart corrigido

REM ===== 6. CORRIGIR super.key em todos os arquivos =====
echo Corrigindo super.key em todos os arquivos...
powershell -Command "Get-ChildItem -Path '%LIB_PATH%' -Filter '*.dart' -Recurse | ForEach-Object { (Get-Content $_.FullName) -replace 'Key\? key\) : super\(key: key\)', 'super.key' | Set-Content $_.FullName }"
echo ✓ super.key corrigido

echo.
echo ========================================
echo  ✓✓✓ TODOS OS ERROS CORRIGIDOS
echo ========================================
echo.
echo Próximos passos:
echo   1. flutter pub get
echo   2. flutterfire configure
echo   3. flutter analyze
echo.
pause