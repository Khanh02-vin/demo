import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { Image } from 'expo-image';
import { ScanResult } from '@/types/scan';
import { QualityBadge } from './QualityBadge';
import { colors } from '@/constants/colors';
import { theme } from '@/constants/theme';

interface ScanHistoryItemProps {
  scan: ScanResult;
  onPress: (scan: ScanResult) => void;
}

export const ScanHistoryItem: React.FC<ScanHistoryItemProps> = ({ scan, onPress }) => {
  const formatDate = (timestamp: number) => {
    const date = new Date(timestamp);
    return date.toLocaleString();
  };

  return (
    <TouchableOpacity 
      style={styles.container}
      onPress={() => onPress(scan)}
      activeOpacity={0.7}
    >
      <Image
        source={{ uri: scan.imageUri }}
        style={styles.image}
        contentFit="cover"
      />
      <View style={styles.content}>
        <View style={styles.header}>
          <QualityBadge quality={scan.quality} size="small" />
          <Text style={styles.date}>{formatDate(scan.timestamp)}</Text>
        </View>
        <Text style={styles.confidence}>
          Confidence: {Math.round(scan.confidence * 100)}%
        </Text>
      </View>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    backgroundColor: colors.white,
    borderRadius: theme.borderRadius.md,
    marginBottom: theme.spacing.md,
    overflow: 'hidden',
    ...theme.shadows.sm,
  },
  image: {
    width: 80,
    height: 80,
  },
  content: {
    flex: 1,
    padding: theme.spacing.md,
    justifyContent: 'space-between',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: theme.spacing.xs,
  },
  date: {
    fontSize: 12,
    color: colors.textLight,
  },
  confidence: {
    fontSize: 14,
    color: colors.text,
  },
});