import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orange_quality_checker/providers/app_provider.dart';
import 'package:orange_quality_checker/widgets/empty_state.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key = const ValueKey('history_screen')});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scans = ref.watch(scanHistoryProvider);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: scans.isEmpty
          ? const Center(
              child: EmptyState(
                icon: Icons.history,
                title: 'No scan history yet',
                message: 'Your scan history will appear here',
              ),
            )
          : ListView.builder(
              itemCount: scans.length,
              itemBuilder: (context, index) {
                final scan = scans[index];
                return Slidable(
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (_) {
                          ref.read(scanHistoryProvider.notifier).removeScan(scan.id);
                        },
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: 'Delete',
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: SizedBox(
                      width: 56,
                      height: 56,
                      child: Image.asset(
                        scan.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(scan.title),
                    subtitle: Text(
                      _formatDate(scan.timestamp),
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: _buildQualityBadge(scan.quality, theme),
                    onTap: () => context.push('/scan-detail/${scan.id}'),
                  ),
                );
              },
            ),
    );
  }
  
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (date == today) {
      return 'Today, ${DateFormat.jm().format(dateTime)}';
    } else if (date == yesterday) {
      return 'Yesterday, ${DateFormat.jm().format(dateTime)}';
    } else {
      return DateFormat.yMMMd().add_jm().format(dateTime);
    }
  }
  
  Widget _buildQualityBadge(int quality, ThemeData theme) {
    Color color;
    String label;
    
    if (quality >= 90) {
      color = Colors.green;
      label = 'Excellent';
    } else if (quality >= 70) {
      color = Colors.blue;
      label = 'Good';
    } else if (quality >= 50) {
      color = Colors.orange;
      label = 'Fair';
    } else {
      color = Colors.red;
      label = 'Poor';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 