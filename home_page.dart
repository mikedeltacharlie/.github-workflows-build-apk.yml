import 'package:flutter/material.dart';
import 'package:fitspot/screens/map_screen.dart';
import 'package:fitspot/screens/locations_screen.dart';
import 'package:fitspot/screens/workouts_screen.dart';
import 'package:fitspot/screens/profile_screen.dart';
import 'package:fitspot/screens/admin_screen.dart';

class HomePage extends StatefulWidget {
  final bool isAdmin;

  const HomePage({super.key, this.isAdmin = false});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  
  late final List<Widget> _screens;
  late final List<BottomNavigationBarItem> _items;

  @override
  void initState() {
    super.initState();
    _screens = [
      const MapScreen(),
      const LocationsScreen(),
      const WorkoutsScreen(),
      const ProfileScreen(),
      if (widget.isAdmin) const AdminScreen(),
    ];

    _items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.map),
        label: 'Mappa',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.location_on),
        label: 'Luoghi',
      ),
      BottomNavigationBarItem(
        icon: SizedBox(
          width: 24,
          height: 24,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              'assets/logo.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.fitness_center),
            ),
          ),
        ),
        label: 'Allenamenti',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profilo',
      ),
      if (widget.isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        selectedLabelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: Theme.of(context).textTheme.labelSmall,
        items: _items,
      ),
    );
  }
}