import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../models/organization.dart';
import '../models/event.dart';

class SupabaseService {
  static final supabase = Supabase.instance.client;

  // ── Auth ──────────────────────────────────────────────────────────────────

  static Future<AuthResponse> signInWithEmail(
      String email, String password) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static User? getCurrentUser() => supabase.auth.currentUser;

  static Future<void> signOut() async => await supabase.auth.signOut();

  static bool isLoggedIn() => supabase.auth.currentUser != null;

  // ── Profile ───────────────────────────────────────────────────────────────

  /// Fetches the profile for the currently authenticated user.
  /// Throws if role is not one of 'office', 'department', 'club', 'csg_department_lgu', 'cspsg_division', 'csg', 'cspsg'.
  static Future<Profile> fetchCurrentProfile() async {
    final uid = supabase.auth.currentUser!.id;
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', uid)
        .single();
    final profile = Profile.fromMap(data);
    if (!['office', 'department', 'club', 'csg_department_lgu', 'cspsg_division', 'csg', 'cspsg'].contains(profile.role)) {
      throw Exception('This app is for staff only.');
    }
    return profile;
  }

  // ── Organization ──────────────────────────────────────────────────────────

  /// Returns the organization (office/department/club) where the current user
  /// is the head/adviser.
  static Future<Organization?> fetchMyOrganization() async {
    final uid = supabase.auth.currentUser!.id;
    final profile = await supabase.from('profiles').select('role').eq('id', uid).single();
    final role = profile['role'] as String;

    if (role == 'office') {
      final data = await supabase.from('offices').select().eq('head_id', uid).maybeSingle();
      if (data == null) return null;
      return Organization.fromMap(data, 'office');
    } else if (role == 'department') {
      final data = await supabase.from('departments').select().eq('head_id', uid).maybeSingle();
      if (data == null) return null;
      return Organization.fromMap(data, 'department');
    } else if (role == 'club') {
      final data = await supabase.from('clubs').select().eq('adviser_id', uid).maybeSingle();
      if (data == null) return null;
      return Organization.fromMap(data, 'club');
    } else if (role == 'csg_department_lgu') {
      final data = await supabase.from('csg_department_lgus').select().eq('head_id', uid).maybeSingle();
      if (data == null) return null;
      return Organization.fromMap(data, 'csg_department_lgu');
    } else if (role == 'cspsg_division') {
      final data = await supabase.from('cspsg_divisions').select().eq('head_id', uid).maybeSingle();
      if (data == null) return null;
      return Organization.fromMap(data, 'cspsg_division');
    } else if (role == 'csg') {
      final data = await supabase.from('csg').select().eq('head_id', uid).maybeSingle();
      if (data == null) return null;
      return Organization.fromMap(data, 'csg');
    } else if (role == 'cspsg') {
      final data = await supabase.from('cspsg').select().eq('head_id', uid).maybeSingle();
      if (data == null) return null;
      return Organization.fromMap(data, 'cspsg');
    }
    return null;
  }

  // ── Events ────────────────────────────────────────────────────────────────

  static Future<List<Event>> fetchEventsForSource(
      String sourceType, String sourceId) async {
    final data = await supabase
        .from('events')
        .select('*, requirement:requirements(id, name)')
        .eq('source_type', sourceType)
        .eq('source_id', sourceId)
        .order('event_date', ascending: false);
    return (data as List).map((e) => Event.fromMap(e)).toList();
  }

  static Future<Event> createEvent({
    required String sourceType,
    required String sourceId,
    required String name,
    required String description,
    required DateTime eventDate,
    String? requirementId,
    bool requireLogout = false,
  }) async {
    final uid = supabase.auth.currentUser!.id;
    final data = await supabase.from('events').insert({
      'source_type': sourceType,
      'source_id': sourceId,
      'name': name,
      'description': description,
      'event_date': eventDate.toIso8601String(),
      'created_by': uid,
      'is_active': true,
      'require_logout': requireLogout,
      if (requirementId != null) 'requirement_id': requirementId,
    }).select('*, requirement:requirements(id, name)').single();
    return Event.fromMap(data);
  }

  static Future<Event> updateEvent({
    required String eventId,
    required String name,
    required String description,
    required DateTime eventDate,
    String? requirementId,
    bool clearRequirement = false,
    String? previousRequirementId,
    bool requireLogout = false,
  }) async {
    final newReqId = clearRequirement ? null : requirementId;
    final data = await supabase
        .from('events')
        .update({
          'name': name,
          'description': description,
          'event_date': eventDate.toIso8601String(),
          'requirement_id': newReqId,
          'require_logout': requireLogout,
        })
        .eq('id', eventId)
        .select('*, requirement:requirements(id, name)')
        .single();

    // If requirement was just linked (was null, now set), backfill existing attendance
    if (previousRequirementId == null && newReqId != null) {
      await supabase.rpc('backfill_attendance_submissions', params: {
        'p_event_id': eventId,
      });
    }

    return Event.fromMap(data);
  }

  static Future<void> deleteEvent(String eventId) async {
    await supabase.from('events').delete().eq('id', eventId);
  }

  static Future<void> setEventActive(
      String eventId, {required bool isActive}) async {
    await supabase
        .from('events')
        .update({'is_active': isActive})
        .eq('id', eventId);
  }

  // ── Requirements ──────────────────────────────────────────────────────────

  /// Returns all requirements for an organization source (for management screen).
  static Future<List<Map<String, dynamic>>> fetchRequirementsForSource(
      String sourceType, String sourceId) async {
    final data = await supabase
        .from('requirements')
        .select()
        .eq('source_type', sourceType)
        .eq('source_id', sourceId)
        .order('order', ascending: true);
    return List<Map<String, dynamic>>.from(data as List);
  }

  /// Returns only attendance-based requirements for the event requirement dropdown.
  static Future<List<Map<String, dynamic>>> fetchAttendanceRequirementsForSource(
      String sourceType, String sourceId) async {
    final data = await supabase
        .from('requirements')
        .select('id, name')
        .eq('source_type', sourceType)
        .eq('source_id', sourceId)
        .eq('is_attendance', true)
        .order('order', ascending: true);
    return List<Map<String, dynamic>>.from(data as List);
  }

  static Future<Map<String, dynamic>> createRequirement({
    required String sourceType,
    required String sourceId,
    required String name,
    String? description,
    bool isRequired = true,
    bool requiresUpload = false,
    bool isAttendance = false,
  }) async {
    final existing = await supabase
        .from('requirements')
        .select('order')
        .eq('source_type', sourceType)
        .eq('source_id', sourceId)
        .order('order', ascending: false)
        .limit(1);
    final nextOrder = (existing as List).isNotEmpty
        ? ((existing.first['order'] as int? ?? 0) + 1)
        : 0;

    final data = await supabase.from('requirements').insert({
      'source_type': sourceType,
      'source_id': sourceId,
      'name': name,
      if (description != null && description.isNotEmpty)
        'description': description,
      'is_required': isRequired,
      'requires_upload': requiresUpload,
      'is_attendance': isAttendance,
      'order': nextOrder,
      'is_published': false,
    }).select().single();
    return data;
  }

  static Future<Map<String, dynamic>> updateRequirement({
    required String id,
    String? name,
    String? description,
    bool? isRequired,
    bool? requiresUpload,
    bool? isAttendance,
    bool? isPublished,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (isRequired != null) updates['is_required'] = isRequired;
    if (requiresUpload != null) updates['requires_upload'] = requiresUpload;
    if (isAttendance != null) updates['is_attendance'] = isAttendance;
    if (isPublished != null) updates['is_published'] = isPublished;

    final data = await supabase
        .from('requirements')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return data;
  }

  static Future<void> deleteRequirement(String id) async {
    await supabase.from('requirements').delete().eq('id', id);
  }

  // ── Attendance helpers ───────────────────────────────────────────────────

  /// Deletes all attendance records for a student on an event,
  /// and cleans up related requirement_submissions via DB function.
  static Future<int> deleteStudentAttendance(
      String eventId, String studentId) async {
    final data = await supabase.rpc('delete_student_attendance', params: {
      'p_event_id': eventId,
      'p_student_id': studentId,
    });
    return (data as int?) ?? 0;
  }

  /// Returns the number of attendance records for an event.
  /// Used to lock the requirement dropdown after scanning has started.
  static Future<int> countAttendanceForEvent(String eventId) async {
    final data = await supabase
        .from('attendance_records')
        .select('id')
        .eq('event_id', eventId);
    return (data as List).length;
  }

  // ── Attendance ────────────────────────────────────────────────────────────

  /// Looks up a profile by student_id field (e.g. "2024-0001").
  static Future<Profile?> fetchStudentByStudentId(String studentId) async {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('student_id', studentId)
        .maybeSingle();
    if (data == null) return null;
    return Profile.fromMap(data);
  }

  /// Returns all attendance records for an event, with student profile info.
  static Future<List<Map<String, dynamic>>> fetchAttendanceForEvent(
      String eventId) async {
    final data = await supabase
        .from('attendance_records')
        .select('id, scanned_at, attendance_type, student:profiles!attendance_records_student_id_fkey(id, first_name, last_name, student_id, course, year_level, avatar_url)')
        .eq('event_id', eventId)
        .order('scanned_at', ascending: true);
    return List<Map<String, dynamic>>.from(data as List);
  }

  /// Checks if a student already has a submitted/approved requirement_submission
  /// for the given requirement. Used to show "already fulfilled" in the dialog.
  static Future<bool> isRequirementAlreadyFulfilled({
    required String studentProfileId,
    required String requirementId,
  }) async {
    final data = await supabase
        .from('requirement_submissions')
        .select('id')
        .eq('student_id', studentProfileId)
        .eq('requirement_id', requirementId)
        .inFilter('status', ['submitted', 'approved'])
        .maybeSingle();
    return data != null;
  }

  /// Checks if a student already has a TIME IN (log_in) record for a given event.
  static Future<bool> hasStudentTimeIn({
    required String eventId,
    required String studentProfileId,
  }) async {
    final data = await supabase
        .from('attendance_records')
        .select('id')
        .eq('event_id', eventId)
        .eq('student_id', studentProfileId)
        .eq('attendance_type', 'log_in')
        .maybeSingle();
    return data != null;
  }

  /// Inserts an attendance record. The DB trigger auto-fulfills the clearance item.
  /// Returns the inserted row. Throws on duplicate or error.
  static Future<Map<String, dynamic>> recordAttendance({
    required String eventId,
    required String studentProfileId,
    required String attendanceType,
  }) async {
    final uid = supabase.auth.currentUser!.id;
    final data = await supabase.from('attendance_records').insert({
      'event_id': eventId,
      'student_id': studentProfileId,
      'scanned_by': uid,
      'attendance_type': attendanceType,
    }).select().single();
    return data;
  }
}
