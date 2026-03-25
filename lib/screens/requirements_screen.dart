import 'package:flutter/material.dart';
import '../models/organization.dart';
import '../services/supabase_service.dart';
import '../theme/colors.dart';

class RequirementsScreen extends StatefulWidget {
  final Organization organization;

  const RequirementsScreen({required this.organization, super.key});

  @override
  State<RequirementsScreen> createState() => _RequirementsScreenState();
}

class _RequirementsScreenState extends State<RequirementsScreen> {
  List<Map<String, dynamic>> _requirements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequirements();
  }

  Future<void> _loadRequirements() async {
    setState(() => _isLoading = true);
    try {
      final reqs = await SupabaseService.fetchRequirementsForSource(
          widget.organization.sourceType, widget.organization.id);
      setState(() {
        _requirements = reqs;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load requirements: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Requirements',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.organization.name,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Add Requirement',
            onPressed: _showCreateDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryRed))
          : RefreshIndicator(
              color: primaryRed,
              onRefresh: _loadRequirements,
              child: _requirements.isEmpty
                  ? ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 60),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.checklist,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  'No requirements yet.\nTap + to create one.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _requirements.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final req = _requirements[index];
                        return _RequirementCard(
                          req: req,
                          onEdit: () => _showEditDialog(req),
                          onDelete: () => _confirmDelete(req),
                          onTogglePublish: () => _togglePublish(req),
                        );
                      },
                    ),
            ),
    );
  }

  void _showCreateDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool isRequired = true;
    bool requiresUpload = false;
    bool isAttendance = false;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: backgroundColor,
          title: const Text(
            'New Requirement',
            style: TextStyle(color: darkRed, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: _inputDecoration('Name *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: _inputDecoration('Description (optional)'),
                ),
                const SizedBox(height: 12),
                _ToggleRow(
                  label: 'Required',
                  value: isRequired,
                  onChanged: (v) => setDialogState(() => isRequired = v),
                ),
                _ToggleRow(
                  label: 'Requires file upload',
                  value: requiresUpload,
                  enabled: !isAttendance,
                  onChanged: (v) =>
                      setDialogState(() => requiresUpload = v),
                ),
                _ToggleRow(
                  label: 'Fulfilled via attendance scan only',
                  value: isAttendance,
                  onChanged: (v) => setDialogState(() {
                    isAttendance = v;
                    if (v) requiresUpload = false;
                  }),
                ),
                if (isAttendance)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Students cannot manually submit this. '
                            'Staff must scan them.',
                            style: TextStyle(
                                color: Colors.blue, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: primaryRed)),
            ),
            TextButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Name is required.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      setDialogState(() => isSaving = true);
                      final nav = Navigator.of(ctx);
                      try {
                        await SupabaseService.createRequirement(
                          sourceType: widget.organization.sourceType,
                          sourceId: widget.organization.id,
                          name: name,
                          description: descController.text.trim(),
                          isRequired: isRequired,
                          requiresUpload: requiresUpload,
                          isAttendance: isAttendance,
                        );
                        if (mounted) {
                          nav.pop();
                          await _loadRequirements();
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to create: $e'),
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
                  : const Text('Create',
                      style: TextStyle(color: primaryRed)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> req) {
    final nameController = TextEditingController(text: req['name'] as String);
    final descController =
        TextEditingController(text: req['description'] as String? ?? '');
    bool isRequired = req['is_required'] as bool? ?? true;
    bool requiresUpload = req['requires_upload'] as bool? ?? false;
    bool isAttendance = req['is_attendance'] as bool? ?? false;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: backgroundColor,
          title: const Text(
            'Edit Requirement',
            style: TextStyle(color: darkRed, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: _inputDecoration('Name *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: _inputDecoration('Description (optional)'),
                ),
                const SizedBox(height: 12),
                _ToggleRow(
                  label: 'Required',
                  value: isRequired,
                  onChanged: (v) => setDialogState(() => isRequired = v),
                ),
                _ToggleRow(
                  label: 'Requires file upload',
                  value: requiresUpload,
                  enabled: !isAttendance,
                  onChanged: (v) =>
                      setDialogState(() => requiresUpload = v),
                ),
                _ToggleRow(
                  label: 'Fulfilled via attendance scan only',
                  value: isAttendance,
                  onChanged: (v) => setDialogState(() {
                    isAttendance = v;
                    if (v) requiresUpload = false;
                  }),
                ),
                if (isAttendance)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Students cannot manually submit this. '
                            'Staff must scan them.',
                            style: TextStyle(
                                color: Colors.blue, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: primaryRed)),
            ),
            TextButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Name is required.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      setDialogState(() => isSaving = true);
                      final nav = Navigator.of(ctx);
                      try {
                        await SupabaseService.updateRequirement(
                          id: req['id'] as String,
                          name: name,
                          description: descController.text.trim(),
                          isRequired: isRequired,
                          requiresUpload: requiresUpload,
                          isAttendance: isAttendance,
                        );
                        if (mounted) {
                          nav.pop();
                          await _loadRequirements();
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update: $e'),
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
                  : const Text('Save',
                      style: TextStyle(color: primaryRed)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> req) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: backgroundColor,
        title: const Text(
          'Delete Requirement',
          style: TextStyle(color: darkRed, fontWeight: FontWeight.bold),
        ),
        content: Text(
            'Delete "${req['name']}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Cancel', style: TextStyle(color: primaryRed)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await SupabaseService.deleteRequirement(req['id'] as String);
      if (mounted) {
        setState(() =>
            _requirements.removeWhere((r) => r['id'] == req['id']));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Requirement deleted.'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _togglePublish(Map<String, dynamic> req) async {
    final newValue = !(req['is_published'] as bool? ?? false);
    try {
      await SupabaseService.updateRequirement(
          id: req['id'] as String, isPublished: newValue);
      if (mounted) {
        setState(() {
          final idx = _requirements.indexWhere((r) => r['id'] == req['id']);
          if (idx != -1) {
            _requirements[idx] = {
              ..._requirements[idx],
              'is_published': newValue
            };
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: primaryRed),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryRed),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _RequirementCard extends StatelessWidget {
  final Map<String, dynamic> req;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePublish;

  const _RequirementCard({
    required this.req,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePublish,
  });

  @override
  Widget build(BuildContext context) {
    final isPublished = req['is_published'] as bool? ?? false;
    final isRequired = req['is_required'] as bool? ?? true;
    final requiresUpload = req['requires_upload'] as bool? ?? false;
    final isAttendance = req['is_attendance'] as bool? ?? false;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    req['name'] as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: darkRed),
                  ),
                ),
                // Publish toggle
                GestureDetector(
                  onTap: onTogglePublish,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPublished
                          ? Colors.green.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isPublished
                              ? Colors.green
                              : Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPublished ? Icons.visibility : Icons.visibility_off,
                          size: 12,
                          color: isPublished ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPublished ? 'Live' : 'Draft',
                          style: TextStyle(
                              fontSize: 11,
                              color: isPublished
                                  ? Colors.green
                                  : Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if ((req['description'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                req['description'] as String,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _chip(
                  isRequired ? 'Required' : 'Optional',
                  isRequired ? Colors.red.shade100 : Colors.grey.shade100,
                  isRequired ? Colors.red.shade700 : Colors.grey[600]!,
                ),
                if (requiresUpload)
                  _chip('Upload', Colors.blue.shade50, Colors.blue.shade700),
                if (isAttendance)
                  _chip('Scan Only', Colors.indigo.shade50,
                      Colors.indigo.shade700,
                      icon: Icons.qr_code_scanner),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Edit', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: primaryRed,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                  ),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 14),
                  label:
                      const Text('Delete', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 4),
          ],
          Text(label, style: TextStyle(fontSize: 11, color: fg)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: primaryRed,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: enabled ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
