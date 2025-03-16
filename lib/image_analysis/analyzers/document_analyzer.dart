import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:image_blur_detector/image_analysis/analyzers/shadow_analyzer.dart';
import 'package:image_blur_detector/image_analysis/models/analysis_result.dart';
import 'package:image_blur_detector/image_analysis/services/mlkit_service.dart';

import 'blur_analyzer.dart';

class DocumentAnalyzer {
  const DocumentAnalyzer(
      this._shadowAnalyzer,
      this._mlkitService,
      this._blurAnalyzer,
      );

  final ShadowAnalyzer _shadowAnalyzer;
  final MLKitService _mlkitService;
  final BlurAnalyzer _blurAnalyzer;

  Future<AnalysisResult> analyze(File image) async {
    final bytes = await image.readAsBytes();
    final decodedImage = img.decodeImage(bytes);

    if (decodedImage == null) {
      throw Exception('Could not decode image');
    }

    // First try MLKit analysis
    final mlkitResult = await _mlkitService.analyzeWithMLKit(image.path);

    // If MLKit detects good quality and good confidence, return immediately
    if (!mlkitResult.hasIssues && mlkitResult.confidence > 0.7) {
      return mlkitResult;
    }

    // Only if MLKit result is not satisfactory, check for shadows
    final shadowScore = _shadowAnalyzer.detectShadows(decodedImage);
    final hasShadows = _shadowAnalyzer.hasShadows(shadowScore);

    // If shadows are detected, no need to continue with blur analysis
    if (hasShadows) {
      return mlkitResult.copyWith(
          shadowScore: shadowScore,
          hasShadows: hasShadows,
          score: _shadowAnalyzer.adjustScoreForShadows(
              mlkitResult.score, shadowScore));
    }

    // Only if no shadows and MLKit wasn't satisfactory, use hybrid analysis
    final hybridResult = _blurAnalyzer.analyzeImageHybrid(bytes);

    // Return the stricter result between MLKit and Hybrid
    return hybridResult.score < mlkitResult.score
        ? hybridResult.copyWith(
        shadowScore: shadowScore, hasShadows: hasShadows)
        : mlkitResult.copyWith(
        shadowScore: shadowScore, hasShadows: hasShadows);
  }

  void dispose() {
    _mlkitService.dispose();
  }
}
