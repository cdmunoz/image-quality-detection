import 'package:image_blur_detector/image_analysis/analyzers/blur_analyzer.dart';
import 'package:image_blur_detector/image_analysis/analyzers/document_analyzer.dart';
import 'package:image_blur_detector/image_analysis/analyzers/shadow_analyzer.dart';
import 'package:image_blur_detector/image_analysis/services/mlkit_service.dart';
import 'package:image_blur_detector/image_analysis/ui/image_quality.dart';

abstract class AppModule {
  static MLKitService mlkitService() {
    return MLKitService();
  }

  static ShadowAnalyzer shadowAnalyzer() {
    return const ShadowAnalyzer();
  }

  static BlurAnalyzer blurAnalyzer() {
    return const BlurAnalyzer();
  }

  static DocumentAnalyzer documentAnalyzer() {
    return DocumentAnalyzer(shadowAnalyzer(), mlkitService(), blurAnalyzer());
  }

  static QualityIndicator qualityIndicator() {
    return QualityIndicator();
  }
}
