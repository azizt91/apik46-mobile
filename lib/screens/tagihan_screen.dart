import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/tagihan.dart';

class TagihanScreen extends StatefulWidget {
  const TagihanScreen({super.key});

  @override
  State<TagihanScreen> createState() => _TagihanScreenState();
}

class _TagihanScreenState extends State<TagihanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  List<Tagihan> _tagihanBelumLunas = [];
  List<Tagihan> _tagihanLunas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTagihan();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTagihan() async {
    setState(() => _isLoading = true);
    try {
      // Load belum lunas
      final responseBL = await _apiService.getTagihan(status: 'BL');
      if (responseBL.data['success'] == true) {
        _tagihanBelumLunas = (responseBL.data['data'] as List)
            .map((json) => Tagihan.fromJson(json))
            .toList();
      }

      // Load lunas
      final responseLS = await _apiService.getTagihan(status: 'LS');
      if (responseLS.data['success'] == true) {
        _tagihanLunas = (responseLS.data['data'] as List)
            .map((json) => Tagihan.fromJson(json))
            .toList();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat tagihan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8FC),
      appBar: AppBar(
        title: const Text('Tagihan'),
        backgroundColor: const Color(0xFF501EE6),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Belum Lunas'),
            Tab(text: 'Lunas'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTagihanList(_tagihanBelumLunas, false),
                _buildTagihanList(_tagihanLunas, true),
              ],
            ),
    );
  }

  Widget _buildTagihanList(List<Tagihan> tagihan, bool isLunas) {
    if (tagihan.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLunas ? Icons.check_circle_outline : Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isLunas
                  ? 'Belum ada tagihan yang lunas'
                  : 'Tidak ada tagihan yang belum lunas',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTagihan,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tagihan.length,
        itemBuilder: (context, index) {
          final item = tagihan[index];
          return _buildTagihanCard(item);
        },
      ),
    );
  }

  Widget _buildTagihanCard(Tagihan tagihan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tagihan.periode,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF110E1B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: tagihan.isLunas
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tagihan.statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: tagihan.isLunas ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tagihan.nominalFormatted,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: tagihan.isLunas ? Colors.green : Colors.red,
            ),
          ),
          if (tagihan.isLunas && tagihan.tglBayarFormatted != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  'Dibayar: ${tagihan.tglBayarFormatted}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF604E97),
                  ),
                ),
              ],
            ),
          ],
          if (tagihan.pembayaranVia != null) ...[
            const SizedBox(height: 4),
            Text(
              'Via: ${tagihan.pembayaranVia}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF604E97),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
