import 'package:flutter/material.dart';
import 'package:image_blur_detector/image_analysis/models/analysis_result.dart';

enum ImageQuality {
  critical,
  bad,
  acceptable,
  good;

  Color get color {
    switch (this) {
      case ImageQuality.critical:
        return Colors.red.shade700;
      case ImageQuality.bad:
        return Colors.red;
      case ImageQuality.acceptable:
        return Colors.orange;
      case ImageQuality.good:
        return Colors.green;
    }
  }

  IconData get icon {
    switch (this) {
      case ImageQuality.critical:
        return Icons.error;
      case ImageQuality.bad:
        return Icons.error_outline;
      case ImageQuality.acceptable:
        return Icons.warning_amber_rounded;
      case ImageQuality.good:
        return Icons.check_circle_outline;
    }
  }

  String get message {
    switch (this) {
      case ImageQuality.critical:
        return 'La calidad de la imagen es inaceptable. Es necesario tomar una nueva foto.';
      case ImageQuality.bad:
        return 'La imagen está muy borrosa. Se recomienda tomar una nueva foto.';
      case ImageQuality.acceptable:
        return 'La calidad de la imagen es aceptable, pero podrías intentar mejorarla.';
      case ImageQuality.good:
        return 'La calidad de la imagen es buena.';
    }
  }
}

class QualityIndicator {
  static String analyzeQuality(AnalysisResult result) {
    // Check blur first (as it's the most common and visible issue)
    if (result.score < result.threshold) {
      return 'La imagen esta borrosa, escanea de nuevo';
    }

    // Check for shadows
    if (result.hasShadows) {
      return 'La imagen esta sombreada, escanea de nuevo';
    }

    // Not a valid document (might be cropped/incomplete)
    if (!result.isDocument) {
      return 'La imagen esta recortada, escanea de nuevo';
    }

    // Good quality
    return 'La calidad de la imagen es buena';
  }
}
