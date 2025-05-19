import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import '../models/history_item.dart';

class HistoryService {
  static const String _historyKey = 'orange_analyzer_history';
  final Uuid _uuid = const Uuid();
  
  // Get all history items
  Future<List<HistoryItem>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey) ?? [];
      
      final history = historyJson
          .map((item) => HistoryItem.fromJson(jsonDecode(item)))
          .toList();
      
      // Sort by most recent first
      history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return history;
    } catch (e) {
      debugPrint('Error loading history: $e');
      return [];
    }
  }
  
  // Save a new history item
  Future<void> saveHistoryItem(
    String originalImagePath,
    bool isOrange,
    String result,
    Color resultColor,
    double qualityScore,
    Map<String, dynamic> detailedMetrics,
  ) async {
    try {
      // First, copy the image to a permanent location in the app documents directory
      final permanentImagePath = await _saveImagePermanently(originalImagePath);
      
      final newItem = HistoryItem(
        id: _uuid.v4(),
        imagePath: permanentImagePath,
        timestamp: DateTime.now(),
        isOrange: isOrange,
        result: result,
        resultColor: resultColor,
        qualityScore: qualityScore,
        detailedMetrics: detailedMetrics,
      );
      
      // Get existing history
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey) ?? [];
      
      // Add new item to history
      historyJson.add(jsonEncode(newItem.toJson()));
      
      // Limit history to most recent 50 items
      if (historyJson.length > 50) {
        final List<HistoryItem> allItems = historyJson
            .map((item) => HistoryItem.fromJson(jsonDecode(item)))
            .toList();
        
        // Sort by most recent
        allItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        // Keep only the most recent 50 items
        final List<String> newHistoryJson = allItems
            .take(50)
            .map((item) => jsonEncode(item.toJson()))
            .toList();
        
        await prefs.setStringList(_historyKey, newHistoryJson);
        
        // Delete images for removed items
        for (int i = 50; i < allItems.length; i++) {
          final File imageFile = File(allItems[i].imagePath);
          if (await imageFile.exists()) {
            await imageFile.delete();
          }
        }
      } else {
        // Save history
        await prefs.setStringList(_historyKey, historyJson);
      }
    } catch (e) {
      debugPrint('Error saving history item: $e');
    }
  }
  
  // Copy images to a permanent location in app documents
  Future<String> _saveImagePermanently(String imagePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imageDirectory = Directory('${directory.path}/orange_images');
      
      // Create the directory if it doesn't exist
      if (!await imageDirectory.exists()) {
        await imageDirectory.create(recursive: true);
      }
      
      // Generate a unique filename for the image
      final filename = '${_uuid.v4()}${path.extension(imagePath)}';
      final targetPath = '${imageDirectory.path}/$filename';
      
      // Copy the file
      final File sourceFile = File(imagePath);
      final File newImage = await sourceFile.copy(targetPath);
      
      return newImage.path;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return imagePath; // Return original path if failed
    }
  }
  
  // Delete a history item
  Future<void> deleteHistoryItem(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey) ?? [];
      
      // Parse all items
      final List<HistoryItem> items = historyJson
          .map((item) => HistoryItem.fromJson(jsonDecode(item)))
          .toList();
      
      // Find the item to delete
      final itemToDelete = items.firstWhere((item) => item.id == id);
      
      // Delete the image file
      final File imageFile = File(itemToDelete.imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
      
      // Remove the item from the list
      items.removeWhere((item) => item.id == id);
      
      // Update storage
      final updatedHistoryJson = items
          .map((item) => jsonEncode(item.toJson()))
          .toList();
      
      await prefs.setStringList(_historyKey, updatedHistoryJson);
    } catch (e) {
      debugPrint('Error deleting history item: $e');
    }
  }
  
  // Clear all history
  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey) ?? [];
      
      // Parse all items to get image paths
      final List<HistoryItem> items = historyJson
          .map((item) => HistoryItem.fromJson(jsonDecode(item)))
          .toList();
      
      // Delete all image files
      for (final item in items) {
        final File imageFile = File(item.imagePath);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      }
      
      // Clear history
      await prefs.remove(_historyKey);
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }
} 