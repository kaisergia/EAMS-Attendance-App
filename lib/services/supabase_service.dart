import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../models/office.dart';
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
  /// Throws if role != 'office'.
  static Future<Profile> fetchCurrentProfile() async {
    final uid = supabase.auth.currentUser!.id;
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', uid)
        .single();
    final profile = Profile.fromMap(data);
    if (profile.role != 'office') {
      throw Exception('This app is for office staff only.');
    }
    return profile;
  }

  // ── Office ────────────────────────────────────────────────────────────────

  /// Returns the office where head_id = current user's uid.
  static Future<Office?> fetchMyOffice() async {
    final uid = supabase.auth.currentUser!.id;
    final data = await supabase
        .from('offices')
        .select()
        .eq('head_id', uid)
        .maybeSingle();
    if (data == null) return null;
    return Office.fromMap(data);
  }

  // ── Events ────────────────────────────────────────────────────────────────

  static Future<List<Event>> fetchEventsForOffice(String officeId) async {
    final data = await supabase
        .from('events')
        .select('*, requirement:requirements(id, name)')
        .eq('office_id', officeId)
        .order('event_date', ascending: false);
    return (data as List).map((e) => Event.fromMap(e)).toList();
  }

  static Future<Event> createEvent({
    required String officeId,
    required String name,
    required String description,
    required DateTime eventDate,
    String? requirementId,
  }) async {
    final uid = supabase.auth.currentUser!.id;
    final data = await supabase.from('events').insert({
      'office_id': officeId,
      'name': name,
      'description': description,
      'event_date': eventDate.toIso8601String(),
      'created_by': uid,
      'is_active': true,
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
  }) async {
    final data = await supabase
        .from('events')
        .update({
          'name': name,
          'description': description,
          'event_date': eventDate.toIso8601String(),
          'requirement_id': clearRequirement ? null : requirementId,
        })
        .eq('id', eventId)
        .select('*, requirement:requirements(id, name)')
        .single();
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

  /// Returns all requirements for an office (for management screen).
  static Future<List<Map<String, dynamic>>> fetchRequirementsForOffice(
      String officeId) async {
    final data = await supabase
        .from('requirements')
        .select()
        .eq('source_type', 'office')
        .eq('source_id', officeId)
        .order('order', ascending: true);
    return List<Map<String, dynamic>>.from(data as List);
  }

  /// Returns only attendance-based requirements for the event requirement dropdown.
  static Future<List<Map<String, dynamic>>> fetchAttendanceRequirementsForOffice(
      String officeId) async {
    final data = await supabase
        .from('requirements')
        .select('id, name')
        .eq('source_type', 'office')
        .eq('source_id', officeId)
        .eq('is_attendance', true)
        .order('order', ascending: true);
    return List<Map<String, dynamic>>.from(data as List);
  }

  static Future<Map<String, dynamic>> createRequirement({
    required String officeId,
    required String name,
    String? description,
    bool isRequired = true,
    bool requiresUpload = false,
    bool isAttendance = false,
  }) async {
    final existing = await supabase
        .from('requirements')
        .select('order')
        .eq('source_type', 'office')
        .eq('source_id', officeId)
        .order('order', ascending: false)
        .limit(1);
    final nextOrder = (existing as List).isNotEmpty
        ? ((existing.first['order'] as int? ?? 0) + 1)
        : 0;

    final data = await supabase.from('requirements').insert({
      'source_type': 'office',
      'source_id': officeId,
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
        .select('id, scanned_at, student:profiles!attendance_records_student_id_fkey(id, first_name, last_name, student_id, course, year_level, avatar_url)')
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

  /// Inserts an attendance record. The DB trigger auto-fulfills the clearance item.
  /// Returns the inserted row. Throws on duplicate or error.
  static Future<Map<String, dynamic>> recordAttendance({
    required String eventId,
    required String studentProfileId,
  }) async {
    final uid = supabase.auth.currentUser!.id;
    final data = await supabase.from('attendance_records').insert({
      'event_id': eventId,
      'student_id': studentProfileId,
      'scanned_by': uid,
    }).select().single();
    return data;
  }
}
