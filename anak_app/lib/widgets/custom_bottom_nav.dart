import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  
  const CustomBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final int unreadChats = appState.unreadChatsCount;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: Border(top: BorderSide(color: AppTheme.gray200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(context, Icons.home_outlined, 'Beranda', '/home', currentIndex == 0),
          if (appState.isParentMode)
            _buildNavItem(context, Icons.chat_bubble_outline, 'Konsultasi', '/consultation', currentIndex == 1, badgeCount: unreadChats),
          _buildNavItem(context, Icons.people_outline, 'Komunitas', '/community', currentIndex == 2),
          _buildNavItem(context, Icons.bar_chart_outlined, 'Progres', '/progress', currentIndex == 3),
          _buildNavItem(context, Icons.person_outline, 'Profil', '/profile', currentIndex == 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, String route, bool active, {int badgeCount = 0}) {
    return GestureDetector(
      onTap: () async {
        if (!active) {
          final appState = Provider.of<AppState>(context, listen: false);
          if (route == '/consultation' && !appState.isParentMode) {
            final bool hasPin = appState.parentalPin != null && appState.parentalPin!.isNotEmpty;
            final bool? verified = await Navigator.pushNamed<bool>(
              context, 
              '/parental-pin', 
              arguments: {
                'isSetup': !hasPin,
                'currentPin': appState.parentalPin,
              }
            );
            
            if (verified == true) {
              appState.setParentMode(true);
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, route);
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Akses Dibatalkan. Hanya untuk orang tua 🔒'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }
          } else {
            Navigator.pushReplacementNamed(context, route);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: active ? const Color(0xFFF97316) : AppTheme.gray400,
                  size: 24,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? const Color(0xFFF97316) : AppTheme.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
