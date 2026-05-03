import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/quedadas_service.dart';
import 'profile_screen.dart';
import 'map_screen.dart'; 
import 'mis_planes_screen.dart';
import 'home/widgets/explore_tab.dart';
import 'home/widgets/create_event_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  int _currentIndex = 0;

  final QuedadasService _service = QuedadasService();

  final List<String> _categories = [
    'All',
    'Deporte',
    'Naturaleza',
    'Estudio',
    'Ocio',
    'Cultura',
    'Gastronomía',
    'Fiesta',
    'Voluntariado',
    'Viajes',
    'Videojuegos',
    'Música',
    'Networking',
    'Otros',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
       body: SafeArea(
        child: _currentIndex == 0
            ? ExploreTab(
                service: _service,
                selectedCategory: _selectedCategory,
                onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
                categories: _categories,
              )
            : _currentIndex == 1
                ? const MapScreen()
                : _currentIndex == 3
                    ? const MisPlanesScreen()
                    : _buildPlaceholderTab(_currentIndex),
      ),
      floatingActionButton: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => showCreateEventDialog(context, _service),
          backgroundColor: const Color(0xFFF59E0B),
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 36),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildPlaceholderTab(int index) {
    if (index == 4) {
      return const ProfileScreen();
    }

    return const SizedBox.shrink();
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: Color(0xFFEBEFF5), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            showCreateEventDialog(context, _service);
            return;
          }
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        selectedLabelStyle: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: AppTextStyles.labelSmall,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map_rounded),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add, color: Colors.transparent),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            activeIcon: Icon(Icons.event_note_rounded),
            label: 'My Plans',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
