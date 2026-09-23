// داشبورد نظارتی دبیر: آمار کلی + لیست دانش‌آموزان + رصد لحظه‌ای
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('داشبورد دبیر'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'آمار کلی'),
              Tab(text: 'دانش‌آموزان'),
              Tab(text: 'رصد لحظه‌ای'),
              Tab(text: 'هشدارها'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _StatsTab(),
            _StudentsTab(),
            _LiveTab(),
            _AlertsTab(),
          ],
        ),
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'student').snapshots(),
      builder: (context, snapshot) {
        final total = snapshot.data?.docs.length ?? 0;
        final online = snapshot.data?.docs.where((d) => (d.data() as Map)['onlineStatus'] == true).length ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _statCard('تعداد دانش‌آموزان', '$total', Icons.groups, AppTheme.primaryBlue),
                  const SizedBox(width: 10),
                  _statCard('آنلاین‌ها', '$online', Icons.circle, Colors.green),
                ],
              ),
              const SizedBox(height: 24),
              const Text('روند مطالعه هفتگی', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true),
                    titlesData: const FlTitlesData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        // نمونه داده - در نسخه نهایی از فعالیت‌های واقعی Firestore جمع‌آوری می‌شود
                        spots: const [
                          FlSpot(0, 3), FlSpot(1, 5), FlSpot(2, 4),
                          FlSpot(3, 7), FlSpot(4, 6), FlSpot(5, 8), FlSpot(6, 5),
                        ],
                        isCurved: true,
                        color: AppTheme.accentOrange,
                        barWidth: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentsTab extends StatelessWidget {
  const _StudentsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'student').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('دانش‌آموزی ثبت‌نام نکرده است.'));
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final online = data['onlineStatus'] == true;
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: data['avatar'] != null ? NetworkImage(data['avatar']) : null,
                child: data['avatar'] == null ? const Icon(Icons.person) : null,
              ),
              title: Text(data['name'] ?? 'بدون نام'),
              subtitle: Text('کلاس: ${data['class'] ?? '-'}'),
              trailing: Icon(Icons.circle, size: 12, color: online ? Colors.green : Colors.grey),
            );
          },
        );
      },
    );
  }
}

class _LiveTab extends StatelessWidget {
  const _LiveTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('activities')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('فعالیتی ثبت نشده است.'));
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return ListTile(
              leading: const Icon(Icons.bolt, color: AppTheme.accentOrange),
              title: Text(data['type'] ?? ''),
              subtitle: Text('فصل: ${data['chapter'] ?? '-'}'),
            );
          },
        );
      },
    );
  }
}

class _AlertsTab extends StatelessWidget {
  const _AlertsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('progressPercent', isLessThan: 30)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('هشداری وجود ندارد. 👍'));
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return ListTile(
              leading: const Icon(Icons.warning_amber, color: Colors.red),
              title: Text(data['name'] ?? ''),
              subtitle: const Text('پیشرفت کمتر از ۳۰٪'),
            );
          },
        );
      },
    );
  }
}
