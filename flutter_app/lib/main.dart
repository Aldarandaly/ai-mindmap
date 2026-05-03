import 'package:flutter/material.dart';
import 'core/network/api_client.dart';
import 'features/auth/data/auth_service.dart';
import 'features/auth/ui/login_screen.dart';
import 'features/projects/ui/projects_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final token = await AuthService.getToken();
  if (token != null) ApiClient.setToken(token);

  runApp(MyApp(isLoggedIn: token != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DiagramAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F0E17),
      ),
      home: isLoggedIn ? const ProjectsScreen() : const LoginScreen(),
    );
  }
}