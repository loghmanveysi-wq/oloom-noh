// جدول دانش‌آموزان ثبت‌نام‌شده (فقط برای مدیر): نام، تلفن، شهر، امتیاز
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class _Student {
  final String name;
  final String phone;
  final String city;
  final String school;
  final String email;
  final int points;
  final int games;
  final int wins;

  _Student({
    required this.name,
    required this.phone,
    required this.city,
    required this.school,
    required this.email,
    required this.points,
    required this.games,
    required this.wins,
  });
}

class StudentsTableTab extends StatefulWidget {
  const StudentsTableTab({super.key});

  @override
  State<StudentsTableTab> createState() => _StudentsTableTabState();
}

class _StudentsTableTabState extends State<StudentsTableTab> {
  // ستون‌ها: 0 ردیف، 1 نام، 2 تلفن، 3 شهر، 4 امتیاز
  int _sortIndex = 4;
  bool _asc = false;
  String _query = '';

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream = FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'student')
      .snapshots();

  int _n(dynamic v) => (v as num?)?.toInt() ?? 0;

  _Student _fromDoc(Map<String, dynamic> m) {
    final comp = Map<String, dynamic>.from((m['comp'] as Map?) ?? {});
    return _Student(
      name: (m['name'] ?? '').toString().trim(),
      phone: (m['phone'] ?? '').toString().trim(),
      city: (m['city'] ?? '').toString().trim(),
      school: (m['school'] ?? '').toString().trim(),
      email: (m['email'] ?? '').toString().trim(),
      points: _n(comp['points']),
      games: _n(comp['games']),
      wins: _n(comp['wins']),
    );
  }

  void _sort(int index, bool asc) {
    setState(() {
      _sortIndex = index;
      _asc = asc;
    });
  }

  void _details(_Student s) {
    Widget line(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 78, child: Text(label, style: const TextStyle(color: Colors.grey))),
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(value.isEmpty ? '—' : value, textAlign: TextAlign.right),
                ),
              ),
            ],
          ),
        );
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.name.isEmpty ? 'دانش‌آموز' : s.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            line('تلفن', s.phone),
            line('ایمیل', s.email),
            line('مدرسه', s.school),
            line('شهر', s.city),
            line('امتیاز', '${s.points}'),
            line('رقابت‌ها', '${s.games}'),
            line('پیروزی‌ها', '${s.wins}'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('بستن'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            onChanged: (v) => setState(() => _query = v.trim()),
            decoration: InputDecoration(
              hintText: 'جستجو در نام، شماره تلفن یا شهر...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(child: Text('خطا در بارگذاری: ${snap.error}'));
              }
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              var list = [for (final d in snap.data!.docs) _fromDoc(d.data())];
              if (_query.isNotEmpty) {
                list = list
                    .where((s) =>
                        s.name.contains(_query) || s.phone.contains(_query) || s.city.contains(_query))
                    .toList();
              }
              list.sort((a, b) {
                int c;
                if (_sortIndex == 1) {
                  c = a.name.compareTo(b.name);
                } else if (_sortIndex == 2) {
                  c = a.phone.compareTo(b.phone);
                } else if (_sortIndex == 3) {
                  c = a.city.compareTo(b.city);
                } else {
                  c = a.points.compareTo(b.points);
                }
                return _asc ? c : -c;
              });
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text('تعداد دانش‌آموزان: ${list.length}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
                    ),
                  ),
                  Expanded(
                    child: list.isEmpty
                        ? const Center(child: Text('دانش‌آموزی پیدا نشد.', style: TextStyle(color: Colors.grey)))
                        : SingleChildScrollView(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                sortColumnIndex: _sortIndex,
                                sortAscending: _asc,
                                columnSpacing: 20,
                                headingRowHeight: 44,
                                dataRowMinHeight: 44,
                                dataRowMaxHeight: 52,
                                showCheckboxColumn: false,
                                headingRowColor:
                                    MaterialStateProperty.all(AppTheme.primaryBlue.withOpacity(0.10)),
                                columns: [
                                  const DataColumn(label: Text('ردیف')),
                                  DataColumn(label: const Text('نام و نام خانوادگی'), onSort: _sort),
                                  DataColumn(label: const Text('شماره تلفن'), onSort: _sort),
                                  DataColumn(label: const Text('شهر'), onSort: _sort),
                                  DataColumn(label: const Text('امتیاز'), numeric: true, onSort: _sort),
                                ],
                                rows: [
                                  for (var i = 0; i < list.length; i++)
                                    DataRow(
                                      onSelectChanged: (_) => _details(list[i]),
                                      cells: [
                                        DataCell(Text('${i + 1}')),
                                        DataCell(Text(list[i].name.isEmpty ? '—' : list[i].name)),
                                        DataCell(Directionality(
                                          textDirection: TextDirection.ltr,
                                          child: Text(list[i].phone.isEmpty ? '—' : list[i].phone),
                                        )),
                                        DataCell(Text(list[i].city.isEmpty ? '—' : list[i].city)),
                                        DataCell(Text('${list[i].points}',
                                            style: const TextStyle(fontWeight: FontWeight.bold))),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
