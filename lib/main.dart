import 'package:abadinursery/models/user_model.dart';
import 'package:abadinursery/pages/admin_booking_page.dart';
import 'package:abadinursery/pages/admin_dashboard.dart';
import 'package:abadinursery/pages/add_product_page.dart';
import 'package:abadinursery/pages/profile_page.dart';
import 'package:abadinursery/pages/penyewa_dashboard.dart';
import 'package:abadinursery/pages/login_page.dart';
import 'package:abadinursery/services/api_service.dart';
import 'package:abadinursery/widgets/customcircular.dart';
import 'package:abadinursery/widgets/navbar.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/booking_list.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Abadi Green Nursery',
        theme: ThemeData(
          primarySwatch: Colors.green,
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final User? user;

  const MainScreen({super.key, this.user});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  User? user;
  List<Widget> _pages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    print('Token retrieved: $token'); // Debugging

    if (token == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      return;
    }

    try {
      final fetchedUser = await ApiService.getUserData(token);
      setState(() {
        user = fetchedUser;
        _initializePages();
        _isLoading = false;
      });
      print('User data set: ${user!.username}, ${user!.role}');
    } catch (e) {
      print('Error fetching user data: $e');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  void _initializePages() {
    if (user!.role == 'admin') {
      _pages = [
        AdminDashboard(user: user!),
        const AdminBookingPage(),
        const AddProductPage(),
        ProfilePage(user: user!, onUserUpdated: _updateUser),
      ];
    } else {
      _pages = [
        PenyewaDashboard(user: user!, onUserUpdated: _updateUser),
        const BookingListPage(),
        ProfilePage(user: user!, onUserUpdated: _updateUser),
      ];
    }
    print('Pages initialized for role: ${user!.role}');
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onLogout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    // Reset state and navigate to login page
    setState(() {
      user = null;
      _selectedIndex = 0;
      _pages = []; // Reset pages
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _updateUser(User updatedUser) {
    setState(() {
      user = updatedUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CustomCircularProgressIndicator(
              imagePath: 'assets/images/logo/circularcustom.png',
            ))
          : _pages.isNotEmpty // Check if pages are initialized
              ? _pages[_selectedIndex]
              : const SizedBox(), // Show an empty container if pages are not initialized
      bottomNavigationBar: _isLoading
          ? null
          : BottomNavBar(
              currentIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
              isAdmin: user != null && user!.role == 'admin',
              onLogout: _onLogout,
            ),
    );
  }
}