class User {
  final int id;
  final String username;
  final String role;
  final String namaLengkap;
  final String profilePicture;
  final String address;

  User({
    required this.id,
    required this.username,
    required this.role,
    required this.namaLengkap,
    required this.profilePicture,
    required this.address,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      role: json['role'],
      namaLengkap: json['nama_lengkap'] ?? '',
      profilePicture: json['profile_picture'] ?? '',
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'nama_lengkap': namaLengkap,
      'profile_picture': profilePicture,
      'address': address,
    };
  }
}
