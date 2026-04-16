import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../pages/verify_email_page.dart';
import '../pages/login_pages.dart';
import 'package:provider/provider.dart';

// Bungkus halaman yang butuh autentikasi dengan AuthGuard
class AuthGuard extends StatelessWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});


  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;


    return switch (status) {
      AuthStatus.authenticated => child,           // Lanjut ke halaman
      AuthStatus.emailNotVerified =>
        const VerifyEmailPage(),                   // Redirect verifikasi
      _ => const LoginPage(),                     // Redirect login
    };
  }
}


// Penggunaan di routes:
// dashboard: (_) => const AuthGuard(child: DashboardPage())
//            ↑ DashboardPage HANYA muncul jika status = authenticated
