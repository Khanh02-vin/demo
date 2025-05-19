import 'package:flutter/material.dart';

class HistoryItem {
  final String id;
  final String imagePath;
  final DateTime timestamp;
  final bool isOrange;
  final String result;
  final Color resultColor;
  final double qualityScore;
  final Map<String, dynamic> detailedMetrics;

  HistoryItem({
    required this.id,
    required this.imagePath,
    required this.timestamp,
    required this.isOrange,
    required this.result,
    required this.resultColor,
    required this.qualityScore,
    required this.detailedMetrics,
  });

  // Convert to and from JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'timestamp': timestamp.toIso8601String(),
      'isOrange': isOrange,
      'result': result,
      'resultColor': resultColor.value,
      'qualityScore': qualityScore,
      'detailedMetrics': detailedMetrics,
    };
  }

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'],
      imagePath: json['imagePath'],
      timestamp: DateTime.parse(json['timestamp']),
      isOrange: json['isOrange'],
      result: json['result'],
      resultColor: Color(json['resultColor']),
      qualityScore: json['qualityScore'],
      detailedMetrics: Map<String, dynamic>.from(json['detailedMetrics']),
    );
  }
} 