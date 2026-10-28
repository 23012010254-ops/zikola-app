import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/audio_service.dart';

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
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          )
        ],
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 4, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined, 'Beranda', '/home', currentIndex == 0),
          if (appState.isParentMode)
            _buildNavItem(context, currentIndex == 1 ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded, 'Konsultasi', '/consultation', currentIndex == 1, badgeCount: unreadChats),
          _buildNavItem(context, currentIndex == 2 ? Icons.people_rounded : Icons.people_outline_rounded, 'Komunitas', '/community', currentIndex == 2),
          _buildNavItem(context, currentIndex == 3 ? Icons.bar_chart_rounded : Icons.bar_chart_outlined, 'Progres', '/progress', currentIndex == 3),
          _buildNavItem(context, currentIndex == 4 ? Icons.person_rounded : Icons.person_outline_rounded, 'Profil', '/profile', currentIndex == 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, String route, bool active, {int badgeCount = 0}) {
    return GestureDetector(
      onTap: () async {
        if (!active) {
          final appState = Provider.of<AppState>(context, listen: false);
          // Play click SFX only in Child Mode
          if (!appState.isParentMode) {
            AudioService().playClick();
          }
          if (route == '/consultation' && !appState.isParentMode) {
            final bool hasPin = appState.parentalPin != null && appState.parentalPin!.isNotEmpty;
            final dynamic result = await Navigator.pushNamed(
              context, 
              '/parental-pin', 
              arguments: {
                'isSetup': !hasPin,
                'currentPin': appState.parentalPin,
              }
            );
            
            if (result == true || (result is String && result.length == 4)) {
              if (result is String && result.length == 4) {
                await appState.setParentalPin(result);
              }
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
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: active ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                  size: 26,
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
                fontSize: 11,
                fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                color: active ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
              ),
            ),
            if (active) ...[
              const SizedBox(height: 3),
              Container(
                width: 18,
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ] else ...[
              const SizedBox(height: 6),
            ]
          ],
        ),
      ),
    );
  }
}
