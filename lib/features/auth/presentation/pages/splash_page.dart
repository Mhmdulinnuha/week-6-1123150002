import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/product_divider.dart';
import '../.././../../core/routes/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/secure_storage.dart';
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: MaterialApp(
        title:                  'My App',
        debugShowCheckedModeBanner: false,
        theme:                  AppTheme.light,
        initialRoute:           AppRouter.splash,
        routes:                 AppRouter.routes,
      ),
    );
  }
}


// SplashPage: cek token tersimpan, redirect otomatis
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override State<SplashPage> createState() => _SplashPageState();
}


class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }


  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2)); // Animasi splash
    if (!mounted) return;


    final token = await SecureStorageService.getToken();
    final route = token != null ? AppRouter.dashboard : AppRouter.login;
    Navigator.pushReplacementNamed(context, route);
  }


  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );
}
