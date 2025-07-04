import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:homeypark_mobile_application/config/pref/preferences.dart';
import 'package:homeypark_mobile_application/screens/home_screen.dart';
import 'package:homeypark_mobile_application/screens/sign_in_screen.dart';
import 'package:homeypark_mobile_application/services/iam_service.dart';
import 'package:homeypark_mobile_application/services/profile_service.dart';
import 'package:homeypark_mobile_application/services/vehicle_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  
  WidgetsFlutterBinding.ensureInitialized();

  await preferences.init();
  await dotenv.load(fileName: ".env");
   await initializeDateFormatting('es_ES', null);

  final iamService = IAMService();
  await iamService.initialize();

  final profileService = ProfileService(iamService);
  final vehicleService = VehicleService(iamService); 

    final GoogleMapsFlutterPlatform mapsImplementation = GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    mapsImplementation.useAndroidViewSurface = true;
    await mapsImplementation.initializeWithRenderer(AndroidMapRenderer.latest);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: iamService),
        ChangeNotifierProvider.value(value: profileService),
        ChangeNotifierProvider.value(value: vehicleService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomeyPark',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      
      // 3. AÑADE LOS DELEGADOS Y LOCALES SOPORTADOS
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // Inglés, por si acaso
        Locale('es', 'ES'), // Español de España
      ],

      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final iamService = context.watch<IAMService>();

    if (iamService.isAuthenticated) {
      return const HomeScreen();
    } else {
      return const SignInScreen();
    }
  }
}