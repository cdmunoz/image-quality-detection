// ignore_for_file: omit_local_variable_types, prefer_final_in_for_each

import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/analysis_result.dart';

class MLKitService {
  MLKitService()
      : _textRecognizer = TextRecognizer(),
        _imageLabeler = ImageLabeler(
            options: ImageLabelerOptions(confidenceThreshold: 0.5));

  final TextRecognizer _textRecognizer;
  final ImageLabeler _imageLabeler;

  Future<AnalysisResult> analyzeWithMLKit(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);

    // First try text recognition
    final recognizedText = await _textRecognizer.processImage(inputImage);
    final blocks = recognizedText.blocks;

    // If we found text, treat it as a document
    if (blocks.isNotEmpty) {
      double totalConfidence = 0;
      int totalElements = 0;

      for (TextBlock block in blocks) {
        for (TextLine line in block.lines) {
          for (TextElement element in line.elements) {
            totalConfidence += element.confidence!;
            totalElements++;
          }
        }
      }

      if (totalElements > 0) {
        final avgConfidence = totalConfidence / totalElements;
        final score = avgConfidence * 100;

        return AnalysisResult(
          score: score,
          hasIssues: score < 70,
          isDocument: true,
          confidence: avgConfidence,
          threshold: 70,
          method: 'MLKit-Text',
        );
      }
    }

    // If no text found, try image labeling
    final labels = await _imageLabeler.processImage(inputImage);

    if (labels.isNotEmpty) {
      final avgConfidence = labels
              .take(3)
              .map((label) => label.confidence)
              .reduce((a, b) => a + b) /
          3;

      final score = avgConfidence * 100;

      return AnalysisResult(
        score: score,
        hasIssues: score < 60,
        isDocument: false,
        confidence: avgConfidence,
        threshold: 60,
        method: 'MLKit-Image',
      );
    }

    return AnalysisResult(
      score: 0,
      hasIssues: true,
      isDocument: false,
      confidence: 0,
      threshold: 60,
      method: 'MLKit-Failed',
    );
  }

  void dispose() {
    _textRecognizer.close();
    _imageLabeler.close();
  }
}
