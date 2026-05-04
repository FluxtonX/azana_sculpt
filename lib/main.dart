import 'dart:io';
import 'package:azana_sculpt/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/signup/signup_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/coach/coach_main_screen.dart';
import 'screens/login/welcome_screen.dart';
import 'screens/login/forgot_password_screen.dart';
import 'screens/subscription/subscription_screen.dart';

import 'services/stripe_service.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Stripe
  await StripeService.instance.init();

  // Lock to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const AzanaSculptApp());
  //   runApp(
  //     DevicePreview(
  //       enabled: !kReleaseMode,
  //       builder: (context) => const AzanaSculptApp(),
  //     ),
  //   );
}

class AzanaSculptApp extends StatelessWidget {
  const AzanaSculptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // useInheritedMediaQuery: true,
      // locale: DevicePreview.locale(context),
      // builder: DevicePreview.appBuilder,
      title: 'Azana Sculpt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const HomeScreen(),
        '/onboarding': (context) => OnboardingScreen(),
        '/splash': (context) => const SplashScreen(),
        '/coach': (context) => const CoachMainScreen(),
        '/subscription': (context) => const SubscriptionScreen(),
      },
    );
  }
}
