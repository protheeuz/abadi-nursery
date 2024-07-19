import 'package:abadinursery/widgets/customcircular.dart';
import 'package:flutter/material.dart';
import 'package:abadinursery/services/api_service.dart';
import 'package:abadinursery/models/booking_model.dart';
import 'package:intl/intl.dart';

class BookingListPage extends StatefulWidget {
  const BookingListPage({super.key});

  @override
  _BookingListPageState createState() => _BookingListPageState();
}

class _BookingListPageState extends State<BookingListPage> {
  Future<List<Booking>>? approvedBookings;

  @override
  void initState() {
    super.initState();
    _fetchApprovedBookings();
  }

  void _fetchApprovedBookings() {
    setState(() {
      approvedBookings = ApiService.getApprovedBookingsForUser();
    });
  }

  String formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0', 'id');
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 10,
        title: const Text('Detail Status Booking',
            style: TextStyle(
                fontFamily: 'Poppins', fontSize: 16, color: Colors.black)),
        backgroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Booking>>(
        future: approvedBookings,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CustomCircularProgressIndicator(
              imagePath: 'assets/images/logo/circularcustom.png',
            ));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('Belum ada booking yang diapprove'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final booking = snapshot.data![index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Text(
                      'Booking ID: ${booking.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Nama Penyewa:', booking.namaLengkap),
                        _buildDetailRow('Total Harga:',
                            'Rp ${formatCurrency(booking.totalSewa)}'),
                        _buildDetailRow('Status:', booking.status),
                        if (booking.needDelivery)
                          _buildDetailRow(
                              'Alamat:', booking.address ?? 'Tidak ada alamat'),
                        if (booking.needDelivery)
                          _buildDetailRow(
                              'Status Pengiriman:', booking.statusPengiriman),
                      ],
                    ),
                    onTap: () {
                      _showBookingDetailsDialog(context, booking);
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  void _showBookingDetailsDialog(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Detail Pemesanan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Nama Penyewa:', booking.namaLengkap),
                _buildDetailRow(
                    'Total Harga:', 'Rp ${formatCurrency(booking.totalSewa)}'),
                _buildDetailRow('Status:', booking.status),
                if (booking.needDelivery)
                  _buildDetailRow(
                      'Alamat:', booking.address ?? 'Tidak ada alamat'),
                if (booking.needDelivery)
                  _buildDetailRow(
                      'Status Pengiriman:', booking.statusPengiriman),
                if (booking.needDelivery) ...[
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _buildTimeline(booking),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildTimeline(Booking booking) {
    List<Map<String, String>> statuses = [
      {'status': 'Belum dikirim', 'description': 'Pesanan belum dikirim.'},
      {'status': 'Sedang diproses', 'description': 'Pesanan sedang diproses.'},
      {'status': 'Sedang dikemas', 'description': 'Pesanan sedang dikemas.'},
      {'status': 'Sedang dikirim', 'description': 'Pesanan sedang dikirim.'},
      {
        'status': 'Sudah sampai',
        'description': 'Pesanan sudah sampai di tujuan.'
      },
    ];

    return statuses.map((status) {
      bool isActive = booking.statusPengiriman == status['status'];
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: isActive ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              status['description']!,
              style: TextStyle(
                fontSize: 14,
                color: isActive ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            value,
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }
}
