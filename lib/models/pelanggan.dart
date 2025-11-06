class Pelanggan {
  final int id;
  final String idPelanggan;
  final String nama;
  final String email;
  final String alamat;
  final String whatsapp;
  final String status;
  final String? ipAddress;
  final String? level;
  final String? profilePicture;
  final Paket? paket;

  Pelanggan({
    required this.id,
    required this.idPelanggan,
    required this.nama,
    required this.email,
    required this.alamat,
    required this.whatsapp,
    required this.status,
    this.ipAddress,
    this.level,
    this.profilePicture,
    this.paket,
  });

  factory Pelanggan.fromJson(Map<String, dynamic> json) {
    return Pelanggan(
      id: json['id'],
      idPelanggan: json['id_pelanggan'],
      nama: json['nama'],
      email: json['email'],
      alamat: json['alamat'],
      whatsapp: json['whatsapp'],
      status: json['status'],
      ipAddress: json['ip_address'],
      level: json['level'],
      profilePicture: json['profile_picture'],
      paket: json['paket'] != null ? Paket.fromJson(json['paket']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_pelanggan': idPelanggan,
      'nama': nama,
      'email': email,
      'alamat': alamat,
      'whatsapp': whatsapp,
      'status': status,
      'ip_address': ipAddress,
      'level': level,
      'profile_picture': profilePicture,
      'paket': paket?.toJson(),
    };
  }

  bool get isActive => status == 'aktif';
}

class Paket {
  final String idPaket;
  final String paket;
  final int tarif;

  Paket({
    required this.idPaket,
    required this.paket,
    required this.tarif,
  });

  factory Paket.fromJson(Map<String, dynamic> json) {
    return Paket(
      idPaket: json['id_paket'],
      paket: json['paket'],
      tarif: json['tarif'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_paket': idPaket,
      'paket': paket,
      'tarif': tarif,
    };
  }
}
