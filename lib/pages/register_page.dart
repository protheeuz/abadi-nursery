import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:abadinursery/services/api_service.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _namaLengkapController =
      TextEditingController(); // Controller untuk Nama Lengkap
  bool _isLoading = false;
  bool _passwordVisible = false; // Tambahkan ini

  void _register() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    String namaLengkap = _namaLengkapController.text.trim();

    if (username.isEmpty || password.isEmpty || namaLengkap.isEmpty) {
      _showCupertinoDialog("Ups", "Semua kolom harus diisi.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response =
          await ApiService.register(username, password, namaLengkap); // Tambahkan 'penyewa'

      if (!mounted) return; // Pastikan widget masih terpasang

      setState(() {
        _isLoading = false;
      });

      _showCupertinoDialog("Informasi", response['message']);

      if (response.containsKey('success') && response['success'] == true) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (!mounted) return; // Pastikan widget masih terpasang

      setState(() {
        _isLoading = false;
      });
      _showCupertinoDialog(
          "Error", "Terjadi kesalahan saat mendaftar. Silakan coba lagi.");
    }
  }

  void _showCupertinoDialog(String title, String message) {
    if (!mounted) return; // Pastikan widget masih terpasang
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 30,
                ),
                const Text(
                  "Daftarkan Akun",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                ),
                Image.asset(
                  "assets/images/register.jpg",
                  height: 250,
                  width: double.infinity,
                ),
                const Text(
                  "Dapatkan akses mendaftar dari sini",
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(
                  height: 20,
                ),
                const Text(
                  "Nama Lengkap",
                  style: TextStyle(fontSize: 12),
                ),
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black12,
                      ),
                      color: Colors.grey[100],
                      borderRadius:
                          const BorderRadius.all(Radius.circular(10))),
                  child: TextField(
                    controller: _namaLengkapController,
                    decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Masukkan Nama Lengkap',
                        contentPadding: EdgeInsets.all(10)),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const Text(
                  "Username",
                  style: TextStyle(fontSize: 12),
                ),
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black12,
                      ),
                      color: Colors.grey[100],
                      borderRadius:
                          const BorderRadius.all(Radius.circular(10))),
                  child: TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Masukkan Username',
                        contentPadding: EdgeInsets.all(10)),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const Text(
                  "Kata Sandi",
                  style: TextStyle(fontSize: 12),
                ),
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black12,
                      ),
                      color: Colors.grey[100],
                      borderRadius:
                          const BorderRadius.all(Radius.circular(10))),
                  child: TextField(
                    controller: _passwordController,
                    obscureText:
                        !_passwordVisible, // Use the updated _passwordVisible value here
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Masukkan Password',
                      contentPadding: const EdgeInsets.all(10),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                MaterialButton(
                  color: Theme.of(context).primaryColor,
                  height: 25,
                  minWidth: double.maxFinite,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                      side: BorderSide(color: Theme.of(context).primaryColor)),
                  onPressed: _isLoading ? null : _register,
                  child: const Text(
                    "Daftar Akun",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Sudah punya akun? ",
                      style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 14,
                          color: Colors.grey),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginPage()));
                      },
                      child: Text(
                        "Masuk ",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Theme.of(context).primaryColor),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}