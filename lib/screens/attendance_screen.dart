import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/event.dart';
import '../models/profile.dart';
import '../services/supabase_service.dart';
import '../theme/colors.dart';

class AttendanceScreen extends StatefulWidget {
  final Event event;

  const AttendanceScreen({required this.event, super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _studentIdController = TextEditingController();
  bool _showScanner = false;
  bool _isProcessing = false;
  bool _isTimeOut = false; // false = TIME IN, true = TIME OUT (only used when requireLogout)

  @override
  void initState() {
    super.initState();
    // Force TIME IN only when event doesn't require logout
    if (!widget.event.requireLogout) _isTimeOut = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryRed,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.event.name,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryRed.withValues(alpha: 0.1),
                  border: Border.all(color: primaryRed, width: 2),
                ),
                child: const Icon(Icons.qr_code_scanner,
                    color: primaryRed, size: 50),
              ),
              const SizedBox(height: 20),
              Text(
                'Mark Attendance',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: darkRed,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.event.description.isNotEmpty
                    ? widget.event.description
                    : widget.event.name,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Time In / Time Out toggle — only show if event requires logout
              if (widget.event.requireLogout)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _isTimeOut ? Colors.blue : Colors.green, width: 2),
                    color: (_isTimeOut ? Colors.blue : Colors.green)
                        .withValues(alpha: 0.08),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isTimeOut = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: !_isTimeOut
                                  ? Colors.green
                                  : Colors.transparent,
                              borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(10)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.login,
                                    color: !_isTimeOut
                                        ? Colors.white
                                        : Colors.green,
                                    size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  'TIME IN',
                                  style: TextStyle(
                                    color: !_isTimeOut
                                        ? Colors.white
                                        : Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isTimeOut = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color:
                                  _isTimeOut ? Colors.blue : Colors.transparent,
                              borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(10)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout,
                                    color:
                                        _isTimeOut ? Colors.white : Colors.blue,
                                    size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  'TIME OUT',
                                  style: TextStyle(
                                    color:
                                        _isTimeOut ? Colors.white : Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.green,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login, color: Colors.white, size: 20),
                      SizedBox(width: 6),
                      Text(
                        'TIME IN',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

              // Scanner or manual input
              if (_showScanner)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryRed, width: 2),
                    ),
                    child: MobileScanner(
                      onDetect: (capture) {
                        if (_isProcessing) return;
                        final barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty) {
                          final value = barcodes.first.rawValue ?? '';
                          if (value.isNotEmpty) {
                            _isProcessing = true;
                            Future.delayed(const Duration(milliseconds: 200),
                                () {
                              if (mounted) _submitAttendance(value);
                            });
                          }
                        }
                      },
                    ),
                  ),
                )
              else
                TextField(
                  controller: _studentIdController,
                  decoration: InputDecoration(
                    labelText: 'Student ID',
                    labelStyle: const TextStyle(color: primaryRed),
                    hintText: 'e.g. 2024-0001',
                    prefixIcon: const Icon(Icons.person, color: primaryRed),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: primaryRed, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: darkRed, width: 2),
                    ),
                    filled: true,
                    fillColor: lightGray,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check_circle, color: primaryRed),
                      onPressed: _isProcessing
                          ? null
                          : () => _submitAttendance(
                              _studentIdController.text.trim()),
                    ),
                  ),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (v) =>
                      _isProcessing ? null : _submitAttendance(v.trim()),
                ),

              const SizedBox(height: 16),

              // Submit button (manual mode only)
              if (!_showScanner)
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: Material(
                    color: primaryRed,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _isProcessing
                          ? null
                          : () => _submitAttendance(
                              _studentIdController.text.trim()),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            _isProcessing ? 'Processing...' : 'Submit',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Toggle scanner / manual
              SizedBox(
                width: double.infinity,
                height: 55,
                child: Material(
                  color: _showScanner ? darkRed : primaryRed,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() {
                      _showScanner = !_showScanner;
                      _studentIdController.clear();
                      _isProcessing = false;
                    }),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showScanner ? Icons.edit : Icons.qr_code_scanner,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _showScanner ? 'Manual Entry' : 'Scan Barcode',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (_showScanner)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryRed, width: 1),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: primaryRed, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Point your camera at the student\'s barcode or QR code.',
                            style:
                                TextStyle(color: primaryRed, fontSize: 12),
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

  Future<void> _submitAttendance(String rawStudentId) async {
    if (rawStudentId.isEmpty) {
      _showSnack('Please enter or scan a student ID', Colors.red);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // 1. Look up the student profile by student_id field
      final student =
          await SupabaseService.fetchStudentByStudentId(rawStudentId);

      if (student == null) {
        _showSnack(
            'Student ID "$rawStudentId" not found in the system.', Colors.red);
        setState(() => _isProcessing = false);
        return;
      }

      // 2. Check if requirement already fulfilled (different event, same req)
      bool alreadyFulfilled = false;
      if (widget.event.requirementId != null) {
        alreadyFulfilled = await SupabaseService.isRequirementAlreadyFulfilled(
          studentProfileId: student.id,
          requirementId: widget.event.requirementId!,
        );
      }

      // 3. Insert attendance record (trigger upserts requirement_submission)
      await SupabaseService.recordAttendance(
        eventId: widget.event.id,
        studentProfileId: student.id,
        attendanceType: _isTimeOut ? 'log_out' : 'log_in',
      );

      // 4. Show success dialog
      if (mounted) {
        _showSuccessDialog(
          student,
          rawStudentId,
          alreadyFulfilled: alreadyFulfilled,
          attendanceType: _isTimeOut ? 'log_out' : 'log_in',
        );
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('duplicate key') ||
          msg.contains('unique') ||
          msg.contains('23505')) {
        _showSnack(
            'Student $rawStudentId already has a ${_isTimeOut ? "TIME OUT" : "TIME IN"} record for this event.',
            Colors.orange);
      } else {
        _showSnack('Error recording attendance: $msg', Colors.red);
      }
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog(
    Profile student,
    String rawStudentId, {
    bool alreadyFulfilled = false,
    required String attendanceType,
  }) {
    final reqName = widget.event.requirementName;
    final hasReq = reqName != null;

    final Color badgeColor = !hasReq
        ? Colors.amber
        : alreadyFulfilled
            ? Colors.blue
            : Colors.green;

    final String badgeText = !hasReq
        ? 'Attendance recorded — no clearance requirement linked'
        : alreadyFulfilled
            ? 'Requirement "$reqName" already fulfilled — attendance recorded'
            : 'Requirement "$reqName" submitted';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: backgroundColor,
        title: const Text(
          'Attendance Recorded',
          style: TextStyle(color: darkRed, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: primaryRed.withValues(alpha: 0.12),
              backgroundImage:
                  student.avatarUrl != null && student.avatarUrl!.isNotEmpty
                      ? NetworkImage(student.avatarUrl!)
                      : null,
              child: student.avatarUrl == null || student.avatarUrl!.isEmpty
                  ? Text(
                      student.fullName.isNotEmpty
                          ? student.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: primaryRed,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              student.fullName.isNotEmpty ? student.fullName : rawStudentId,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'ID: $rawStudentId',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: badgeColor),
              ),
              child: Text(
                badgeText,
                textAlign: TextAlign.center,
                style: TextStyle(color: badgeColor, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (attendanceType == 'log_out' ? Colors.blue : Colors.green)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: attendanceType == 'log_out'
                        ? Colors.blue
                        : Colors.green),
              ),
              child: Text(
                attendanceType == 'log_out'
                    ? 'TIME OUT recorded'
                    : 'TIME IN recorded',
                style: TextStyle(
                  color: attendanceType == 'log_out' ? Colors.blue : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isProcessing = false;
                _studentIdController.clear();
              });
            },
            child: const Text('OK', style: TextStyle(color: primaryRed)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    super.dispose();
  }
}
