import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/neumo_bottom_nav.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        child: NeumoBottomNav(
          tabs: const [
            (Icons.home_outlined, 'Beranda'),
            (Icons.bar_chart_outlined, 'Riwayat'),
            (Icons.menu_book_outlined, 'Edukasi'),
            (Icons.person_outline, 'Profil'),
          ],
          currentIndex: navigationShell.currentIndex,
          onSelect: (i) => navigationShell.goBranch(
            i,
            initialLocation: i == navigationShell.currentIndex,
          ),
        ),
      ),
    );
  }
}
