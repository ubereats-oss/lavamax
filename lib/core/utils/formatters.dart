import 'package:intl/intl.dart';
/// Formata um valor double para moeda BRL: R$ 1.500,00
String formatBrl(double value) {
  return NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  ).format(value);
}
/// Formata uma placa para o padrão XXX-XXXX.
/// Remove traços existentes antes de reformatar.
String formatPlate(String plate) {
  final clean = plate.toUpperCase().replaceAll('-', '').replaceAll(' ', '');
  if (clean.length >= 4) {
    return '${clean.substring(0, 3)}-${clean.substring(3)}';
  }
  return plate.toUpperCase();
}
/// Formata um telefone para (XX)XXXXX-XXXX ou (XX)XXXX-XXXX.
/// Aceita apenas dígitos; ignora formatação existente.
String formatPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11) {
    // Celular: (XX)XXXXX-XXXX
    return '(${digits.substring(0, 2)})${digits.substring(2, 7)}-${digits.substring(7)}';
  }
  if (digits.length == 10) {
    // Fixo: (XX)XXXX-XXXX
    return '(${digits.substring(0, 2)})${digits.substring(2, 6)}-${digits.substring(6)}';
  }
  // Retorna original se não se encaixar
  return phone;
}
