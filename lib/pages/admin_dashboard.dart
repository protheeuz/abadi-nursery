import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/booking_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../widgets/customcircular.dart';

class AdminDashboard extends StatefulWidget {
  final User user;

  const AdminDashboard({super.key, required this.user});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Future<List<Booking>>? approvedBookings;

  @override
  void initState() {
    super.initState();
    _refreshApprovedBookings();
  }

  void _refreshApprovedBookings() {
    setState(() {
      approvedBookings = ApiService.getApprovedBookingsAdmin();
    });
  }

  void _updateDeliveryStatus(int bookingId, String status) async {
    try {
      var response = await ApiService.updateDeliveryStatus(bookingId, status);
      // Log respons API
      print('Response from API: $response');

      // Verifikasi apakah status_pengiriman diperbarui dengan benar
      if (response['status_pengiriman'] == status) {
        setState(() {
          // Perbarui state lokal untuk mencerminkan status baru
          approvedBookings = approvedBookings!.then((bookings) {
            final updatedBookings = bookings.map((booking) {
              if (booking.id == bookingId) {
                return Booking(
                  id: booking.id,
                  userId: booking.userId,
                  namaLengkap: booking.namaLengkap,
                  startDate: booking.startDate,
                  endDate: booking.endDate,
                  proofOfPayment: booking.proofOfPayment,
                  status: booking.status,
                  totalSewa: booking.totalSewa,
                  needDelivery: booking.needDelivery,
                  address: booking.address,
                  bookingDetails: booking.bookingDetails,
                  statusPengiriman: status, // Perbarui status pengiriman
                );
              }
              return booking;
            }).toList();

            return updatedBookings;
          });
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Status pengiriman diperbarui menjadi $status')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui status pengiriman')),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Booking>>(
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
                  return const Center(child: Text('No approved bookings'));
                } else {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final booking = snapshot.data![index];

                      // Ensure that the initial value of DropdownButton is valid
                      final List<String> deliveryStatusOptions = [
                        'Belum dikirim',
                        'Sedang diproses',
                        'Sedang dikemas',
                        'Sedang dikirim',
                        'Sudah sampai'
                      ];
                      String? validStatus = deliveryStatusOptions
                              .contains(booking.statusPengiriman)
                          ? booking.statusPengiriman
                          : deliveryStatusOptions[0];

                      return Card(
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
                                'Booking ID: ${booking.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                'Nama Penyewa: ${booking.namaLengkap}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                'Total Harga: Rp ${formatCurrency(booking.totalSewa)}',
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
                              const SizedBox(height: 8.0),
                              if (booking.needDelivery) ...[
                                Text(
                                  'Alamat: ${booking.address}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  'Status Pengiriman: $validStatus',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                DropdownButton<String>(
                                  value: validStatus,
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      _updateDeliveryStatus(
                                          booking.id, newValue);
                                    }
                                  },
                                  items: deliveryStatusOptions
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
