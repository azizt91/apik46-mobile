import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _getSelectedIndex(currentRoute),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.receipt), label: 'Tagihan'),
          NavigationDestination(icon: Icon(Icons.wifi), label: 'WiFi'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
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
