import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { QualityResult } from '@/types/scan';
import { colors, qualityColors } from '@/constants/colors';
import { theme } from '@/constants/theme';

interface QualityBadgeProps {
  quality: QualityResult;
  confidence?: number;
  size?: 'small' | 'medium' | 'large';
}

export const QualityBadge: React.FC<QualityBadgeProps> = ({ 
  quality, 
  confidence, 
  size = 'medium' 
}) => {
  const getQualityColor = () => {
    return qualityColors[quality];
  };
  
  const getQualityLabel = () => {
    return quality.charAt(0).toUpperCase() + quality.slice(1);
  };
  
  return (
    <View style={[
      styles.badge, 
      { backgroundColor: getQualityColor() },
      styles[`${size}Badge`]
    ]}>
      <Text style={[styles.label, styles[`${size}Text`]]}>
        {getQualityLabel()}
        {confidence !== undefined && ` (${Math.round(confidence * 100)}%)`}
      </Text>
    </View>
  );
};

const styles = StyleSheet.create({
  badge: {
    borderRadius: theme.borderRadius.full,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.xs,
    alignSelf: 'flex-start',
    ...theme.shadows.sm,
  },
  smallBadge: {
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: 2,
  },
  mediumBadge: {
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.xs,
  },
  largeBadge: {
    paddingHorizontal: theme.spacing.lg,
    paddingVertical: theme.spacing.sm,
  },
  label: {
    color: colors.white,
    fontWeight: '600',
  },
  smallText: {
    fontSize: 10,
  },
  mediumText: {
    fontSize: 12,
  },
  largeText: {
    fontSize: 14,
  },
});