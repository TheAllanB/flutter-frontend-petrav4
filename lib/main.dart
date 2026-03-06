import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/org_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // The original authProvider instance is used to check auth status before runApp.
  // A new AuthProvider instance will be created and provided to the widget tree.
  final authProvider = AuthProvider();
  await authProvider.checkAuth();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => OrganizationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return MaterialApp(
          title: 'AppV4',
          theme: ThemeData(
            useMaterial3: true,
            primaryColor: const Color(0xFF1967D2),
            scaffoldBackgroundColor: const Color(0xFFF4F7FC),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1967D2),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1967D2)),
          ),
          home: auth.isAuthenticated ? MainNavigation() : LoginScreen(),
        );
      },
    );
  }
}
