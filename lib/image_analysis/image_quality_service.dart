import 'dart:io';

import 'package:image_blur_detector/image_analysis/analyzers/document_analyzer.dart';
import 'package:image_blur_detector/image_analysis/models/analysis_result.dart';
import 'package:image_blur_detector/image_analysis/ui/image_quality.dart';

class ImageQualityService {
  ImageQualityService({
    required DocumentAnalyzer documentAnalyzer,
  }) : _documentAnalyzer = documentAnalyzer;

  final DocumentAnalyzer _documentAnalyzer;

  // Main method that returns only the quality message
  Future<String> analyzeImageQuality(File image) async {
    try {
      final result = await _documentAnalyzer.analyze(image);
      return QualityIndicator.analyzeQuality(result);
    } catch (e) {
      return 'Error al analizar la imagen, intenta de nuevo';
    }
  }

  // Optional method if complete result is needed
  Future<AnalysisResult> analyzeImageComplete(File image) async {
    return _documentAnalyzer.analyze(image);
  }

  void dispose() {
    _documentAnalyzer.dispose();
  }
}
