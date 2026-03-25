import 'package:flutter/material.dart';
import '../models/event.dart';
import '../theme/colors.dart';

class EventCard extends StatefulWidget {
  final Event event;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onViewHistory;

  const EventCard({
    required this.event,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onViewHistory,
    super.key,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _animController.forward().then((_) {
      _animController.reverse();
      widget.onTap();
    });
  }

  void _showContextMenu(BuildContext context) {
    final hasActions =
        widget.onEdit != null || widget.onDelete != null || widget.onViewHistory != null;
    if (!hasActions) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.event.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: darkRed,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1),
            if (widget.onViewHistory != null)
              ListTile(
                leading: const Icon(Icons.people_outline, color: primaryRed),
                title: const Text('View Attendance'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onViewHistory!();
                },
              ),
            if (widget.onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: primaryRed),
                title: const Text('Edit Event'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onEdit!();
                },
              ),
            if (widget.onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Event',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  widget.onDelete!();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${widget.event.eventDate.day}/${widget.event.eventDate.month}/${widget.event.eventDate.year}';

    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTap: _handleTap,
        onLongPress: () => _showContextMenu(context),
        child: Container(
          constraints: const BoxConstraints(minHeight: 180, maxHeight: 210),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            border: Border.all(color: Colors.black12),
            boxShadow: [
              BoxShadow(
                color: primaryRed.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryRed.withValues(alpha: 0.15),
                    ),
                    child: const Icon(Icons.event, color: primaryRed, size: 28),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      widget.event.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: darkRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (widget.event.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 2),
                      child: Text(
                        widget.event.description,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 10),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: TextStyle(color: Colors.grey[400], fontSize: 10),
                  ),
                  const Spacer(),
                  // View Attendance button
                  if (widget.onViewHistory != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: SizedBox(
                        width: double.infinity,
                        height: 28,
                        child: OutlinedButton.icon(
                          onPressed: widget.onViewHistory,
                          icon: const Icon(Icons.people_outline, size: 14),
                          label: const Text(
                            'Attendance',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryRed,
                            side: BorderSide(color: primaryRed.withValues(alpha: 0.3)),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Tappable 3-dot menu button
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _showContextMenu(context),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.more_vert,
                      size: 18,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
