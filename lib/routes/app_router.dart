import 'package:go_router/go_router.dart';
import '../pages/main_screen.dart';
import '../pages/netease_music_page.dart';
import '../pages/nfc_write_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/netease-music',
        builder: (context, state) => const NeteaseMusicPage(),
      ),
      GoRoute(
        path: '/nfc-write',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return NfcWritePage(
            musicLinks: extra?['musicLinks'] as List<Map<String, dynamic>>? ?? [],
            title: extra?['title'] as String? ?? 'NFC写入',
          );
        },
      ),
    ],
  );
}