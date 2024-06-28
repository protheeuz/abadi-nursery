import 'dart:convert';
import 'dart:io';
import 'package:abadinursery/models/booking_model.dart';
import 'package:abadinursery/models/product_model.dart';
import 'package:abadinursery/models/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'session_manager.dart';

class ApiService {
  static const String baseUrl = 'https://abadinursery.pythonanywhere.com';

  static Future<void> submitBooking(
      Map<Product, int> cartItems,
      DateTime startDate,
      DateTime endDate,
      File proofOfPayment,
      bool needDelivery,
      double totalSewa) async {
    final token = await SessionManager.getAccessToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    var uri = Uri.parse('$baseUrl/bookings/book');
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['start_date'] = startDate.toIso8601String()
      ..fields['end_date'] = endDate.toIso8601String()
      ..fields['need_delivery'] = needDelivery.toString()
      ..fields['total_sewa'] = totalSewa.toString()
      ..files.add(await http.MultipartFile.fromPath(
        'proof_of_payment',
        proofOfPayment.path,
        filename: path.basename(proofOfPayment.path),
      ));

    int i = 0;
    cartItems.forEach((product, quantity) {
      final cartItemField = 'cart_items_$i';
      final cartItemValue =
          '${product.id},${product.namaTanaman},${product.jenisTanaman},${product.hargaSewa},$quantity,${product.hargaSewa * quantity}';
      print('$cartItemField: $cartItemValue'); // Log untuk debug
      request.fields[cartItemField] = cartItemValue;
      i++;
    });

    var response = await request.send();
    if (response.statusCode == 201) {
      print('Booking created successfully');
    } else if (response.statusCode == 401) {
      print('Unauthorized: Invalid token');
      throw Exception('Failed to submit booking: Unauthorized');
    } else {
      print('Failed to submit booking: ${response.statusCode}');
      throw Exception('Failed to submit booking');
    }
  }

  static Future<List<Booking>> getApprovedBookings(int userId) async {
    final token = await SessionManager.getAccessToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/bookings/approved/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body) as List;
      return jsonData.map((item) => Booking.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch approved bookings');
    }
  }

  static Future<Map<String, dynamic>> register(
      String username, String password, String namaLengkap) async {
    try {
      print('Mengirim request ke $baseUrl/auth/register');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'nama_lengkap': namaLengkap,
          // Tidak perlu mengirimkan role dari mobile
        }),
      );

      print('Register response status: ${response.statusCode}');
      print('Register response body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('Error during register: $e');
      throw Exception('Failed to register');
    }
  }

  static Future<Map<String, dynamic>?> login(
      String username, String password) async {
    try {
      print('Mengirim request ke $baseUrl/auth/login');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Gagal login');
      }
    } catch (e) {
      print('Error during login: $e');
      return null; // Mengembalikan null jika terjadi kesalahan
    }
  }

  static Future<User> getUserData(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/getuser'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        print('User data from API: $userData');

        // Buat objek User dari data yang diperoleh
        const baseUrl = 'https://abadinursery.pythonanywhere.com/profile/';
        final user = User.fromJson({
          ...userData,
          'profile_picture': userData['profile_picture'] != null &&
                  userData['profile_picture'].isNotEmpty
              ? baseUrl + userData['profile_picture']
              : ''
        });
        print('Profile Picture URL after parsing: ${user.profilePicture}');
        return user;
      } else {
        throw Exception('Failed to load user data');
      }
    } catch (e) {
      print('Error during getUserData: $e');
      throw Exception('Failed to get user data');
    }
  }

  static Future<User> getUserDataById(int userId) async {
    final token = await SessionManager.getAccessToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/user/getuser/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      print('User data from API: $userData');
      final user = User.fromJson(userData);
      return user;
    } else {
      print(
          'Failed to load user data: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception('Failed to load user data');
    }
  }

  static Future<List<Product>> getProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products/all'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body)['products'];
      List<Product> products =
          body.map((dynamic item) => Product.fromJson(item)).toList();
      return products;
    } else {
      throw Exception('Failed to load products');
    }
  }

  static Future<Map<String, dynamic>> addProduct(
    String namaTanaman,
    String jenisTanaman,
    double hargaSewa,
    File fotoTanaman,
    int jumlahStok, // Menambahkan jumlah stok
  ) async {
    final token = await SessionManager.getAccessToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    var uri = Uri.parse('$baseUrl/products/add');
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['nama_tanaman'] = namaTanaman
      ..fields['jenis_tanaman'] = jenisTanaman
      ..fields['harga_sewa'] = hargaSewa.toString()
      ..fields['jumlah_stok'] = jumlahStok.toString() // Menambahkan jumlah stok
      ..files.add(await http.MultipartFile.fromPath(
        'foto_tanaman',
        fotoTanaman.path,
        filename: path.basename(fotoTanaman.path),
      ));

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      return jsonDecode(responseBody);
    } else {
      throw Exception('Gagal menambahkan produk');
    }
  }

  static Future<Map<String, dynamic>> bookPlant(
    String plantId,
    String startDate,
    String endDate,
    String proofOfPayment,
  ) async {
    final token = await SessionManager.getAccessToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/bookings/book'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'plant_id': plantId,
        'start_date': startDate,
        'end_date': endDate,
        'proof_of_payment': proofOfPayment,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> verifyBooking(int bookingId) async {
    final token = await SessionManager.getAccessToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/booking/verify/$bookingId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return jsonDecode(response.body);
  }

  // Metode untuk mendapatkan daftar permintaan penyewaan
  static Future<List<Booking>> getBookingRequests() async {
    final response = await http.get(
      Uri.parse('$baseUrl/booking/requests'),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body) as List;
      return jsonData.map((item) => Booking.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch booking requests');
    }
  }

  static Future<List<Booking>> getBookingRequestsForUser(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/booking/requests/user'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body) as List;
      return jsonData.map((item) => Booking.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch booking requests for user');
    }
  }

  // Metode untuk menangani permintaan penyewaan (menyetujui atau menolak)
  static Future<Map<String, dynamic>> handleBookingAction(
      int bookingId, bool isApprove) async {
    final action = isApprove ? 'approve' : 'reject';
    final response = await http.put(
      Uri.parse('$baseUrl/booking/$action/$bookingId'),
      headers: {'Content-Type': 'application/json'},
    );

    return jsonDecode(response.body);
  }

  static Future<User> updateUserProfile(
      String namaLengkap, String address, File? profileImage) async {
    final token = await SessionManager.getAccessToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    var uri = Uri.parse('$baseUrl/user/update');
    var request = http.MultipartRequest('PUT', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['nama_lengkap'] = namaLengkap
      ..fields['address'] = address;

    if (profileImage != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'profile_picture',
        profileImage.path,
        filename: path.basename(profileImage.path),
      ));
    }

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();

    // Log response body untuk debugging
    print('Response body: $responseBody');

    if (response.statusCode == 200) {
      var responseData = jsonDecode(responseBody);
      print('Parsed response data: $responseData'); // Log data yang diparsing

      if (responseData['user'] != null) {
        return User.fromJson(responseData['user']);
      } else {
        throw Exception('Gagal memperbarui profil, user data tidak ditemukan');
      }
    } else {
      throw Exception('Gagal memperbarui profil');
    }
  }

  // Fungsi untuk mendapatkan semua pemesanan
  static Future<List<Booking>> getAllBookings() async {
    final token = await SessionManager.getAccessToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/bookings/all'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => Booking.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch bookings');
    }
  }

  static Future<Map<String, dynamic>> updateDeliveryStatus(
      int bookingId, String newStatus) async {
    final token = await SessionManager.getAccessToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/bookings/$bookingId/delivery_status/$newStatus'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final responseBody = jsonDecode(response.body);

    // Log tambahan untuk debugging
    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');
    print('Parsed response: $responseBody');

    if (response.statusCode == 200) {
      return responseBody;
    } else {
      throw Exception('Failed to update delivery status');
    }
  }

  static Future<void> updateBookingStatus(
      int bookingId, String newStatus) async {
    final token = await SessionManager.getAccessToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }
    final response = await http.put(
      Uri.parse('$baseUrl/bookings/$bookingId/status/$newStatus'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update booking status');
    }
  }

  static Future<List<Booking>> getPendingBookings() async {
    final token = await SessionManager.getAccessToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/bookings/pending'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body) as List;
      return jsonData.map((item) => Booking.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch pending bookings');
    }
  }

  // Fungsi untuk mendapatkan pemesanan yang disetujui
  static Future<List<Booking>> getApprovedBookingsAdmin() async {
    final token = await SessionManager.getAccessToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/bookings/approved'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => Booking.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch approved bookings');
    }
  }

  // Fungsi untuk mendapatkan pemesanan yang disetujui untuk user
  static Future<List<Booking>> getApprovedBookingsForUser() async {
    final token = await SessionManager.getAccessToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/bookings/approved_user'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => Booking.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch approved bookings');
    }
  }
}
