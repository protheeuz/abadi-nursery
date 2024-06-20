import 'package:abadinursery/utils/product_card.dart';
import 'package:flutter/material.dart';
import 'package:abadinursery/models/booking_model.dart';
import 'package:abadinursery/widgets/ios_styled_notification.dart';
import 'package:abadinursery/models/product_model.dart';
import 'package:abadinursery/models/user_model.dart';
import 'package:abadinursery/services/api_service.dart';
import 'package:abadinursery/widgets/customcircular.dart';
import 'package:abadinursery/widgets/customrefresh.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'booking_page.dart';

class PenyewaDashboard extends StatefulWidget {
  final User user;
  final Function(User) onUserUpdated;

  const PenyewaDashboard(
      {super.key, required this.user, required this.onUserUpdated});

  @override
  _PenyewaDashboardState createState() => _PenyewaDashboardState();
}

class _PenyewaDashboardState extends State<PenyewaDashboard> {
  List<Product> _products = [];
  bool _isLoading = true;
  int _currentCarouselIndex = 0;
  int _notificationCount = 0;
  List<Booking> _approvedBookings = [];
  Map<Product, int> _cartItems = {};

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _checkApprovedBookings();
  }

  Future<void> _fetchProducts() async {
    try {
      List<Product> products = await ApiService.getProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      print('Failed to load products: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkApprovedBookings() async {
    try {
      List<Booking> approvedBookings =
          await ApiService.getApprovedBookingsForUser();
      setState(() {
        _approvedBookings = approvedBookings;
        _notificationCount = approvedBookings.length;
      });
    } catch (e) {
      print('Failed to check approved bookings: $e');
    }
  }

  Future<void> _refreshApprovedBookings() async {
    try {
      List<Booking> approvedBookings =
          await ApiService.getApprovedBookingsForUser();
      setState(() {
        _approvedBookings = approvedBookings;
        _notificationCount = approvedBookings.length;
      });
    } catch (e) {
      print('Failed to refresh approved bookings: $e');
    }
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _isLoading = true;
    });
    await _fetchProducts();
  }

  String formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0', 'id');
    return formatter.format(amount);
  }

  void _showBookingList(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Daftar Pemesanan'),
          content: SingleChildScrollView(
            child: Column(
              children: _approvedBookings.map((booking) {
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    title: Text(
                      'Booking id: ${booking.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        ...booking.bookingDetails.map((detail) {
                          return Text(
                            'Nama Tanaman: ${detail.namaTanaman}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 5),
                        Text(
                          'Total Harga: Rp ${formatCurrency(booking.totalSewa)}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Status: ${booking.statusPengiriman}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _showBookingStatus(context, booking);
                    },
                  ),
                );
              }).toList(),
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

  void _showBookingStatus(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Status Pemesanan'),
          content: SingleChildScrollView(
            child: Column(
              children: _buildTimeline(booking),
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
  if (!booking.needDelivery) {
    return [const Text('Pengiriman tidak diperlukan')];
  }

  List<Map<String, String>> statuses = [
    {'status': 'Sedang diproses', 'description': 'Pesanan sedang diproses'},
    {'status': 'Sedang dikemas', 'description': 'Pesanan sedang dikemas'},
    {'status': 'Sedang dikirim', 'description': 'Pesanan sedang dikirim'},
    {'status': 'Sudah sampai', 'description': 'Pesanan sudah sampai di tujuan'},
  ];

  bool reachedCurrentStatus = false;
  bool isPastStatus = true;

  return statuses.map((status) {
    bool isActive = booking.statusPengiriman == status['status'];

    if (isActive) {
      reachedCurrentStatus = true;
      isPastStatus = false;
    }

    return TimelineTile(
      alignment: TimelineAlign.manual,
      lineXY: 0.1,
      isFirst: status['status'] == 'Sedang diproses',
      isLast: status['status'] == 'Sudah sampai',
      indicatorStyle: IndicatorStyle(
        width: 20,
        color: isActive || isPastStatus ? Colors.green : Colors.grey,
        iconStyle: IconStyle(
          iconData: isActive || isPastStatus ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isActive || isPastStatus ? Colors.green : Colors.grey,
        ),
      ),
      beforeLineStyle: LineStyle(
        color: isActive || isPastStatus ? Colors.green : Colors.grey,
        thickness: 6,
      ),
      afterLineStyle: LineStyle(
        color: reachedCurrentStatus ? Colors.grey : Colors.green,
        thickness: 6,
      ),
      endChild: Container(
        constraints: const BoxConstraints(minHeight: 80),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            status['description']!,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Poppins',
              color: isActive || isPastStatus ? Colors.green : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }).toList();
}

  void _addToCart(Product product) {
    setState(() {
      if (_cartItems.containsKey(product)) {
        _cartItems[product] = _cartItems[product]! + 1;
      } else {
        _cartItems[product] = 1;
      }
    });

    _showIOSStyledNotification(
      context,
      '${product.namaTanaman} ditambahkan ke keranjang!',
    );
  }

  void _navigateToCart() async {
    if (_cartItems.isEmpty) {
      _showIOSStyledNotification(
        context,
        'Anda belum memilih item sama sekali',
      );
      return;
    }

    final updatedCartItems = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingPage(
          cartItems: _cartItems,
          user: widget.user,
          onUserUpdated: widget.onUserUpdated,
        ),
      ),
    );

    if (updatedCartItems != null) {
      setState(() {
        _cartItems = updatedCartItems;
      });
    }
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Hi. Selamat pagi';
    } else if (hour < 15) {
      return 'Hi. Selamat siang';
    } else if (hour < 18) {
      return 'Hi. Selamat sore';
    } else {
      return 'Hi. Selamat malam';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomRefreshIndicator(
          onRefresh: _refreshProducts,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 11.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${getGreeting()},\n${widget.user.namaLengkap}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Row(
                      children: [
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(
                                  Icons.notifications_none_outlined,
                                  size: 25),
                              onPressed: () => _showBookingList(context),
                            ),
                            if (_notificationCount > 0)
                              Positioned(
                                right: -1,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.green[300],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 13,
                                    minHeight: 13,
                                  ),
                                  child: Text(
                                    '$_notificationCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontFamily: 'Poppins',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(),
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.shopping_cart_outlined,
                                  size: 20),
                              onPressed: _navigateToCart,
                            ),
                            if (_cartItems.isNotEmpty)
                              Positioned(
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.green[300],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 13,
                                    minHeight: 13,
                                  ),
                                  child: Text(
                                    '${_cartItems.values.fold<int>(0, (sum, count) => sum + (count))}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontFamily: 'Poppins',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _isLoading
                  ? const Center(
                      child: CustomCircularProgressIndicator(
                        imagePath: 'assets/images/logo/circularcustom.png',
                        size: 60,
                      ),
                    )
                  : Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBannerCarousel(),
                            _buildCarouselIndicator(),
                            const Padding(
                              padding: EdgeInsets.only(left: 14),
                              child: Text(
                                "Katalog Kami",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _products.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 0.75,
                                ),
                                itemBuilder: (context, index) {
                                  return ProductCard(
                                    product: _products[index],
                                    onAddToCart: () =>
                                        _addToCart(_products[index]),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerCarousel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 180,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 4),
          enlargeCenterPage: true,
          onPageChanged: (index, reason) {
            setState(() {
              _currentCarouselIndex = index;
            });
          },
        ),
        items: [
          'https://img.freepik.com/free-psd/hand-drawn-botanical-garden-landing-page_23-2150297493.jpg?w=1480&t=st=1716674670~exp=1716675270~hmac=b82427a4b2c300ee946454da9a615cf8f7b0f9b6b85ef5ecd6c44433e3209abf',
          'https://img.pikbest.com/wp/202413/torn-paper-creative-effect-indoor-green-plant-banner_6047689.jpg!w700wp',
          'https://img.freepik.com/free-psd/hand-drawn-botanical-garden-facebook-template_23-2150297499.jpg?w=1480&t=st=1716674968~exp=1716675568~hmac=cce2d2479f466ac8b7658dc480d6625c4bca387a98cbb72c8b0c18f7da65b7fb'
        ].map((banner) {
          return Builder(
            builder: (BuildContext context) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(15.0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          color: Colors.grey[300],
                        ),
                      ),
                    ),
                    Image.network(
                      banner,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (BuildContext context, Widget child,
                          ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCarouselIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < 3; i++)
          Container(
            width: 8.0,
            height: 8.0,
            margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentCarouselIndex == i
                  ? const Color.fromRGBO(0, 0, 0, 0.9)
                  : const Color.fromRGBO(0, 0, 0, 0.4),
            ),
          ),
      ],
    );
  }

  void _showIOSStyledNotification(BuildContext context, String message) {
    showOverlayNotification(
      (context) {
        return IOSStyledNotification(
          message: message,
          icon: Icons.warning,
          backgroundColor: Colors.green,
        );
      },
      duration: const Duration(seconds: 3),
    );
  }
}
