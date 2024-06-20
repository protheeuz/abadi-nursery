import 'package:abadinursery/widgets/customcircular.dart';
import 'package:flutter/material.dart';
import 'package:abadinursery/models/booking_model.dart';
import 'package:abadinursery/services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class AdminBookingPage extends StatefulWidget {
  const AdminBookingPage({super.key});

  @override
  _AdminBookingPageState createState() => _AdminBookingPageState();
}

class _AdminBookingPageState extends State<AdminBookingPage> {
  List<Booking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  void _fetchBookings() async {
    try {
      List<Booking> bookings = await ApiService.getPendingBookings();
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      print('Failed to load bookings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateBookingStatus(int bookingId, String status) async {
    try {
      await ApiService.updateBookingStatus(bookingId, status);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status pemesanan diperbarui menjadi $status')),
      );

      setState(() {
        _bookings.removeWhere((booking) => booking.id == bookingId);
      });

      _fetchBookings();
    } catch (e) {
      print('Gagal memperbarui status pemesanan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memperbarui status pemesanan')),
      );
    }
  }

  void _updateDeliveryStatus(int bookingId, String status) async {
    try {
      await ApiService.updateDeliveryStatus(bookingId, status);
      _fetchBookings();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status pengiriman diperbarui menjadi $status')),
      );
    } catch (e) {
      print('Failed to update delivery status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status pengiriman: $e')),
      );
    }
  }

  String formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0', 'id');
    return formatter.format(amount);
  }

  void _showBookingDetailsDialog(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final List<String> deliveryStatuses = [
          'Belum dikirim',
          'Sedang diproses',
          'Sedang dikemas',
          'Sedang dikirim',
          'Sudah sampai'
        ];

        String deliveryStatus =
            deliveryStatuses.contains(booking.statusPengiriman)
                ? booking.statusPengiriman
                : 'Belum dikirim';

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
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
                const SizedBox(height: 8.0),
                _buildDetailRow('Status:', booking.status),
                const SizedBox(height: 8.0),
                _buildDetailRow(
                    'Total Harga:', formatCurrency(booking.totalSewa)),
                const SizedBox(height: 8.0),
                if (booking.address != null)
                  _buildDetailRow(
                      'Alamat:', booking.address ?? 'Tidak diantar'),
                const SizedBox(height: 8.0),
                const Text(
                  'Bukti Pembayaran:',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                TextButton(
                  onPressed: () {
                    _showPaymentProof(context, booking.proofOfPayment);
                  },
                  child: const Text('Lihat Bukti Pembayaran'),
                ),
                const SizedBox(height: 8.0),
                const Text(
                  'Detail Pemesanan:',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                ...booking.bookingDetails.map((detail) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      '${detail.quantity}x ${detail.namaTanaman} (${detail.jenisTanaman}) - Rp ${detail.totalSewa}',
                      style: const TextStyle(fontFamily: 'Poppins'),
                    ),
                  );
                }),
                if (booking.needDelivery)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8.0),
                      const Text(
                        'Status Pengiriman:',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      DropdownButton<String>(
                        value: deliveryStatus,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            _updateDeliveryStatus(booking.id, newValue);
                          }
                        },
                        items: deliveryStatuses
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _updateBookingStatus(booking.id, 'approved');
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    textStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Terima'),
                ),
                const SizedBox(width: 8), // Beri jarak antara tombol
                ElevatedButton(
                  onPressed: () {
                    _updateBookingStatus(booking.id, 'rejected');
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                    textStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Tolak'),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
                textStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                ),
              ),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentProof(BuildContext context, String proofOfPayment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: CachedNetworkImage(
            imageUrl: 'http://192.168.20.136:5000/bookings/$proofOfPayment',
            placeholder: (context, url) =>
                const CustomCircularProgressIndicator(
              imagePath: 'assets/images/logo/circularcustom.png',
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daftar Pemesanan',
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
            ))
          : ListView.builder(
              itemCount: _bookings.length,
              itemBuilder: (context, index) {
                final booking = _bookings[index];
                return GestureDetector(
                  onTap: () => _showBookingDetailsDialog(context, booking),
                  child: Card(
                    margin: const EdgeInsets.all(8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nama Penyewa: ${booking.namaLengkap}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            'Total Harga: Rp ${booking.totalSewa}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            'Status: ${booking.status}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                          ),
                          if (booking.needDelivery)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8.0),
                                Text(
                                  'Alamat: ${booking.address}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  'Status Pengiriman: ${booking.statusPengiriman}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
