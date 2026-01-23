import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'profile.dart';
import '/controllers/profileController.dart';
import 'chatList.dart';
import 'matchingScreen.dart';
import '/controllers/matchingController.dart';
import '/controllers/chatController.dart';
import 'locationSearch.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = <Widget>[
    const MatchingScreen(), //tampilanmatching
    const LocationSearchScreen(), // Pencarian berdasarkan lokasi
    const ChatListScreen(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MatchingController()),
        ChangeNotifierProvider(
          create: (_) => ChatController(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileController(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: Image.asset(
                  'asset/image/logoSHjpeg-removebg-preview.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              const Text('SeHati'),
            ],
          ),
          backgroundColor: Colors.green,
          actions: [
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          ],
        ),
        body: _widgetOptions.elementAt(_selectedIndex),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Matching',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on),
              label: 'Lokasi',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Pesan'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
