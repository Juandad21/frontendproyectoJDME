import 'package:flutter/material.dart';
import 'pages/tablero_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Girardot Suena a Arte',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'Macondo',
      ),
      home: const MainControlPage(),
    );
  }
}

class MainControlPage extends StatefulWidget {
  const MainControlPage({super.key});

  @override
  State<MainControlPage> createState() => _MainControlPageState();
}

class _MainControlPageState extends State<MainControlPage> {
  bool _isLoggedIn = false;
  bool _isAdmin = false;
  String? _token;

  void _toggleLogin(bool status, {String? token, bool ? isAdmin}) {
    setState(() {
      _isLoggedIn = status;
      _token = token;
      _isAdmin = isAdmin ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TableroInteractivoPage(
      isLoggedIn: _isLoggedIn,
      isAdmin: _isAdmin,
      token: _token,
      onLoginChanged: _toggleLogin,
    );
  }
}