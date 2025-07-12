import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:totpfy/presentation/dashboard_page.dart';
import 'package:totpfy/presentation/qr_scanner_view.dart';
import 'package:totpfy/providers/dashboard_provider.dart';
import 'core/storage/storage.dart';
import 'core/theme.dart';
import 'presentation/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TotpfyApp());
}

class TotpfyApp extends StatelessWidget {
  const TotpfyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Totpfy',
      theme: TotpfyTheme.lightTheme,
      darkTheme: TotpfyTheme.darkTheme,
      themeMode: ThemeMode.system, // Automatically switch based on system preference
      debugShowCheckedModeBanner: false,
      home: const InitialRouteWidget(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => const HomePage());
          case '/qr-scanner':
            return MaterialPageRoute(builder: (context) => QrScannerView(storageService: SecureStorageService()));
          case '/dashboard':
            return MaterialPageRoute(builder: (context) {
              return ChangeNotifierProvider(
                create: (context) => DashboardProvider(storageService: SecureStorageService()),
                child: const DashboardPage(),
              );
            });
          default:
            return MaterialPageRoute(builder: (context) => const HomePage());
        }
      },
    );
  }
}

class InitialRouteWidget extends StatefulWidget {
  const InitialRouteWidget({super.key});

  @override
  State<InitialRouteWidget> createState() => _InitialRouteWidgetState();
}

class _InitialRouteWidgetState extends State<InitialRouteWidget> {
  late Future<Widget> _initialRouteFuture;

  @override
  void initState() {
    super.initState();
    _initialRouteFuture = _determineInitialRoute();
  }

  Future<Widget> _determineInitialRoute() async {
    try {
      final storageService = SecureStorageService();
      final allKeys = await storageService.getAllSecretKeys();
      
      // If there are stored TOTP secrets, go to dashboard
      if (allKeys.isNotEmpty) {
        return ChangeNotifierProvider(
          create: (context) => DashboardProvider(storageService: storageService),
          child: const DashboardPage(),
        );
      } else {
        // If no stored secrets, go to home page
        return const HomePage();
      }
    } catch (e) {
      // If there's an error, default to home page
      debugPrint('Error checking storage: $e');
      return const HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _initialRouteFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Error loading app'),
            ),
          );
        }
        return snapshot.data ?? const HomePage();
      },
    );
  }
}