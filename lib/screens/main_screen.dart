import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_screen.dart';
import 'home_screen.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 2; // Default to home screen (now index 2 in the middle)
  late AnimationController _animationController;
  late PageController _pageController;
  
  // Farmer data - replace with actual data later
  final Map<String, dynamic> _farmerData = {
    'name': 'John Smith',
    'farmName': 'Green Valley Farm',
    'location': 'California, USA',
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pageController = PageController(
      initialPage: _selectedIndex,
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {}); // Refresh state
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Important for the transparent navigation bar
      appBar: _buildAppBar(),
      body: LiquidPullToRefresh(
        onRefresh: _onRefresh,
        color: Colors.green.shade700,
        backgroundColor: Colors.white,
        height: 50,
        animSpeedFactor: 2,
        showChildOpacityTransition: false,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Disable swiping
          children: [
            _buildDashboardContent(),
            const AnalyticsScreen(),
            HomeScreen(onNavigate: _navigateToPage),
            _buildPlaceholderContent('Alerts'),
            const ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Icon(
            Icons.agriculture,
            size: 28,
            color: Colors.white,
          ).animate()
            .fadeIn(duration: 500.ms)
            .slideX(begin: -0.2, end: 0, duration: 500.ms, curve: Curves.easeOut),
          SizedBox(width: 10),
          Flexible(
            child: Text(
              _getScreenTitle(),
              style: GoogleFonts.montserrat(
                textStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              overflow: TextOverflow.ellipsis,
            ).animate()
              .fadeIn(duration: 500.ms)
              .slideX(begin: -0.2, end: 0, duration: 500.ms, curve: Curves.easeOut),
          ),
        ],
      ),
      backgroundColor: Colors.green.shade700,
      foregroundColor: Colors.white,
      elevation: 2,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: () => _onRefresh(),
        ).animate()
          .fadeIn(duration: 500.ms, delay: 100.ms)
          .slideX(begin: 0.2, end: 0, duration: 500.ms, delay: 100.ms, curve: Curves.easeOut),
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ).animate()
          .fadeIn(duration: 500.ms, delay: 200.ms)
          .slideX(begin: 0.2, end: 0, duration: 500.ms, delay: 200.ms, curve: Curves.easeOut),
      ],
    );
  }

  // Get the appropriate screen title based on selected index
  String _getScreenTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Analytics';
      case 2:
        return 'Home';
      case 3:
        return 'Alerts';
      case 4:
        return 'Profile';
      default:
        return 'Smart Farm';
    }
  }

  // Navigate to a specific page
  void _navigateToPage(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  // Dashboard content
  Widget _buildDashboardContent() {
    return DashboardScreen();
  }

  // Placeholder for screens not yet implemented
  Widget _buildPlaceholderContent(String screenName) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green.shade800,
            Colors.green.shade600,
            Colors.green.shade400,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 80,
              color: Colors.white.withOpacity(0.8),
            ).animate()
              .fadeIn(duration: 800.ms)
              .scaleXY(begin: 0.5, end: 1.0, duration: 800.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text(
              '$screenName Coming Soon',
              style: GoogleFonts.montserrat(
                textStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ).animate()
              .fadeIn(duration: 800.ms, delay: 200.ms)
              .slideY(begin: 0.2, end: 0, duration: 800.ms, delay: 200.ms, curve: Curves.easeOut),
            const SizedBox(height: 8),
            Text(
              'This feature is under development',
              style: GoogleFonts.montserrat(
                textStyle: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ).animate()
              .fadeIn(duration: 800.ms, delay: 400.ms)
              .slideY(begin: 0.2, end: 0, duration: 800.ms, delay: 400.ms, curve: Curves.easeOut),
          ],
        ),
      ),
    );
  }

  // Modern floating action button that changes based on the screen
  Widget _buildFloatingActionButton() {
    if (_selectedIndex == 0) {
      return FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Add new node functionality coming soon',
                style: GoogleFonts.montserrat(),
              ),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add),
      ).animate()
        .scale(duration: 500.ms, curve: Curves.easeOut)
        .fadeIn(duration: 500.ms);
    } else if (_selectedIndex == 3) {
      return FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Create alert functionality coming soon',
                style: GoogleFonts.montserrat(),
              ),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add_alert),
      ).animate()
        .scale(duration: 500.ms, curve: Curves.easeOut)
        .fadeIn(duration: 500.ms);
    }
    
    return const SizedBox.shrink(); // No FAB for other screens
  }

  // Bottom Navigation Bar with Home in the middle
  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _navigateToPage,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.green.shade700,
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: GoogleFonts.montserrat(
            textStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          unselectedLabelStyle: GoogleFonts.montserrat(
            textStyle: TextStyle(
              fontSize: 12,
            ),
          ),
          type: BottomNavigationBarType.fixed,
          items: [
            _buildNavItem(Icons.dashboard, 'Dashboard', 0),
            _buildNavItem(Icons.analytics, 'Analytics', 1),
            _buildNavItem(Icons.home, 'Home', 2),
            _buildNavItem(Icons.notifications, 'Alerts', 3),
            _buildNavItem(Icons.person, 'Profile', 4),
          ],
        ),
      ),
    );
  }
  
  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = index == _selectedIndex;
    
    return BottomNavigationBarItem(
      icon: Icon(
        icon,
        size: isSelected ? 28 : 24, // Slightly larger when selected
      )
      .animate(
        target: isSelected ? 1 : 0,
        autoPlay: false,
      )
      .scaleXY(
        begin: 1.0,
        end: 1.2,
        duration: 300.ms,
        curve: Curves.easeOut,
      ),
      label: label,
    );
  }
} 