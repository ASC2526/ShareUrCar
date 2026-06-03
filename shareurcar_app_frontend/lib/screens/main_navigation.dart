import 'package:flutter/material.dart';
import 'package:shareurcar_app_frontend/screens/chats/chat_screens.dart';
import 'package:shareurcar_app_frontend/screens/payments/payments_screen.dart';
import 'package:shareurcar_app_frontend/screens/profile/profile_screen.dart';
import 'package:shareurcar_app_frontend/services/api_service.dart';
import '../app_theme.dart';
import 'home/home_screen.dart';

class MainNavigation extends StatefulWidget {
  final Map user;
  const MainNavigation({super.key, required this.user});

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;
  late Map _user;
  int _chatsRefresh = 0;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _refreshUser();
  }

  Future<void> _refreshUser() async {
    try {
      final updated = await ApiService.getUserById(_user['idUser']);
      if (mounted) setState(() => _user = updated);
    } catch (e) {
      debugPrint("Error refrescando usuario: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(user: _user),
      ChatsScreen(user: _user, refreshTrigger: _chatsRefresh),
      PaymentsScreen(user: _user),
      ProfileScreen(user: _user, onUserUpdated: _refreshUser),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) async {
          if (i == 1) setState(() => _chatsRefresh++);
          await _refreshUser();
          if (mounted) setState(() => _index = i);
        },
        selectedItemColor: kPrimary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Viajes"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chats"),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: "Pagos"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }
}
