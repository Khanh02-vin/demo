# Orange Quality Checker

A Flutter application for checking orange quality using machine learning.

## Features

- Camera integration for capturing orange images
- TensorFlow Lite for quality analysis
- Location tracking for data collection
- History of scans and results
- Detailed analysis reports

## Fallback Classification System

The application now includes a robust fallback classification system that can identify non-orange objects when the primary orange classifier has low confidence or detects a non-orange item.

### Features

- **Enhanced Classification**: The system now uses two-stage classification with primary and fallback models
- **Image Quality Checking**: Validates images before processing to ensure they meet minimum quality requirements
- **Improved Error Handling**: Provides meaningful error messages for invalid images or failed classifications
- **Better User Experience**: The UI now clearly distinguishes between orange classification and other objects

### Implementation Details

The fallback classification system consists of:

1. **ClassificationResult Model**: A structured result object that encapsulates both primary and fallback classification results
2. **ImageQualityChecker**: A utility that validates image quality before processing
3. **Enhanced OrangeClassifier**: The updated classifier service that implements the two-stage classification logic
4. **EnhancedResultDisplay Widget**: A UI component that displays classification results in a user-friendly format

### Usage

The application automatically determines when to apply fallback classification:

1. When the primary classification confidence is below the threshold (30%)
2. When the primary classification result is not an orange
3. When image quality checks fail

The user interface clearly indicates which classification was used and provides appropriate recommendations.

## Getting Started

### Prerequisites

- Flutter SDK
- Xcode for iOS development
- Android Studio for Android development

### Installation

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Connect a device or start an emulator
4. Run the app with `flutter run`

## Building for iOS

Make sure your iOS Info.plist has the required permission strings:
- NSCameraUsageDescription - For camera access
- NSLocationWhenInUseUsageDescription - For location services
