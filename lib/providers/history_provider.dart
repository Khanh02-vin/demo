import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/history_item.dart';
import '../services/history_service.dart';

// Provider for the history service instance
final historyServiceProvider = Provider<HistoryService>((ref) {
  return HistoryService();
});

// Provider that exposes the history items
final historyProvider = FutureProvider<List<HistoryItem>>((ref) async {
  final historyService = ref.watch(historyServiceProvider);
  return historyService.getHistory();
});

// Provider to refresh history when needed
final historyRefreshProvider = StateProvider<int>((ref) => 0);

// Provider that combines the refresh state with history items
final refreshableHistoryProvider = FutureProvider<List<HistoryItem>>((ref) async {
  // Watch the refresh provider to rebuild when it changes
  ref.watch(historyRefreshProvider);
  final historyService = ref.watch(historyServiceProvider);
  return historyService.getHistory();
});

// Function to force refresh of history
void refreshHistory(WidgetRef ref) {
  ref.read(historyRefreshProvider.notifier).state++;
} 