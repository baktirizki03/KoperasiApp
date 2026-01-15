import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'pinjaman_detail_screen.dart'; 

class PinjamanListScreen extends StatefulWidget {
  @override
  _PinjamanListScreenState createState() => _PinjamanListScreenState();
}

class _PinjamanListScreenState extends State<PinjamanListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manajemen Pinjaman'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Pending'),
            Tab(text: 'Disetujui'),
            Tab(text: 'Ditolak'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPinjamanList('pending'),
          _buildPinjamanList('disetujui'),
          _buildPinjamanList('ditolak'),
        ],
      ),
    );
  }

  Widget _buildPinjamanList(String status) {
    final ApiService apiService = ApiService();

    return FutureBuilder<List<dynamic>>(
      future: apiService.getPinjamanList(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text('Tidak ada pengajuan dengan status "$status".'),
          );
        }

        final pinjamanList = snapshot.data!;
        return ListView.builder(
          itemCount: pinjamanList.length,
          itemBuilder: (ctx, index) {
            final pinjaman = pinjamanList[index];
            final anggota = pinjaman['anggota'];
            return Card(
              margin: EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(
                  anggota != null
                      ? anggota['nama_lengkap']
                      : 'Nama tidak tersedia',
                ),
                subtitle: Text(
                  'Nominal: Rp ${pinjaman['nominal']} \nTenor: ${pinjaman['tenor_cicilan']} bulan',
                ),
                isThreeLine: true,
                onTap: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) =>
                          PinjamanDetailScreen(pinjamanId: pinjaman['id']),
                    ),
                  );
                  if (result == true) {
                    setState(() {}); 
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}
