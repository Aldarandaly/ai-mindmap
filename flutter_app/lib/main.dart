import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/auth/ui/login_screen.dart';
import './features/reset/reset_password_screen.dart';
import 'features/main/ui/main.screen.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_sizes.dart';
import 'core/network/api_client.dart';
import 'shared/widgets/network_background.dart';
import 'features/onboarding/ui/onboarding_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  final hasToken = await ApiClient().hasToken();
  runApp(MyApp(isLoggedIn: hasToken));
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static const _channel = MethodChannel('flutter/deeplink');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialLink();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkInitialLink() async {
    try {
      const channel = MethodChannel('flutter/deeplink');
      final link = await channel.invokeMethod<String>('getInitialLink');
      if (link != null) _processLink(link);

      channel.setMethodCallHandler((call) async {
        if (call.method == 'onLink') {
          _processLink(call.arguments as String);
        }
      });
    } catch (_) {}
  }

  void _processLink(String link) {
    try {
      final uri = Uri.parse(link);
      if (uri.scheme == 'myapp' && uri.host == 'reset-password') {
        final token = uri.queryParameters['token'] ?? '';
        final email = uri.queryParameters['email'] ?? '';
        if (token.isNotEmpty && email.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => ResetPasswordScreen(token: token, email: email),
              ),
            );
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        canvasColor: Colors.transparent,
        cardColor: AppColors.surface,
        dividerColor: AppColors.border,
        dialogBackgroundColor: const Color(0xFF1A1A24),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF1A1A24),
          modalBackgroundColor: Color(0xFF1A1A24),
        ),
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
          elevation: 0,
        ),
      ),
      builder: (context, child) {
        AppSizes.init(context);
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.noScaling),
          child: AppBackground(child: child!),
        );
      },
      home: widget.isLoggedIn ? const MainScreen() : const OnboardingScreen(),
    );
  }
}
