import 'package:flutter/material.dart';
import 'profile.dart'; // Import the ProfilePage

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // The list of widgets for each tab
  static final List<Widget> _widgetOptions = <Widget>[
    const Center(
      child: Text('Index 0: Matching'),
    ),
    const Center(
      child: Text('Index 1: Pesan'),
    ),
    const ProfilePage(), // Display the ProfilePage when 'Profile' tab is selected
  ];

  void _onItemTapped(int index) {
    // Simply update the index to change the displayed widget
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SeHati'),
        backgroundColor: Colors.green,
        // The AppBar icon is removed to avoid confusion with the BottomNavigationBar
      ),
      // The body now correctly displays the widget based on the selected index
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Matching',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Pesan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}
