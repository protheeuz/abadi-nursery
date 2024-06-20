class Booking {
  final int id;
  final int userId;
  final String namaLengkap;
  final String startDate;
  final String endDate;
  final String proofOfPayment;
  final String status;
  final double totalSewa;
  final bool needDelivery;
  final String? address;
  final List<BookingDetail> bookingDetails;
  final String statusPengiriman;

  Booking({
    required this.id,
    required this.userId,
    required this.namaLengkap,
    required this.startDate,
    required this.endDate,
    required this.proofOfPayment,
    required this.status,
    required this.totalSewa,
    required this.needDelivery,
    required this.address,
    required this.bookingDetails,
    required this.statusPengiriman,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    print('Booking from JSON: $json'); // Debugging
    double totalSewa;
    if (json['total_sewa'] is String) {
      totalSewa = double.parse(json['total_sewa']);
    } else {
      totalSewa = json['total_sewa'].toDouble();
    }

    return Booking(
      id: json['id'],
      userId: json['user_id'],
      namaLengkap: json['nama_lengkap'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      proofOfPayment: json['proof_of_payment'],
      status: json['status'],
      totalSewa: totalSewa,
      needDelivery: json['need_delivery'] == 1,
      address: json['address'],
      bookingDetails: (json['booking_details'] as List<dynamic>)
          .map((detailJson) => BookingDetail.fromJson(detailJson))
          .toList(),
      statusPengiriman: json['status_pengiriman'] ?? 'Belum dikirim',
    );
  }
}

class BookingDetail {
  final int id;
  final int bookingId;
  final int plantId;
  final String namaTanaman;
  final String jenisTanaman;
  final double hargaSatuan;
  final int quantity;
  final double totalSewa;

  BookingDetail({
    required this.id,
    required this.bookingId,
    required this.plantId,
    required this.namaTanaman,
    required this.jenisTanaman,
    required this.hargaSatuan,
    required this.quantity,
    required this.totalSewa,
  });

  factory BookingDetail.fromJson(Map<String, dynamic> json) {
    print('BookingDetail from JSON: $json');

    double hargaSatuan;
    if (json['harga_satuan'] is String) {
      hargaSatuan = double.parse(json['harga_satuan']);
    } else {
      hargaSatuan = json['harga_satuan'].toDouble();
    }

    double totalSewa;
    if (json['total_sewa'] is String) {
      totalSewa = double.parse(json['total_sewa']);
    } else {
      totalSewa = json['total_sewa'].toDouble();
    }

    return BookingDetail(
      id: json['id'],
      bookingId: json['booking_id'],
      plantId: json['plant_id'],
      namaTanaman: json['nama_tanaman'],
      jenisTanaman: json['jenis_tanaman'],
      hargaSatuan: hargaSatuan,
      quantity: json['quantity'],
      totalSewa: totalSewa,
    );
  }
}
