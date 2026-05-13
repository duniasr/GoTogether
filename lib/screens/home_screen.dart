import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/quedadas_service.dart';
import 'profile_screen.dart';
import 'map_screen.dart';
import 'mis_planes_screen.dart';
import 'home/widgets/explore_tab.dart';
import 'home/widgets/create_event_dialog.dart';
import '../l10n/app_localizations.dart';
import '../models/aviso_modificacion.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  int _currentIndex = 0;

  final QuedadasService _service = QuedadasService();
  StreamSubscription<List<AvisoModificacion>>? _avisosSub;
  bool _hasShownModificationsPopup = false;
  int _misPlanesInitialTab = 0;

  @override
  void initState() {
    super.initState();
    _avisosSub = _service.escucharMisAvisos().listen((avisos) {
      if (avisos.isNotEmpty && !_hasShownModificationsPopup) {
        _hasShownModificationsPopup = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mostrarPopupModificaciones(avisos);
        });
      }
    });
  }

  @override
  void dispose() {
    _avisosSub?.cancel();
    super.dispose();
  }

  void _mostrarPopupModificaciones(List<AvisoModificacion> avisos) {
    if (!mounted) return;

    final camposSet = avisos.expand((a) => a.campos).toSet();
    final translatedCamposList = camposSet.map((c) {
      if (c == 'fecha') return AppLocalizations.get('date').toLowerCase();
      if (c == 'ubicacion') return AppLocalizations.get('location').toLowerCase();
      return c;
    }).toList();

    String fieldsStr;
    if (translatedCamposList.length > 1) {
      final last = translatedCamposList.removeLast();
      final conjunction = AppLocalizations.localeNotifier.value.languageCode == 'es' ? 'y' : 'and';
      fieldsStr = '${translatedCamposList.join(", ")} $conjunction $last';
    } else {
      fieldsStr = translatedCamposList.isNotEmpty ? translatedCamposList.first : '';
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.orange,
                  size: 40,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppLocalizations.get('modifications_title'),
                style: AppTextStyles.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppLocalizations.get('modifications_desc')
                    .replaceAll('{fields}', fieldsStr)
                    .replaceAll('{count}', avisos.length.toString()),
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        setState(() {
                          _currentIndex = 3;
                          _misPlanesInitialTab = 1; // Pestaña "Unidos"
                        });
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        AppLocalizations.get('view_in_my_plans'),
                        style: AppTextStyles.button.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      AppLocalizations.get('got_it'),
                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> get _categories => [
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
                onCategorySelected: (cat) =>
                    setState(() => _selectedCategory = cat),
                categories: _categories,
              )
            : _currentIndex == 1
            ? MapScreen()
            : _currentIndex == 3
            ? MisPlanesScreen(initialIndex: _misPlanesInitialTab)
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
      return ProfileScreen();
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
          setState(() {
            _currentIndex = index;
            if (index != 3) _misPlanesInitialTab = 0;
          });
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
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore_rounded),
            label: AppLocalizations.get('explore'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map_rounded),
            label: AppLocalizations.get('map'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add, color: Colors.transparent),
            label: AppLocalizations.get('create'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            activeIcon: Icon(Icons.event_note_rounded),
            label: AppLocalizations.get('my_plans'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: AppLocalizations.get('profile'),
          ),
        ],
      ),
    );
  }
}
