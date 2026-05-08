import 'package:flutter/material.dart';
import 'features/auth/ui/login_screen.dart';
import 'features/main/ui/main.screen.dart';
import 'core/constants/app_colors.dart';
import 'core/network/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hasToken = await ApiClient().hasToken();
  runApp(MyApp(isLoggedIn: hasToken));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        canvasColor: AppColors.background,
        cardColor: AppColors.surface,
        dividerColor: AppColors.border,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          onPrimary: Colors.white,
        ),
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textTertiary,
        ),
      ),
      home: isLoggedIn ? MainScreen() : const LoginScreen(),
    );
  }
}