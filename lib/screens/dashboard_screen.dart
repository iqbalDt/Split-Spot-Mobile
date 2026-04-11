import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'activity_screen.dart';
import 'summary_screen.dart';
import 'profile_screen.dart';
import 'create_event_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  late List<Widget> _screens;

  final List<NavItem> _navItems = [
    NavItem(icon: Icons.home, label: 'Home'),
    NavItem(icon: Icons.history, label: 'Activity'),
    NavItem(icon: Icons.add, label: 'Create'),
    NavItem(icon: Icons.assessment, label: 'Summary'),
    NavItem(icon: Icons.person, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();

    _screens = [
      _buildNavigator(0, HomeScreen()),
      _buildNavigator(1, ActivityScreen()),
      _buildNavigator(2, SummaryScreen()),
      _buildNavigator(3, ProfileScreen()),
    ];

    _animationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildNavigator(int index, Widget screen) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => screen,
        );
      },
    );
  }

  void _onCreatePressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateEventScreen()),
    ).then((_) {
      setState(() {});
    });
  }

  void _onTabSelected(int index) {
    if (index == 2) {
      _onCreatePressed();
      return;
    }

    int screenIndex = index > 2 ? index - 1 : index;

    if (_selectedIndex == screenIndex) {
      _navigatorKeys[screenIndex].currentState
          ?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _selectedIndex = screenIndex;
        _animationController.reset();
        _animationController.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        onWillPop: () async {
          if (_navigatorKeys[_selectedIndex].currentState?.canPop() ?? false) {
            _navigatorKeys[_selectedIndex].currentState?.pop();
            return false;
          }
          return true;
        },
        child: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(top: 8, bottom: 8),
          child: Row(
            children: List.generate(
              _navItems.length,
              (index) => Expanded(
                child: index == 2
                    ? _buildCreateButton()
                    : _buildAnimatedNavItem(index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return GestureDetector(
      onTap: () => _onTabSelected(2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: Offset(0, -14),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF4CAF50).withOpacity(0.4),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(0, -10),
            child: Text(
              'Create',
              style: TextStyle(
                color: Color(0xFF388E3C),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedNavItem(int index) {
    int screenIndex = index > 2 ? index - 1 : index;
    final isSelected = index != 2 && _selectedIndex == screenIndex;
    final item = _navItems[index];

    return GestureDetector(
      onTap: () => _onTabSelected(index),
      child: Container(
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isSelected)
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(0xFF4CAF50).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  color: isSelected
                      ? Color(0xFF4CAF50)
                      : Colors.grey[600],
                  size: 24,
                ),
                SizedBox(height: 2),
                Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected
                        ? Color(0xFF4CAF50)
                        : Colors.grey[600],
                    fontSize: 11,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final String label;

  NavItem({required this.icon, required this.label});
}