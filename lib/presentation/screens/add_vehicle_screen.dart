import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavamax/core/constants/app_colors.dart';
import 'package:lavamax/core/constants/app_dimensions.dart';
import 'package:lavamax/data/models/vehicle_brand_model.dart';
import 'package:lavamax/data/models/vehicle_model.dart';
import 'package:lavamax/presentation/providers/vehicle_provider.dart';
import 'package:lavamax/presentation/screens/brand_selection_screen.dart';
import 'package:lavamax/presentation/widgets/custom_app_bar.dart';
import 'package:uuid/uuid.dart';
class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key});
  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}
class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _yearController = TextEditingController();
  VehicleBrandModel? _selectedBrand;
  String? _selectedModel;
  bool _isLoading = false;
  @override
  void dispose() {
    _plateController.dispose();
    _yearController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final brandsAsync = ref.watch(vehicleBrandsProvider);
    return Scaffold(
      appBar: CustomAppBar(title: 'Adicionar Veículo', showBackButton: true),
      body: brandsAsync.when(
        data: (brands) => _buildForm(brands),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) =>
            Center(child: Text('Erro ao carregar marcas: $e')),
      ),
    );
  }
  Widget _buildForm(List<VehicleBrandModel> brands) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppDimensions.paddingMedium),
            // Campo de marca — abre tela com lista completa + índice alfabético
            FormField<VehicleBrandModel>(
              initialValue: _selectedBrand,
              validator: (v) => v == null ? 'Selecione a marca' : null,
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      final chosen =
                          await Navigator.of(context).push<VehicleBrandModel>(
                        MaterialPageRoute(
                          builder: (_) =>
                              BrandSelectionScreen(brands: brands),
                        ),
                      );
                      if (chosen != null) {
                        field.didChange(chosen);
                        setState(() {
                          _selectedBrand = chosen;
                          _selectedModel = null;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Marca',
                        prefixIcon:
                            const Icon(Icons.directions_car_outlined),
                        suffixIcon:
                            const Icon(Icons.chevron_right_outlined),
                        errorText: field.errorText,
                      ),
                      child: Text(
                        _selectedBrand?.name ?? 'Toque para selecionar',
                        style: TextStyle(
                          color: _selectedBrand != null
                              ? null
                              : Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Modelo',
                prefixIcon: Icon(Icons.car_repair),
              ),
              initialValue: _selectedModel,
              items: (_selectedBrand?.models ?? [])
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: _selectedBrand == null
                  ? null
                  : (value) => setState(() => _selectedModel = value),
              validator: (v) => v == null ? 'Selecione o modelo' : null,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            TextFormField(
              controller: _yearController,
              decoration: const InputDecoration(
                labelText: 'Ano',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              validator: (v) {
                final year = int.tryParse(v ?? '');
                if (year == null) return 'Digite o ano';
                if (year < 1950 || year > DateTime.now().year + 1) {
                  return 'Ano inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            TextFormField(
              controller: _plateController,
              decoration: const InputDecoration(
                labelText: 'Placa',
                prefixIcon: Icon(Icons.pin_outlined),
                hintText: 'Ex: ABC1234 ou ABC1D23',
              ),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                _PlateFormatter(),
              ],
              validator: (v) {
                final clean = (v ?? '').replaceAll('-', '');
                if (clean.length < 7) return 'Placa inválida';
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.paddingXLarge),
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                minimumSize:
                    const Size.fromHeight(AppDimensions.buttonHeight),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    )
                  : const Text('Salvar Veículo'),
            ),
          ],
        ),
      ),
    );
  }
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _isLoading = true);
    try {
      final vehicle = VehicleModel(
        id: const Uuid().v4(),
        brandId: _selectedBrand!.id,
        brand: _selectedBrand!.name,
        model: _selectedModel!,
        year: int.parse(_yearController.text),
        plate: _plateController.text.replaceAll('-', '').toUpperCase(),
        createdAt: DateTime.now(),
      );
      await ref.read(vehicleRepositoryProvider).addVehicle(uid, vehicle);
      ref.invalidate(userVehiclesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veículo adicionado com sucesso!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
// ── Formatter de placa: ABC-1234 ou ABC-1D23 ───────────────────
class _PlateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    final limited = raw.length > 7 ? raw.substring(0, 7) : raw;
    final formatted = limited.length > 3
        ? '${limited.substring(0, 3)}-${limited.substring(3)}'
        : limited;
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
