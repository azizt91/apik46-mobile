import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:apik_mobile/core/theme/app_colors.dart';

class CustomerScaffold extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const CustomerScaffold({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/debug'),
        backgroundColor: Colors.orange,
        mini: true,
        child: const Icon(Icons.bug_report, size: 20),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _getSelectedIndex(currentRoute),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        indicatorColor: AppColors.primary.withOpacity(0.75),
        backgroundColor: Colors.white,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        elevation: 8,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_outlined),
            selectedIcon: Icon(Icons.receipt),
            label: 'Tagihan',
          ),
          NavigationDestination(
            icon: Icon(Icons.wifi_outlined),
            selectedIcon: Icon(Icons.wifi),
            label: 'WiFi',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  int _getSelectedIndex(String route) {
    if (route.startsWith('/customer/dashboard')) return 0;
    if (route.startsWith('/customer/invoices')) return 1;
    if (route.startsWith('/customer/wifi')) return 2;
    if (route.startsWith('/customer/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/customer/dashboard');
        break;
      case 1:
        context.go('/customer/invoices');
        break;
      case 2:
        context.go('/customer/wifi');
        break;
      case 3:
        context.go('/customer/profile');
        break;
    }
  }
}
