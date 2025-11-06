import 'package:intl/intl.dart';

class Tagihan {
  final int id;
  final String idTagihan;
  final String idPelanggan;
  final int bulan;
  final int tahun;
  final int nominal;
  final String status;
  final String? tglBayar;
  final String? pembayaranVia;
  final String? createdAt;
  final String? updatedAt;
  final Pelanggan? pelanggan;

  Tagihan({
    required this.id,
    required this.idTagihan,
    required this.idPelanggan,
    required this.bulan,
    required this.tahun,
    required this.nominal,
    required this.status,
    this.tglBayar,
    this.pembayaranVia,
    this.createdAt,
    this.updatedAt,
    this.pelanggan,
  });

  factory Tagihan.fromJson(Map<String, dynamic> json) {
    return Tagihan(
      id: json['id'],
      idTagihan: json['id_tagihan'],
      idPelanggan: json['id_pelanggan'],
      bulan: json['bulan'],
      tahun: json['tahun'],
      nominal: json['nominal'],
      status: json['status'],
      tglBayar: json['tgl_bayar'],
      pembayaranVia: json['pembayaran_via'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      pelanggan: json['pelanggan'] != null 
          ? Pelanggan.fromJson(json['pelanggan']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_tagihan': idTagihan,
      'id_pelanggan': idPelanggan,
      'bulan': bulan,
      'tahun': tahun,
      'nominal': nominal,
      'status': status,
      'tgl_bayar': tglBayar,
      'pembayaran_via': pembayaranVia,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'pelanggan': pelanggan?.toJson(),
    };
  }

  // Getters
  bool get isLunas => status == 'LS';
  bool get isBelumLunas => status == 'BL';
  
  String get statusText => isLunas ? 'Lunas' : 'Belum Lunas';
  
  String get bulanText {
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[bulan];
  }
  
  String get periode => '$bulanText $tahun';
  
  String get nominalFormatted {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(nominal);
  }
  
  String? get tglBayarFormatted {
    if (tglBayar == null) return null;
    try {
      final date = DateTime.parse(tglBayar!);
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return tglBayar;
    }
  }
}

class Pelanggan {
  final String idPelanggan;
  final String nama;
  final String? email;

  Pelanggan({
    required this.idPelanggan,
    required this.nama,
    this.email,
  });

  factory Pelanggan.fromJson(Map<String, dynamic> json) {
    return Pelanggan(
      idPelanggan: json['id_pelanggan'],
      nama: json['nama'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_pelanggan': idPelanggan,
      'nama': nama,
      'email': email,
    };
  }
}
