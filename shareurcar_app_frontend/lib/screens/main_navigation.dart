import 'package:flutter/material.dart';
import 'package:shareurcar_app_frontend/screens/chat_screens.dart';
import 'package:shareurcar_app_frontend/screens/profile_screen.dart';
import 'home_screen.dart';

class MainNavigation extends StatefulWidget {
  final Map user;

  const MainNavigation({super.key, required this.user});

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(user: widget.user),
      ChatsScreen(user: widget.user),
      Center(child: Text("Pagos")),
      ProfileScreen(user: widget.user),
    ];

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Viajes"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chats"),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: "Pagos"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }
}
