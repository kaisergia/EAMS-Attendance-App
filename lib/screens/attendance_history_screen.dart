import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/supabase_service.dart';
import '../theme/colors.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final Event event;

  const AttendanceHistoryScreen({required this.event, super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final records =
          await SupabaseService.fetchAttendanceForEvent(widget.event.id);
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load attendance: $e';
        _isLoading = false;
      });
    }
  }

  String _studentName(Map<String, dynamic> record) {
    final student = record['student'] as Map<String, dynamic>?;
    if (student == null) return 'Unknown';
    final first = student['first_name'] as String? ?? '';
    final last = student['last_name'] as String? ?? '';
    final name = '$first $last'.trim();
    return name.isEmpty ? (student['student_id'] as String? ?? 'Unknown') : name;
  }

  String _studentId(Map<String, dynamic> record) {
    final student = record['student'] as Map<String, dynamic>?;
    return student?['student_id'] as String? ?? '—';
  }

  String _courseYear(Map<String, dynamic> record) {
    final student = record['student'] as Map<String, dynamic>?;
    if (student == null) return '';
    final course = student['course'] as String? ?? '';
    final year = student['year_level'] as String? ?? '';
    if (course.isEmpty && year.isEmpty) return '';
    return '$course${year.isNotEmpty ? ' · $year' : ''}';
  }

  String? _avatarUrl(Map<String, dynamic> record) {
    final student = record['student'] as Map<String, dynamic>?;
    final url = student?['avatar_url'] as String?;
    return (url != null && url.isNotEmpty) ? url : null;
  }

  String _scannedAt(Map<String, dynamic> record) {
    final raw = record['scanned_at'] as String?;
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return raw;
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} '
        '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryRed,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.event.name,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryRed),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _load,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: primaryRed),
                          child: const Text('Retry',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: primaryRed,
                  onRefresh: _load,
                  child: _records.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline,
                                      size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No attendees yet.',
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Container(
                              width: double.infinity,
                              color: primaryRed.withValues(alpha: 0.06),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              child: Text(
                                '${_records.length} attendee${_records.length == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  color: darkRed,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                itemCount: _records.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 4),
                                itemBuilder: (ctx, i) {
                                  final record = _records[i];
                                  final courseYear = _courseYear(record);
                                  return Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: const BorderSide(
                                          color: Colors.black12),
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            primaryRed.withValues(alpha: 0.12),
                                        backgroundImage: _avatarUrl(record) != null
                                            ? NetworkImage(_avatarUrl(record)!)
                                            : null,
                                        child: _avatarUrl(record) == null
                                            ? Text(
                                                _studentName(record)[0].toUpperCase(),
                                                style: const TextStyle(
                                                  color: primaryRed,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              )
                                            : null,
                                      ),
                                      title: Text(
                                        _studentName(record),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: darkRed,
                                          fontSize: 14,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'ID: ${_studentId(record)}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600]),
                                          ),
                                          if (courseYear.isNotEmpty)
                                            Text(
                                              courseYear,
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[500]),
                                            ),
                                        ],
                                      ),
                                      trailing: Text(
                                        _scannedAt(record),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[400],
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                ),
    );
  }
}
