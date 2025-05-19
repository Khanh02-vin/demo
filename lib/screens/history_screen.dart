import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orange_quality_checker/providers/app_provider.dart';
import 'package:orange_quality_checker/widgets/empty_state.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/history_item.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    );
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(refreshableHistoryProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Analysis History',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: 'Clear History',
            onPressed: () => _showClearConfirmation(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Scanned Oranges',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Track your orange quality analysis history',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: historyAsync.when(
                  data: (historyItems) {
                    if (historyItems.isEmpty) {
                      return _buildEmptyHistory();
                    }
                    return _buildHistoryList(context, historyItems, ref);
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ),
                  error: (error, stackTrace) => Center(
                    child: Text(
                      'Error loading history: $error',
                      style: GoogleFonts.poppins(color: Colors.white),
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
  
  Widget _buildEmptyHistory() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: child,
        );
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey.shade800,
                    Colors.grey.shade900,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.history,
                size: 60,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No History Yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your analyzed oranges will appear here',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 40),
            OutlinedButton.icon(
              onPressed: () => context.go('/color-detector'),
              icon: const Icon(Icons.camera_alt, color: Colors.orange),
              label: Text(
                'Scan an Orange',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                side: const BorderSide(color: Colors.orange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHistoryList(BuildContext context, List<HistoryItem> items, WidgetRef ref) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        
        // Calculate animation delay based on position
        final delay = 0.05 * index;
        final itemAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              delay.clamp(0.0, 0.9),
              (delay + 0.5).clamp(0.0, 1.0),
              curve: Curves.easeOutQuart,
            ),
          ),
        );
        
        return AnimatedBuilder(
          animation: itemAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - itemAnimation.value)),
              child: Opacity(
                opacity: itemAnimation.value,
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Slidable(
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (context) => _deleteItem(context, item.id, ref),
                    backgroundColor: Colors.red.shade800,
                    foregroundColor: Colors.white,
                    icon: Icons.delete,
                    label: 'Delete',
                    borderRadius: BorderRadius.circular(16),
                  ),
                ],
              ),
              child: _buildHistoryCard(context, item, dateFormat),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildHistoryCard(BuildContext context, HistoryItem item, DateFormat dateFormat) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2C2C2E),
            const Color(0xFF1C1C1E),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showHistoryDetails(context, item),
            splashColor: item.resultColor.withOpacity(0.1),
            highlightColor: item.resultColor.withOpacity(0.05),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        item.resultColor.withOpacity(0.3),
                        item.resultColor.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getIconForResult(item.result),
                        color: item.resultColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.result,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: item.resultColor,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        dateFormat.format(item.timestamp),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Image
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _buildImage(item.imagePath),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Quality: ',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${(item.qualityScore * 100).toInt()}%',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: _getQualityColor(item.qualityScore),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Type: ',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  item.isOrange ? 'Orange' : 'Not an Orange',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: item.isOrange ? Colors.orange : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildQualityBar(item.qualityScore, _getQualityColor(item.qualityScore)),
                          ],
                        ),
                      ),
                      
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade800.withOpacity(0.5),
                        ),
                        child: const Icon(
                          Icons.chevron_right,
                          color: Colors.white70,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildImage(String path) {
    try {
      final file = File(path);
      if (!file.existsSync()) {
        return Container(
          color: Colors.grey.shade800,
          child: const Icon(
            Icons.broken_image,
            color: Colors.white54,
          ),
        );
      }
      return Image.file(
        file,
        fit: BoxFit.cover,
      );
    } catch (e) {
      return Container(
        color: Colors.grey.shade800,
        child: const Icon(
          Icons.error_outline,
          color: Colors.white54,
        ),
      );
    }
  }
  
  Widget _buildQualityBar(double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            // Background
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey.shade800,
              ),
            ),
            // Progress with gradient
            Container(
              height: 8,
              width: MediaQuery.of(context).size.width * 0.35 * value,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    color.withOpacity(0.7),
                    color,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  IconData _getIconForResult(String result) {
    final lowercaseResult = result.toLowerCase();
    
    if (lowercaseResult.contains('good quality')) {
      return Icons.check_circle;
    } else if (lowercaseResult.contains('fair quality')) {
      return Icons.info;
    } else if (lowercaseResult.contains('surface damaged')) {
      return Icons.warning;
    } else if (lowercaseResult.contains('moldy')) {
      return Icons.dangerous;
    } else if (lowercaseResult.contains('rotten')) {
      return Icons.sentiment_very_dissatisfied;
    } else if (lowercaseResult.contains('unripe')) {
      return Icons.access_time;
    } else if (lowercaseResult.contains('not an orange') || 
               lowercaseResult.contains('not orange')) {
      return Icons.help_outline;
    }
    
    return Icons.circle;
  }
  
  Color _getQualityColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.lightGreen;
    if (score >= 0.4) return Colors.amber;
    if (score >= 0.2) return Colors.orange;
    return Colors.red;
  }
  
  Future<void> _showHistoryDetails(BuildContext context, HistoryItem item) async {
    // Implementation for showing history details
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    item.resultColor.withOpacity(0.3),
                    item.resultColor.withOpacity(0.1),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getIconForResult(item.result),
                    color: item.resultColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item.result,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: item.resultColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _buildImage(item.imagePath),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Details
                  _buildDetailItem(
                    'Type',
                    item.isOrange ? 'Orange' : 'Not an Orange',
                    item.isOrange ? Icons.check_circle : Icons.cancel,
                    item.isOrange ? Colors.green : Colors.red,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailItem(
                    'Quality Score',
                    '${(item.qualityScore * 100).toInt()}%',
                    Icons.speed,
                    _getQualityColor(item.qualityScore),
                  ),
                  const SizedBox(height: 8),
                  
                  // Show metrics if available
                  if (item.detailedMetrics.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Detailed Metrics',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    if (item.detailedMetrics.containsKey('colorConsistency'))
                      _buildMetricBar(
                        'Color Consistency',
                        item.detailedMetrics['colorConsistency'] as double,
                        Colors.blue,
                      ),
                      
                    if (item.detailedMetrics.containsKey('surfaceIrregularities'))
                      _buildMetricBar(
                        'Surface Quality',
                        1.0 - (item.detailedMetrics['surfaceIrregularities'] as double),
                        Colors.purple,
                      ),
                  ],
                ],
              ),
            ),
            
            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Close',
                      style: GoogleFonts.poppins(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMetricBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              Text(
                '${(value * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.grey.shade800,
                ),
              ),
              Container(
                height: 8,
                width: MediaQuery.of(context).size.width * 0.7 * value,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      color.withOpacity(0.7),
                      color,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteItem(BuildContext context, String id, WidgetRef ref) async {
    final historyService = ref.read(historyServiceProvider);
    await historyService.deleteHistoryItem(id);
    refreshHistory(ref);
  }
  
  Future<void> _showClearConfirmation(BuildContext context, WidgetRef ref) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Clear History',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to clear all history items? This action cannot be undone.',
          style: GoogleFonts.poppins(
            color: Colors.grey[300],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final historyService = ref.read(historyServiceProvider);
              await historyService.clearHistory();
              refreshHistory(ref);
            },
            child: Text(
              'Clear',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 