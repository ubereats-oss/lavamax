@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "PROJECT_ROOT=%cd%"
set "LIB_PATH=%PROJECT_ROOT%\lib"

echo.
echo ========================================
echo  LAVAMAX - Criando Estrutura de Lib
echo ========================================
echo.

REM Remover main.dart original
if exist "%LIB_PATH%\main.dart" (
    del "%LIB_PATH%\main.dart"
    echo ✓ main.dart original removido
)

REM ===== CORE =====
mkdir "%LIB_PATH%\core\constants" 2>nul
mkdir "%LIB_PATH%\core\extensions" 2>nul
mkdir "%LIB_PATH%\core\theme" 2>nul
mkdir "%LIB_PATH%\core\utils" 2>nul
mkdir "%LIB_PATH%\core\failures" 2>nul
mkdir "%LIB_PATH%\core\logger" 2>nul
echo ✓ core/ criada

REM ===== DATA =====
mkdir "%LIB_PATH%\data\models" 2>nul
mkdir "%LIB_PATH%\data\repositories" 2>nul
mkdir "%LIB_PATH%\data\services" 2>nul
mkdir "%LIB_PATH%\data\datasources" 2>nul
echo ✓ data/ criada

REM ===== DOMAIN =====
mkdir "%LIB_PATH%\domain\entities" 2>nul
mkdir "%LIB_PATH%\domain\repositories" 2>nul
mkdir "%LIB_PATH%\domain\usecases" 2>nul
echo ✓ domain/ criada

REM ===== PRESENTATION =====
mkdir "%LIB_PATH%\presentation\providers" 2>nul
mkdir "%LIB_PATH%\presentation\screens" 2>nul
mkdir "%LIB_PATH%\presentation\widgets" 2>nul
mkdir "%LIB_PATH%\presentation\pages" 2>nul
echo ✓ presentation/ criada

REM ===== CRIAR ARQUIVOS BASE =====

REM main.dart
(
echo import 'package:flutter/material.dart';
echo import 'package:flutter_riverpod/flutter_riverpod.dart';
echo import 'package:lavamax/core/theme/app_theme.dart';
echo import 'package:lavamax/data/services/firebase_service.dart';
echo import 'package:lavamax/presentation/screens/home_screen.dart';
echo.
echo void main() async {
echo   WidgetsFlutterBinding.ensureInitialized();
echo   await FirebaseService.initialize();
echo   runApp(const ProviderScope(child: MyApp()));
echo }
echo.
echo class MyApp extends StatelessWidget {
echo   const MyApp({Key? key}) : super(key: key);
echo.
echo   @override
echo   Widget build(BuildContext context) {
echo     return MaterialApp(
echo       title: 'LavaMax Agendamento',
echo       theme: AppTheme.lightTheme,
echo       debugShowCheckedModeBanner: false,
echo       home: const HomeScreen(),
echo     );
echo   }
echo }
) > "%LIB_PATH%\main.dart"
echo ✓ main.dart criado

REM app_colors.dart
(
echo import 'package:flutter/material.dart';
echo.
echo class AppColors {
echo   static const Color primary = Color(0xFF1E88E5);
echo   static const Color primaryDark = Color(0xFF1565C0);
echo   static const Color primaryLight = Color(0xFF64B5F6);
echo   static const Color secondary = Color(0xFFFF6F00);
echo   static const Color white = Color(0xFFFFFFFF);
echo   static const Color black = Color(0xFF000000);
echo   static const Color grey50 = Color(0xFFFAFAFA);
echo   static const Color grey100 = Color(0xFFF5F5F5);
echo   static const Color grey200 = Color(0xFFEEEEEE);
echo   static const Color grey300 = Color(0xFFE0E0E0);
echo   static const Color grey600 = Color(0xFF757575);
echo   static const Color success = Color(0xFF4CAF50);
echo   static const Color error = Color(0xFFF44336);
echo   static const Color warning = Color(0xFFFFC107);
echo }
) > "%LIB_PATH%\core\constants\app_colors.dart"
echo ✓ app_colors.dart criado

REM app_strings.dart
(
echo class AppStrings {
echo   static const String appName = 'LavaMax Agendamento';
echo   static const String homeTitle = 'Bem-vindo à LavaMax';
echo   static const String homeSubtitle = 'Agende seu serviço automotivo';
echo   static const String scheduleNow = 'Agendar Agora';
echo   static const String myAppointments = 'Meus Agendamentos';
echo   static const String selectBranch = 'Selecione uma Filial';
echo   static const String selectService = 'Selecione um Serviço';
echo   static const String selectDateTime = 'Selecione Data e Hora';
echo   static const String confirmAppointment = 'Confirmar Agendamento';
echo   static const String loading = 'Carregando...';
echo   static const String error = 'Erro';
echo   static const String success = 'Sucesso';
echo }
) > "%LIB_PATH%\core\constants\app_strings.dart"
echo ✓ app_strings.dart criado

REM app_dimensions.dart
(
echo class AppDimensions {
echo   static const double paddingXSmall = 4.0;
echo   static const double paddingSmall = 8.0;
echo   static const double paddingMedium = 16.0;
echo   static const double paddingLarge = 24.0;
echo   static const double paddingXLarge = 32.0;
echo   static const double radiusSmall = 4.0;
echo   static const double radiusMedium = 8.0;
echo   static const double radiusLarge = 16.0;
echo   static const double buttonHeight = 48.0;
echo }
) > "%LIB_PATH%\core\constants\app_dimensions.dart"
echo ✓ app_dimensions.dart criado

REM app_theme.dart
(
echo import 'package:flutter/material.dart';
echo import 'package:google_fonts/google_fonts.dart';
echo import 'app_colors.dart';
echo.
echo class AppTheme {
echo   static ThemeData get lightTheme {
echo     return ThemeData(
echo       useMaterial3: true,
echo       brightness: Brightness.light,
echo       colorScheme: ColorScheme.fromSeed(
echo         seedColor: AppColors.primary,
echo         brightness: Brightness.light,
echo       ),
echo       textTheme: GoogleFonts.robotoTextTheme(),
echo       appBarTheme: AppBarTheme(
echo         backgroundColor: AppColors.primary,
echo         foregroundColor: AppColors.white,
echo         elevation: 0,
echo         centerTitle: true,
echo       ),
echo     );
echo   }
echo }
) > "%LIB_PATH%\core\theme\app_theme.dart"
echo ✓ app_theme.dart criado

REM firebase_service.dart
(
echo import 'package:firebase_core/firebase_core.dart';
echo import 'package:cloud_firestore/cloud_firestore.dart';
echo import 'firebase_options.dart';
echo.
echo class FirebaseService {
echo   static final FirebaseService _instance = FirebaseService._internal();
echo.
echo   factory FirebaseService() {
echo     return _instance;
echo   }
echo.
echo   FirebaseService._internal();
echo.
echo   static Future^<void^> initialize() async {
echo     await Firebase.initializeApp(
echo       options: DefaultFirebaseOptions.currentPlatform,
echo     );
echo     FirebaseFirestore.instance.settings = const Settings(
echo       persistenceEnabled: false,
echo     );
echo   }
echo.
echo   FirebaseFirestore get firestore =^> FirebaseFirestore.instance;
echo }
) > "%LIB_PATH%\data\services\firebase_service.dart"
echo ✓ firebase_service.dart criado

REM app_failure.dart
(
echo abstract class Failure {
echo   final String message;
echo   Failure(this.message);
echo }
echo.
echo class ServerFailure extends Failure {
echo   ServerFailure(String message) : super(message);
echo }
echo.
echo class CacheFailure extends Failure {
echo   CacheFailure(String message) : super(message);
echo }
echo.
echo class NetworkFailure extends Failure {
echo   NetworkFailure(String message) : super(message);
echo }
echo.
echo class ValidationFailure extends Failure {
echo   ValidationFailure(String message) : super(message);
echo }
) > "%LIB_PATH%\core\failures\app_failure.dart"
echo ✓ app_failure.dart criado

REM home_screen.dart
(
echo import 'package:flutter/material.dart';
echo import 'package:lavamax/core/constants/app_colors.dart';
echo import 'package:lavamax/core/constants/app_strings.dart';
echo.
echo class HomeScreen extends StatelessWidget {
echo   const HomeScreen({Key? key}) : super(key: key);
echo.
echo   @override
echo   Widget build(BuildContext context) {
echo     return Scaffold(
echo       appBar: AppBar(
echo         title: const Text(AppStrings.appName),
echo         backgroundColor: AppColors.primary,
echo       ),
echo       body: const Center(
echo         child: Text(AppStrings.homeTitle),
echo       ),
echo     );
echo   }
echo }
) > "%LIB_PATH%\presentation\screens\home_screen.dart"
echo ✓ home_screen.dart criado

echo.
echo ========================================
echo  ✓✓✓ ESTRUTURA CRIADA COM SUCESSO
echo ========================================
echo.
echo Próximos passos:
echo   1. flutter pub get
echo   2. flutter run
echo.
pause