import 'package:abadinursery/models/user_model.dart';
import 'package:abadinursery/pages/penyewa_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:abadinursery/pages/admin_dashboard.dart';

class HomePage extends StatelessWidget {
  final User user;
  final Function(User) onUserUpdated;

  const HomePage({super.key, required this.user, required this.onUserUpdated});

  @override
  Widget build(BuildContext context) {
    // Langsung redirect ke PenyewaDashboard jika user.role bukan 'admin'
    if (user.role != 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PenyewaDashboard(user: user, onUserUpdated: onUserUpdated)),
        );
      });
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Selamat Datang, ${user.namaLengkap}'),
            const SizedBox(height: 20),
            if (user.role == 'admin') ...[
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdminDashboard(user: user)),
                  );
                },
                child: const Text('Admin Dashboard'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
