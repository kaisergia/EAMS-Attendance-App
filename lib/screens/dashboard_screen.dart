import 'package:flutter/material.dart';
import '../models/profile.dart';
import '../models/organization.dart';
import '../models/event.dart';
import '../services/supabase_service.dart';
import '../widgets/event_card.dart';
import '../theme/colors.dart';
import '../screens/login_screen.dart';
import '../screens/requirements_screen.dart';
import 'attendance_screen.dart';
import 'attendance_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Profile profile;
  final Organization? organization;

  const DashboardScreen({required this.profile, this.organization, super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Event> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (widget.organization == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final events = await SupabaseService.fetchEventsForSource(
          widget.organization!.sourceType, widget.organization!.id);
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load events: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgName = widget.organization?.name ?? 'No organization assigned';
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryRed,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Events',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Text(
              orgName,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          if (widget.organization != null)
            IconButton(
              icon: const Icon(Icons.checklist, color: Colors.white),
              tooltip: 'Requirements',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      RequirementsScreen(organization: widget.organization!),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryRed),
            )
          : RefreshIndicator(
              color: primaryRed,
              onRefresh: _loadEvents,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.organization == null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No organization is linked to your account. '
                                'Please contact an admin.',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Text(
                        'Events for ${widget.organization!.name}',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                                color: darkRed, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Logged in as ${widget.profile.fullName.isNotEmpty ? widget.profile.fullName : widget.profile.email}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      if (_events.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                Icon(Icons.event_busy,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  'No events yet.\nTap + to create one.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: _events.length,
                          itemBuilder: (context, index) {
                            final event = _events[index];
                            return EventCard(
                              event: event,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AttendanceScreen(event: event),
                                ),
                              ),
                              onViewHistory: () =>
                                  Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AttendanceHistoryScreen(event: event),
                                ),
                              ),
                              onEdit: () => _showEditEventDialog(event),
                              onDelete: () => _confirmDeleteEvent(event),
                            );
                          },
                        ),
                      const SizedBox(height: 24),
                      Center(
                        child: FloatingActionButton.extended(
                          backgroundColor: primaryRed,
                          onPressed: _showCreateEventDialog,
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            'Add Event',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _showCreateEventDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool isCreating = false;
    DateTime selectedDate = DateTime.now();

    // Load requirements before opening dialog — no flicker
    final List<Map<String, dynamic>> attendanceReqs =
        widget.organization != null
            ? await SupabaseService.fetchAttendanceRequirementsForSource(
                widget.organization!.sourceType, widget.organization!.id)
            : [];
    String? selectedReqId;
    bool requireLogout = false;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: backgroundColor,
            title: const Text(
              'Create New Event',
              style: TextStyle(color: darkRed, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Event Name',
                      labelStyle: const TextStyle(color: primaryRed),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: primaryRed),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: const TextStyle(color: primaryRed),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: primaryRed),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: isCreating
                        ? null
                        : () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              builder: (ctx, child) => Theme(
                                data: Theme.of(ctx).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: primaryRed,
                                  ),
                                ),
                                child: child!,
                              ),
                            );
                            if (picked != null) {
                              setDialogState(() => selectedDate = picked);
                              // Re-check conflict when date changes
                              if (selectedReqId != null) {
                                final conflict = _events.any((e) =>
                                  e.requirementId == selectedReqId &&
                                  e.eventDate.year == picked.year &&
                                  e.eventDate.month == picked.month &&
                                  e.eventDate.day == picked.day,
                                );
                                if (conflict && ctx.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Warning: another event on this date already uses this requirement.',
                                      ),
                                      backgroundColor: Colors.orange,
                                      duration: Duration(seconds: 4),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: primaryRed),
                      foregroundColor: primaryRed,
                    ),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      '${selectedDate.year}-'
                      '${selectedDate.month.toString().padLeft(2, '0')}-'
                      '${selectedDate.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: selectedReqId,
                    decoration: InputDecoration(
                      labelText: 'Linked Requirement (optional)',
                      labelStyle: const TextStyle(color: primaryRed),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: primaryRed),
                      ),
                    ),
                    hint: Text(
                      attendanceReqs.isEmpty
                          ? 'No attendance requirements'
                          : 'Select requirement',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('None'),
                      ),
                      ...attendanceReqs.map((r) => DropdownMenuItem<String?>(
                            value: r['id'] as String,
                            child: Text(r['name'] as String),
                          )),
                    ],
                    onChanged: (v) {
                      setDialogState(() => selectedReqId = v);
                      if (v != null) {
                        final conflict = _events.any((e) =>
                          e.requirementId == v &&
                          e.eventDate.year == selectedDate.year &&
                          e.eventDate.month == selectedDate.month &&
                          e.eventDate.day == selectedDate.day,
                        );
                        if (conflict) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Warning: another event on this date already uses this requirement.',
                              ),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 4),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: requireLogout,
                    onChanged: isCreating
                        ? null
                        : (v) => setDialogState(
                            () => requireLogout = v ?? false),
                    title: const Text(
                      'Require Time Out',
                      style: TextStyle(fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Only count attendance when both time in and time out are recorded',
                      style: TextStyle(fontSize: 11),
                    ),
                    activeColor: primaryRed,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isCreating ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: primaryRed)),
              ),
              TextButton(
                onPressed: isCreating
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Event name cannot be empty.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        setDialogState(() => isCreating = true);
                        final nav = Navigator.of(ctx);
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final event = await SupabaseService.createEvent(
                            sourceType: widget.organization!.sourceType,
                            sourceId: widget.organization!.id,
                            name: name,
                            description: descController.text.trim(),
                            eventDate: selectedDate,
                            requirementId: selectedReqId,
                            requireLogout: requireLogout,
                          );
                          if (mounted) {
                            setState(() => _events.insert(0, event));
                            nav.pop();
                          }
                        } catch (e) {
                          setDialogState(() => isCreating = false);
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                  content: Text('Failed to create event: $e'),
                                  backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                child: isCreating
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: primaryRed))
                    : const Text('Create',
                        style: TextStyle(color: primaryRed)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showEditEventDialog(Event event) async {
    final nameController = TextEditingController(text: event.name);
    final descController = TextEditingController(text: event.description);
    bool isSaving = false;
    DateTime selectedDate = event.eventDate;
    bool requireLogout = event.requireLogout;

    // Load requirements + attendance count before opening dialog
    final List<Map<String, dynamic>> attendanceReqs =
        widget.organization != null
            ? await SupabaseService.fetchAttendanceRequirementsForSource(
                widget.organization!.sourceType, widget.organization!.id)
            : [];
    final int attendanceCount =
        await SupabaseService.countAttendanceForEvent(event.id);
    // Only lock if a requirement is already linked AND attendance exists
    final bool requirementLocked =
        attendanceCount > 0 && event.requirementId != null;

    // Pre-select the event's linked requirement if it exists in the list
    final exists = attendanceReqs.any((r) => r['id'] == event.requirementId);
    String? selectedReqId = exists ? event.requirementId : null;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: backgroundColor,
            title: const Text(
              'Edit Event',
              style: TextStyle(color: darkRed, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Event Name',
                      labelStyle: const TextStyle(color: primaryRed),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: primaryRed),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: const TextStyle(color: primaryRed),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: primaryRed),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              builder: (ctx, child) => Theme(
                                data: Theme.of(ctx).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: primaryRed,
                                  ),
                                ),
                                child: child!,
                              ),
                            );
                            if (picked != null) {
                              setDialogState(() => selectedDate = picked);
                              if (selectedReqId != null) {
                                final conflict = _events.any((e) =>
                                  e.id != event.id &&
                                  e.requirementId == selectedReqId &&
                                  e.eventDate.year == picked.year &&
                                  e.eventDate.month == picked.month &&
                                  e.eventDate.day == picked.day,
                                );
                                if (conflict && ctx.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Warning: another event on this date already uses this requirement.',
                                      ),
                                      backgroundColor: Colors.orange,
                                      duration: Duration(seconds: 4),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: primaryRed),
                      foregroundColor: primaryRed,
                    ),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      '${selectedDate.year}-'
                      '${selectedDate.month.toString().padLeft(2, '0')}-'
                      '${selectedDate.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  IgnorePointer(
                    ignoring: requirementLocked,
                    child: Opacity(
                      opacity: requirementLocked ? 0.5 : 1.0,
                      child: DropdownButtonFormField<String?>(
                        value: selectedReqId,
                        decoration: InputDecoration(
                          labelText: 'Linked Requirement (optional)',
                          labelStyle: const TextStyle(color: primaryRed),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: primaryRed),
                          ),
                        ),
                        hint: Text(
                          attendanceReqs.isEmpty
                              ? 'No attendance requirements'
                              : 'Select requirement',
                          style: TextStyle(color: Colors.grey[500], fontSize: 14),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('None'),
                          ),
                          ...attendanceReqs.map((r) => DropdownMenuItem<String?>(
                                value: r['id'] as String,
                                child: Text(r['name'] as String),
                              )),
                        ],
                        onChanged: requirementLocked
                            ? null
                            : (v) {
                                setDialogState(() => selectedReqId = v);
                                if (v != null) {
                                  final conflict = _events.any((e) =>
                                    e.id != event.id &&
                                    e.requirementId == v &&
                                    e.eventDate.year == selectedDate.year &&
                                    e.eventDate.month == selectedDate.month &&
                                    e.eventDate.day == selectedDate.day,
                                  );
                                  if (conflict) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Warning: another event on this date already uses this requirement.',
                                        ),
                                        backgroundColor: Colors.orange,
                                        duration: Duration(seconds: 4),
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                    ),
                  ),
                  if (requirementLocked) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline,
                              size: 16, color: Colors.amber.shade800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Requirement cannot be changed after attendance '
                              'has been recorded ($attendanceCount scan${attendanceCount == 1 ? '' : 's'}).',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.amber.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: requireLogout,
                    onChanged: isSaving
                        ? null
                        : (v) => setDialogState(
                            () => requireLogout = v ?? false),
                    title: const Text(
                      'Require Time Out',
                      style: TextStyle(fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Only count attendance when both time in and time out are recorded',
                      style: TextStyle(fontSize: 11),
                    ),
                    activeColor: primaryRed,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: primaryRed)),
              ),
              TextButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Event name cannot be empty.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        setDialogState(() => isSaving = true);
                        final nav = Navigator.of(ctx);
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final updated = await SupabaseService.updateEvent(
                            eventId: event.id,
                            name: name,
                            description: descController.text.trim(),
                            eventDate: selectedDate,
                            requirementId: selectedReqId,
                            clearRequirement: selectedReqId == null,
                            previousRequirementId: event.requirementId,
                            requireLogout: requireLogout,
                          );
                          if (mounted) {
                            setState(() {
                              final idx =
                                  _events.indexWhere((e) => e.id == event.id);
                              if (idx != -1) _events[idx] = updated;
                            });
                            nav.pop();
                          }
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Failed to update event: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: primaryRed))
                    : const Text('Save', style: TextStyle(color: primaryRed)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteEvent(Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: backgroundColor,
        title: const Text(
          'Delete Event',
          style: TextStyle(color: darkRed, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${event.name}"?\n\n'
          'This will also delete all attendance records for this event.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: primaryRed)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await SupabaseService.deleteEvent(event.id);
      if (mounted) {
        setState(() => _events.removeWhere((e) => e.id == event.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event deleted.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    await SupabaseService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }
}
