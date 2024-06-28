class Product {
  final int id;
  final String namaTanaman;
  final double hargaSewa;
  final String jenisTanaman;
  final String fotoTanaman;
  final int jumlahStok;

  Product({
    required this.id,
    required this.namaTanaman,
    required this.jenisTanaman,
    required this.hargaSewa,
    required this.fotoTanaman,
    required this.jumlahStok,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    const baseUrl = 'https://abadinursery.pythonanywhere.com/products/';
    String fotoTanaman = json['foto_tanaman'];
    if (fotoTanaman.contains('/home/abadinursery/abadinursery/assets/product/')) {
      fotoTanaman = baseUrl + fotoTanaman.split('/').last;
    }
    return Product(
      id: json['id'],
      namaTanaman: json['nama_tanaman'],
      jenisTanaman: json['jenis_tanaman'],
      hargaSewa: double.parse(json['harga_sewa'].toString()),  // Konversi String ke double
      fotoTanaman: fotoTanaman,
      jumlahStok: json['jumlah_stok'],
    );
  }
}