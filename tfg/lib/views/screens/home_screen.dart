import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../widgets/custom_drawer.dart';
import 'explore_screen.dart';
import 'favorites_screen.dart';
import 'recommendations_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    ExploreScreen(),
    FavoritesScreen(),
    RecommendationsScreen(),
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }



  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const CustomDrawer(),

      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 0,
        automaticallyImplyLeading: false, 
        title: Row(
          children: [
            const Text(
              'WeatherWay',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(width: 8),
            if (user != null)
              Text(
                ' | ${user.displayName ?? ''}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          if (user != null)
            GestureDetector(
              onTap: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: CircleAvatar(
                  backgroundImage: NetworkImage(user.photoURL ?? ''),
                ),
              ),
            ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.grey[900],
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[500],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Explorar'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoritos'),
          BottomNavigationBarItem(icon: Icon(Icons.cloud), label: 'Clima'),
        ],
      ),
    );
  }
}
