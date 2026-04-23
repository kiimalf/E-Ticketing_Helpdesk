import 'package:flutter/material.dart';
import 'package:eticketing_helpdesk/core/theme/app_theme.dart';
import 'package:eticketing_helpdesk/core/widgets/app_widgets.dart';
import 'package:eticketing_helpdesk/features/ticket/data/models/ticket_model.dart';

class TicketCardWidget extends StatelessWidget {
  const TicketCardWidget({
    super.key,
    required this.ticket,
    required this.onTap,
  });

  final TicketModel ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header: ticket number + priority ──────────
              Row(
                children: [
                  Flexible(
                    child: Text(
                      ticket.ticketNumber,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  PriorityBadge(priority: ticket.priority, small: true),
                ],
              ),
              const SizedBox(height: 8),

              // ── Title ──────────────────────────────────────
              Text(
                ticket.title,
                style: theme.textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // ── Description preview ────────────────────────
              Text(
                ticket.description,
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Status badge kiri
                  StatusBadge(status: ticket.status, small: true),

                  const Spacer(),

                  // Meta info kanan: komentar + waktu
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${ticket.comments.length}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        relativeTime(ticket.updatedAt),
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
