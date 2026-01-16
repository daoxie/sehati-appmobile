import 'package:flutter/material.dart';
import 'profile.dart';
import '../controllers/profileController.dart';
import 'chatList.dart';

class HomePage extends StatefulWidget {
  final String name;
  const HomePage({super.key, required this.name});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late ProfileController _profileController; // Declare the controller

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _profileController = ProfileController(); // Initialize the controller
    // Initialize with dummy data for now
    _profileController.nikController.text = '1234567890123456';
    _profileController.nameController.text = widget.name;
    _profileController.dobController.text = '2000-01-01';
    _profileController.addressController.text = '123 Main St';
    _profileController.gender = 'Laki-laki';
    _widgetOptions = <Widget>[
      const Center(
        child: Text('Index 0: Matching'),
      ),
      const ChatListScreen(),
      ProfilePage(
          name: widget.name,
          controller: _profileController), // Pass the controller
    ];
  }

  @override
  void dispose() {
    _profileController.dispose(); // Dispose the controller
    super.dispose();
  }

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