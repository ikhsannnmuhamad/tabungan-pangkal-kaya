import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/home_page.dart';
import 'package:intl/date_symbol_data_local.dart';

// Provider
import 'package:provider/provider.dart';
import 'services/notif_service.dart';
import 'services/theme_service.dart'; // service baru untuk toggle theme

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('id_ID', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotifService()),
        ChangeNotifierProvider(create: (_) => ThemeService()), // tambahkan provider theme
      ],
      child: const TabunganPangkalKayaApp(),
    ),
  );
}

class TabunganPangkalKayaApp extends StatelessWidget {
  const TabunganPangkalKayaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-HTabungan',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light, // langsung di ColorScheme
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark, // langsung di ColorScheme
        ),
        useMaterial3: true,
      ),
      themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomePage(),
    );
  }
}