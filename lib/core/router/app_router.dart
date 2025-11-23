import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:apik_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:apik_mobile/features/auth/presentation/pages/splash_page.dart';
import 'package:apik_mobile/features/customer/dashboard/presentation/pages/customer_dashboard_page.dart';
import 'package:apik_mobile/features/customer/profile/presentation/pages/customer_profile_page.dart';
import 'package:apik_mobile/features/customer/profile/presentation/pages/edit_profile_page.dart';
import 'package:apik_mobile/features/customer/profile/presentation/pages/change_password_page.dart';
import 'package:apik_mobile/features/customer/invoices/presentation/pages/customer_invoices_page.dart';
import 'package:apik_mobile/features/customer/payment_info/presentation/pages/payment_info_page.dart';
import 'package:apik_mobile/features/customer/help/presentation/pages/help_page.dart';
import 'package:apik_mobile/features/customer/wifi/presentation/pages/wifi_settings_page.dart';
import 'package:apik_mobile/data/providers/auth_provider.dart';
import '../widgets/customer_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isSplash = state.matchedLocation == '/splash';

      // If not logged in and not on login page, redirect to login
      if (!isLoggedIn && !isLoggingIn && !isSplash) {
        return '/login';
      }

      // If logged in and on login page, redirect to customer dashboard
      if (isLoggedIn && isLoggingIn) {
        return '/customer/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),

      // Customer Routes wrapped in ShellRoute to persist BottomNavigationBar
      ShellRoute(
        builder: (context, state, child) {
          return CustomerScaffold(
            currentRoute: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/customer/dashboard',
            builder: (context, state) => const CustomerDashboardPage(),
          ),
          GoRoute(
            path: '/customer/profile',
            builder: (context, state) => const CustomerProfilePage(),
          ),
          GoRoute(
            path: '/customer/invoices',
            builder: (context, state) {
              final tab = state.uri.queryParameters['tab'];
              final invoiceId = state.uri.queryParameters['invoiceId'];
              final initialTabIndex = tab != null ? int.tryParse(tab) ?? 0 : 0;
              return CustomerInvoicesPage(
                initialTabIndex: initialTabIndex,
                highlightInvoiceId: invoiceId,
              );
            },
          ),
          GoRoute(
            path: '/customer/payment-info',
            builder: (context, state) => const PaymentInfoPage(),
          ),
          GoRoute(
            path: '/customer/help',
            builder: (context, state) => const HelpPage(),
          ),
          GoRoute(
            path: '/customer/wifi',
            builder: (context, state) => const WifiSettingsPage(),
          ),
        ],
      ),
      
      // Profile Edit Routes (outside ShellRoute - no bottom nav)
      GoRoute(
        path: '/customer/profile/edit',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/customer/profile/change-password',
        builder: (context, state) => const ChangePasswordPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
});
