import 'dart:math';

import 'package:image/image.dart' as img;

// Threshold for considering brightness variation as shadow
const double _shadowThreshold = 0.25;

class ShadowAnalyzer {
  const ShadowAnalyzer();

  double detectShadows(img.Image image) {
    final grayscale = img.grayscale(image);
    const rows = 6; // More regions for better detection
    const cols = 6;
    final regionHeight = grayscale.height ~/ rows;
    final regionWidth = grayscale.width ~/ cols;

    final regionBrightness = <double>[];

    // Calculate average brightness for each region
    for (var i = 0; i < rows; i++) {
      for (var j = 0; j < cols; j++) {
        var brightness = 0;
        var pixels = 0;

        for (var y = i * regionHeight;
        y < (i + 1) * regionHeight && y < grayscale.height;
        y++) {
          for (var x = j * regionWidth;
          x < (j + 1) * regionWidth && x < grayscale.width;
          x++) {
            brightness += grayscale.getPixel(x, y).r.toInt();
            pixels++;
          }
        }

        if (pixels > 0) {
          regionBrightness.add(brightness / pixels);
        }
      }
    }

    if (regionBrightness.isEmpty) return 0;

    // Calculate brightness statistics
    final avgBrightness =
        regionBrightness.reduce((a, b) => a + b) / regionBrightness.length;

    // Calculate standard deviation
    final variance = regionBrightness.fold(0, (sum, brightness) {
      final diff = brightness - avgBrightness;

      return sum + (diff * diff).toInt();
    }) /
        regionBrightness.length;

    final stdDev = sqrt(variance);

    // Normalize the score between 0 and 1
    final shadowScore = (stdDev / avgBrightness).clamp(0.0, 1.0);

    return shadowScore;
  }

  bool hasShadows(double shadowScore) {
    return shadowScore > _shadowThreshold;
  }

  // Method to adjust quality score based on shadow presence
  double adjustScoreForShadows(double originalScore, double shadowScore) {
    if (shadowScore <= _shadowThreshold) return originalScore;

    // Calculate penalty factor based on shadow severity
    final penaltyFactor = 1.0 - (shadowScore - _shadowThreshold);

    return originalScore * penaltyFactor;
  }
}
