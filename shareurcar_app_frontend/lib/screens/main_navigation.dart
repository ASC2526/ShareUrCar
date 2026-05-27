import 'package:flutter/material.dart';
import 'package:shareurcar_app_frontend/screens/chat_screens.dart';
import 'package:shareurcar_app_frontend/screens/payments_screen.dart';
import 'package:shareurcar_app_frontend/screens/profile_screen.dart';
import 'package:shareurcar_app_frontend/services/api_service.dart';
import 'home_screen.dart';

class MainNavigation extends StatefulWidget {
  final Map user;

  const MainNavigation({super.key, required this.user});

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;
  late Map currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
    _refreshUser();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(user: currentUser),
      ChatsScreen(user: currentUser),
      PaymentsScreen(user: currentUser),
      ProfileScreen(user: currentUser),
    ];

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) async {
          await _refreshUser();

          setState(() {
            currentIndex = index;
          });
        },
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

  Future<void> _refreshUser() async {
    try {
      final updatedUser = await ApiService.getUserById(currentUser['idUser']);

      if (mounted) {
        setState(() {
          currentUser = updatedUser;
        });
      }
    } catch (e) {
      print("Error refrescando usuario: $e");
    }
  }
}
