import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rajyo_darpan_publisher/core/theme/app_theme.dart';
import 'package:rajyo_darpan_publisher/core/constants/app_colors.dart';
import 'package:rajyo_darpan_publisher/presentation/providers/auth_provider.dart';
import 'package:rajyo_darpan_publisher/presentation/providers/dashboard_provider.dart';
import 'package:rajyo_darpan_publisher/presentation/providers/article_provider.dart';
import 'package:rajyo_darpan_publisher/presentation/providers/draft_provider.dart';
import 'package:rajyo_darpan_publisher/presentation/screens/auth/login_screen.dart';
import 'package:rajyo_darpan_publisher/presentation/screens/dashboard/home_dashboard_screen.dart';
import 'package:rajyo_darpan_publisher/presentation/screens/articles/articles_list_screen.dart';
import 'package:rajyo_darpan_publisher/presentation/screens/editor/create_article_screen.dart';
import 'package:rajyo_darpan_publisher/presentation/screens/schedule/schedule_screen.dart';
import 'package:rajyo_darpan_publisher/presentation/screens/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RajyoDarpanApp());
}

class RajyoDarpanApp extends StatelessWidget {
  const RajyoDarpanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuthStatus()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ArticleProvider()),
        ChangeNotifierProvider(create: (_) => DraftProvider()..loadDrafts()),
      ],
      child: MaterialApp(
        title: 'Rajyo Darpan Publisher',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (auth.isAuthenticated) {
      return const MainNavigationScaffold();
    }
    return const LoginScreen();
  }
}

class MainNavigationScaffold extends StatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeDashboardScreen(onNavigateTab: (idx) => setState(() => _currentIndex = idx)),
      const ArticlesListScreen(),
      const SizedBox.shrink(), // Placeholder for center modal Create button
      const ScheduleScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            // Open Create Article Screen as full modal
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateArticleScreen()),
            );
          } else {
            setState(() => _currentIndex = index);
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'হোম',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            activeIcon: Icon(Icons.article),
            label: 'সংবাদ',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.add, color: Colors.white, size: 20),
            ),
            label: 'লিখুন',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule_outlined),
            activeIcon: Icon(Icons.schedule),
            label: 'শিডিউল',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'সেটিংস',
          ),
        ],
      ),
    );
  }
}
