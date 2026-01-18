import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:retro1/l10n/app_localizations.dart' show AppLocalizations;
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar dados de localização para DateFormat (suporta múltiplos idiomas)
  await initializeDateFormatting('en', null);
  await initializeDateFormatting('pt', null);
  
  // Inicializar Hive
  await HiveService.init();
  
  // Inicializar notificações
  await NotificationService.init();
  
  // Configurar orientação
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // Callback para atualizar idioma
  static VoidCallback? updateLanguageCallback;

  // Método estático para atualizar idioma
  static void updateLanguage() {
    updateLanguageCallback?.call();
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en'); // Default to English

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    // Registrar callback para atualização de idioma
    MyApp.updateLanguageCallback = _loadLanguage;
  }

  @override
  void dispose() {
    MyApp.updateLanguageCallback = null;
    super.dispose();
  }

  void _loadLanguage() {
    final settings = HiveService.getSettings();
    setState(() {
      _locale = Locale(settings.language);
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
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
