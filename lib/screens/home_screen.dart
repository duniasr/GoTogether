import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/quedadas_service.dart';
import 'profile_screen.dart';
// import 'map_screen.dart'; // Will be used when implemented
import 'home/widgets/explore_tab.dart';
import 'home/widgets/create_event_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'Todos';
  int _currentIndex = 0;

  // Servicio de quedadas conectado a Firebase
  final QuedadasService _service = QuedadasService();

  final List<String> _categories = [
    'Todos',
    'Fiesta',
    'Deporte',
    'Cultura',
    'Gastronomía',
    'Aire libre',
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
            : _buildPlaceholderTab(_currentIndex),
      ),
      floatingActionButton: _currentIndex == 0
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: AppShadows.button,
              ),
              child: FloatingActionButton.extended(
                onPressed: () => showCreateEventDialog(context, _service),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_rounded, size: 22),
                label: Text(
                  'Crear plan',
                  style: AppTextStyles.button.copyWith(color: Colors.white),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildPlaceholderTab(int index) {
    // Si el usuario toca el índice 3 (la 4ª pestaña, "Perfil")
    if (index == 3) {
      return const ProfileScreen(); // ¡Llamamos a tu pantalla!
    }

    // Para Mapa (1) y Mis planes (2), mostramos un texto de aviso
    return Center(
      child: Text(
        'Próximamente...',
        style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textHint),
      ),
    );
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
        onTap: (index) => setState(() => _currentIndex = index),
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
            label: 'Explorar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map_rounded),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            activeIcon: Icon(Icons.event_note_rounded),
            label: 'Mis planes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
