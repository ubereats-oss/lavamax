import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavamax/core/theme/app_theme.dart';
import 'package:lavamax/firebase_options.dart';
import 'package:lavamax/presentation/providers/auth_provider.dart';
import 'package:lavamax/presentation/screens/auth_screen.dart';
import 'package:lavamax/presentation/screens/home_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const ProviderScope(
      child: LavaMaxApp(),
    ),
  );
}
class LavaMaxApp extends ConsumerWidget {
  const LavaMaxApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    return MaterialApp(
      title: 'LavaMax',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authState.when(
        data: (user) => user != null ? const HomeScreen() : const AuthScreen(),
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => const AuthScreen(),
      ),
    );
  }
}
