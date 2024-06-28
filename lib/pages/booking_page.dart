import 'package:abadinursery/models/product_model.dart';
import 'package:abadinursery/models/user_model.dart';
import 'package:abadinursery/services/api_service.dart';
import 'package:abadinursery/widgets/ios_styled_notification.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:overlay_support/overlay_support.dart';

import 'penyewa_dashboard.dart';

class BookingPage extends StatefulWidget {
  final Map<Product, int> cartItems;
  final User user;
  final Function(User) onUserUpdated;

  const BookingPage(
      {super.key,
      required this.cartItems,
      required this.user,
      required this.onUserUpdated});

  @override
  BookingPageState createState() => BookingPageState();
}

class BookingPageState extends State<BookingPage> {
  late Map<Product, int> _cartItems;
  DateTime? _startDate;
  DateTime? _endDate;
  File? _proofOfPayment;
  final ImagePicker picker = ImagePicker();
  final bool _needDelivery = false;
  double _totalPrice = 0.0; // variabel ini untuk menyimpan total harga

  @override
  void initState() {
    super.initState();
    _cartItems = Map.from(widget.cartItems);
  }

  void _incrementQuantity(Product product) {
    setState(() {
      _cartItems[product] = (_cartItems[product] ?? 0) + 1;
    });
  }

  void _decrementQuantity(Product product) {
    setState(() {
      if (_cartItems[product]! > 1) {
        _cartItems[product] = _cartItems[product]! - 1;
      } else {
        _cartItems.remove(product);
      }
    });
  }

  void _removeItem(Product product) {
    setState(() {
      _cartItems.remove(product);
    });
  }

  Future<void> _pickProofOfPayment() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _proofOfPayment = File(pickedFile.path);
      }
    });
  }

  Future<void> _submitBooking(bool needDelivery) async {
    try {
      if (_proofOfPayment == null || _startDate == null || _endDate == null) {
        throw Exception('Data belum lengkap');
      }

      if (_totalPrice <= 0) {
        throw Exception('Total belanja harus lebih dari 0');
      }

      print('Start Date: $_startDate');
      print('End Date: $_endDate');
      print('Proof of Payment: $_proofOfPayment');
      print('Need Delivery: $needDelivery');
      print('Total Sewa: $_totalPrice');

      _cartItems.forEach((product, quantity) {
        print('Product ID: ${product.id}, Quantity: $quantity');
      });

      await ApiService.submitBooking(_cartItems, _startDate!, _endDate!,
          _proofOfPayment!, needDelivery, _totalPrice);
      _showSuccessDialog();
    } catch (e) {
      print('Failed to submit booking: $e');
      showSimpleNotification(
        Text(
          e.toString(),
          style: const TextStyle(color: Colors.white),
        ),
        background: Colors.red,
        leading: const Icon(
          Icons.warning,
          color: Colors.white,
        ),
        autoDismiss: true,
        slideDismissDirection: DismissDirection.up,
        contentPadding: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      );
      throw Exception('Failed to submit booking');
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  double _calculateTotalPrice() {
    double total = 0.0;
    if (_startDate != null && _endDate != null) {
      // Tambahkan 1 hari ke durasi untuk menyertakan hari akhir
      int days = _endDate!.difference(_startDate!).inDays + 1;
      _cartItems.forEach((product, quantity) {
        total += product.hargaSewa * quantity * days;
      });
    }
    return total;
  }

  void _updateTotalPrice() {
    if (_startDate != null && _endDate != null) {
      final days = _endDate!.difference(_startDate!).inDays + 1;
      _totalPrice = _cartItems.entries
          .map((entry) => entry.key.hargaSewa * entry.value * days)
          .fold(0.0, (sum, price) => sum + price);
      if (_needDelivery) {
        _totalPrice += 5000; // Tambahkan biaya pengantaran
      }
    } else {
      _totalPrice = 0.0;
    }
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Sukses'),
          content: const Text(
              'Berhasil melakukan penyewaan, tunggu untuk konfirmasi Admin'),
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PenyewaDashboard(
                        user: widget.user, onUserUpdated: widget.onUserUpdated),
                  ),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    Navigator.pop(
        context, _cartItems); // Kirimkan data keranjang yang diperbarui
    return false;
  }

  String formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0', 'id');
    return formatter.format(amount);
  }

  void _showIOSStyledNotification(BuildContext context, String message) {
    showOverlayNotification(
      (context) {
        return IOSStyledNotification(
          message: message,
          icon: Icons.warning,
          backgroundColor: Colors.grey, // Warna abu-abu untuk notifikasi
        );
      },
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Keranjang Anda',
              style: TextStyle(
                fontSize: 17,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              )),
          backgroundColor: Colors.green[300],
          elevation: 10,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, _cartItems);
            },
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  itemCount: _cartItems.length,
                  itemBuilder: (context, index) {
                    Product product = _cartItems.keys.elementAt(index);
                    int quantity = _cartItems.values.elementAt(index);
                    return Card(
                      elevation: 5,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: Image.network(
                                product.fotoTanaman,
                                width: 85,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (BuildContext context,
                                    Object exception, StackTrace? stackTrace) {
                                  return const Icon(Icons.error);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.namaTanaman,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[200],
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      product.jenisTanaman,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Poppins',
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green[200],
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      'Stok: ${product.jumlahStok}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Poppins',
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red[200],
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      'Harga: Rp ${formatCurrency(product.hargaSewa)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () =>
                                          _decrementQuantity(product),
                                      icon: Icon(Icons.remove_circle,
                                          color: Colors.grey[500]),
                                    ),
                                    Text(
                                      '$quantity',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _incrementQuantity(product),
                                      icon: Icon(Icons.add_circle,
                                          color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () => _removeItem(product),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[500],
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: const Text(
                                      'Hapus',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Poppins',
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.green[50],
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Belanja:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        'Rp ${formatCurrency(_calculateTotalPrice())}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _showConfirmationBottomSheet(context),
                    child: const Text(
                      'Konfirmasi Pemesanan',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationBottomSheet(BuildContext context) {
    if (_cartItems.isEmpty) {
      _showIOSStyledNotification(
          context, 'Anda belum memilih item sama sekali');
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Tanggal Mulai'),
                    trailing: Text(_startDate != null
                        ? DateFormat('dd/MM/yyyy').format(_startDate!)
                        : 'Pilih'),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null) {
                        Navigator.pop(context);
                        setState(() {
                          _startDate = picked;
                          if (_endDate != null &&
                              _endDate!.isBefore(_startDate!)) {
                            _endDate = null;
                          }
                          _updateTotalPrice();
                        });
                        _showConfirmationBottomSheet(context);
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('Tanggal Selesai'),
                    trailing: Text(_endDate != null
                        ? DateFormat('dd/MM/yyyy').format(_endDate!)
                        : 'Pilih'),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: _startDate ?? DateTime.now(),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null) {
                        Navigator.pop(context);
                        setState(() {
                          _endDate = picked;
                          _updateTotalPrice();
                        });
                        _showConfirmationBottomSheet(context);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Total Harga: Rp ${formatCurrency(_totalPrice)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Menutup modal bottom sheet
                      _showPaymentConfirmationDialog(); // Menampilkan dialog konfirmasi pembayaran
                    },
                    child: const Text(
                      'Konfirmasi Pembayaran',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPaymentConfirmationDialog() {
    if (_startDate == null || _endDate == null) {
      _showIOSStyledNotification(
          context, 'Anda belum memilih rentang tanggal penyewaan');
      return;
    }
    bool needDelivery = false;
    bool showDeliveryWarning = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
                side: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Konfirmasi Pembayaran',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 16, thickness: 1, color: Colors.grey),
                    Text(
                      'Pesanan untuk, ${widget.user.namaLengkap}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._cartItems.entries.map((entry) {
                      final product = entry.key;
                      final quantity = entry.value;
                      final totalPricePerProduct = product.hargaSewa * quantity;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          '$quantity x ${product.namaTanaman}: Rp ${formatCurrency(totalPricePerProduct)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    Text(
                      'Total Harga: Rp ${formatCurrency(_totalPrice)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Lakukan transfer 1x24 jam ke rekening:\n0444 0104 1574 505 \n BRI \n Hamdani Ikhwan',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Butuh diantar?',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        FlutterSwitch(
                          width: 55.0,
                          height: 35.0,
                          toggleSize: 25.0,
                          value: needDelivery,
                          borderRadius: 30.0,
                          padding: 4.0,
                          activeToggleColor: Colors.white,
                          inactiveToggleColor: Colors.white,
                          activeSwitchBorder: Border.all(
                            color: Colors.green,
                            width: 2.0,
                          ),
                          inactiveSwitchBorder: Border.all(
                            color: Colors.grey,
                            width: 2.0,
                          ),
                          activeColor: Colors.green,
                          inactiveColor: Colors.grey,
                          activeIcon: const Icon(
                            Icons.directions_bike_rounded,
                            color: Colors.green,
                          ),
                          inactiveIcon: const Icon(
                            Icons.circle,
                            color: Colors.grey,
                          ),
                          onToggle: (val) {
                            setState(() {
                              needDelivery = val;
                              showDeliveryWarning = val;
                              if (val) {
                                _totalPrice += 5000;
                              } else {
                                _totalPrice -= 5000;
                              }
                            });
                          },
                        )
                      ],
                    ),
                    if (showDeliveryWarning)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          '! Biaya Rp. 5.000 untuk menggunakan opsi pengantaran\n *Hanya menerima pengiriman Jabodetabek',
                          style: TextStyle(
                            fontSize: 9,
                            fontFamily: 'Poppins',
                            color: Colors.red,
                          ),
                        ),
                      ),
                    if (!needDelivery)
                      const Center(
                        child: Text(
                          '! Maks. 3 Hari Pengambilan Tanaman',
                          style: TextStyle(
                            fontSize: 9,
                            fontFamily: 'Poppins',
                            color: Colors.red,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        await _pickProofOfPayment();
                        setState(() {});
                      },
                      child: const Text('Upload Bukti Transfer'),
                    ),
                    if (_proofOfPayment != null) ...[
                      const SizedBox(height: 8),
                      const Text('Bukti transfer berhasil diunggah.'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          await _submitBooking(needDelivery);
                          Navigator.pop(context);
                          _showSuccessDialog();
                        },
                        child: const Text('Konfirmasi Pembayaran'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}