import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
/// Emite `true` quando há conexão de rede ativa, `false` caso contrário.
/// Verifica o estado inicial imediatamente ao ser criado.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  // Estado inicial — sem esperar o primeiro evento do stream
  final initial = await connectivity.checkConnectivity();
  yield initial.any((r) => r != ConnectivityResult.none);
  // Atualizações em tempo real
  await for (final results in connectivity.onConnectivityChanged) {
    yield results.any((r) => r != ConnectivityResult.none);
  }
});
/// Atalho síncrono: `true` = online, `false` = offline.
/// Assume online durante o carregamento inicial para não bloquear desnecessariamente.
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).when(
    data: (online) => online,
    loading: () => true,
    error: (_, _) => true,
  );
});
