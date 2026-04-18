import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:retro1/l10n/app_localizations.dart' show AppLocalizations;
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/hive_service.dart';
import 'services/backup_service.dart';
import 'services/quote_service.dart';
import 'services/timeline_prefs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar dados de localização para DateFormat (suporta múltiplos idiomas)
  await initializeDateFormatting('en', null);
  await initializeDateFormatting('pt', null);
  
  // Inicializar Hive
  await HiveService.init();

  // Inicializar serviço de frases (depende do Hive)
  await QuoteService.init();

  // Inicializar preferências de visualização
  await TimelinePrefs.init();
  await ThumbnailSizePrefs.init();
  await MediaPickerPrefs.init();

  // Inicializar notificações
  await NotificationService.init();

  // Auto backup (runs silently in background if enabled)
  BackupService.checkAndRunAutoBackup();
  
  // Allow all orientations (portraitDown excluded on iOS — unsupported on iPhone)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    if (!Platform.isIOS) DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // Callback para atualizar idioma
  static VoidCallback? updateLanguageCallback;
  
  // Callback para atualizar tema
  static VoidCallback? updateThemeCallback;

  // Método estático para atualizar idioma
  static void updateLanguage() {
    updateLanguageCallback?.call();
  }
  
  // Método estático para atualizar tema
  static void updateTheme() {
    updateThemeCallback?.call();
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en'); // Default to English
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    // Registrar callback para atualização de idioma e tema
    MyApp.updateLanguageCallback = _loadSettings;
    MyApp.updateThemeCallback = _loadSettings;
  }

  @override
  void dispose() {
    MyApp.updateLanguageCallback = null;
    MyApp.updateThemeCallback = null;
    super.dispose();
  }

  void _loadSettings() {
    final settings = HiveService.getSettings();
    setState(() {
      _locale = Locale(settings.language);
      // Converter string para ThemeMode
      switch (settings.themeMode) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        case 'system':
        default:
          _themeMode = ThemeMode.system;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Retro1',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English (default)
        Locale('pt'), // Portuguese
        Locale('es'), // Spanish
        Locale('fr'), // French
        Locale('de'), // German
        Locale('it'), // Italian
      ],
      locale: _locale, // Usar idioma das configurações
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      themeMode: _themeMode,
      home: const HomeScreen(),
    );
  }
}
