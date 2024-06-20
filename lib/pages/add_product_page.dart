import 'dart:io';
import 'package:abadinursery/widgets/customcircular.dart';
import 'package:abadinursery/widgets/ios_styled_notification.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:abadinursery/services/api_service.dart';
import 'package:overlay_support/overlay_support.dart';

import '../main.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  File? _image;
  final picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> addProduct() async {
    if (_image == null) {
      showOverlayNotification(
        (context) => const IOSStyledNotification(
          message: "Harap menambahkan foto tanaman",
          icon: Icons.warning,
          backgroundColor: Colors.red,
        ),
        duration: const Duration(seconds: 3),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.addProduct(
        _nameController.text,
        _typeController.text,
        double.parse(_priceController.text),
        _image!,
        int.parse(_stockController.text),
      );

      setState(() {
        _isLoading = false;
      });

      if (response['status'] == 'success') {
        showOverlayNotification(
          (context) => const IOSStyledNotification(
            message: "Produk berhasil ditambahkan",
            icon: Icons.check_circle,
            backgroundColor: Colors.green,
          ),
          duration: const Duration(seconds: 3),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Gagal menambahkan produk: ${response['message']}')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saat menambahkan produk')),
      );
      print('Error during addProduct: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tambah Produk',
          style: TextStyle(
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 165, 255, 168),
      ),
      body: _isLoading
          ? const Center(
              child: CustomCircularProgressIndicator(
                imagePath: 'assets/images/logo/circularcustom.png',
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  GestureDetector(
                    onTap: _getImage,
                    child: Center(
                      child: CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.grey[200],
                        backgroundImage:
                            _image != null ? FileImage(_image!) : null,
                        child: _image == null
                            ? const Icon(Icons.camera_alt,
                                size: 40, color: Colors.grey)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Tanaman',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      prefixIcon: const Icon(Icons.local_florist),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _typeController,
                    decoration: InputDecoration(
                      labelText: 'Jenis Tanaman',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      prefixIcon: const Icon(Icons.category),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Harga',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _stockController,
                    decoration: InputDecoration(
                      labelText: 'Jumlah Stok',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      prefixIcon: const Icon(Icons.store),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: addProduct,
                    child: const Text('Tambahkan Produk'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
