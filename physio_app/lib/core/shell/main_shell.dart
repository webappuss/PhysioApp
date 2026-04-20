import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = switch (location) {
      String l when l.startsWith('/dashboard')   => 0,
      String l when l.startsWith('/bookings')    => 1,
      String l when l.startsWith('/patients')    => 2,
      String l when l.startsWith('/profile')     => 3,
      _                                          => 0,
    };

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/dashboard');
            case 1: context.go('/bookings');
            case 2: context.go('/patients');
            case 3: context.go('/profile');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined),     selectedIcon: Icon(Icons.home),          label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_outlined),  selectedIcon: Icon(Icons.calendar_month), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.people_outline),     selectedIcon: Icon(Icons.people),         label: 'Patients'),
          NavigationDestination(icon: Icon(Icons.person_outline),     selectedIcon: Icon(Icons.person),         label: 'Profile'),
        ],
      ),
    );
  }
}
