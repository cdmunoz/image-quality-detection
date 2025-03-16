// ignore_for_file: unused_local_variable

import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../models/analysis_result.dart';

class BlurAnalyzer {
  const BlurAnalyzer();

  // Laplacian method with document detection
  AnalysisResult detectBlurLaplacian(Uint8List imageBytes) {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) throw Exception('Could not decode image');

      final grayscale = img.grayscale(image);

      // Calculate image characteristics
      var whiteArea = 0;
      var textArea = 0;

      // First pass - determine image characteristics
      for (var y = 0; y < grayscale.height; y++) {
        for (var x = 0; x < grayscale.width; x++) {
          final pixel = grayscale.getPixel(x, y).r;
          if (pixel > 200) whiteArea++; // Detect white areas
          if (pixel < 50) textArea++; // Detect text/dark areas
        }
      }

      final whiteRatio = whiteArea / (grayscale.width * grayscale.height);
      final textRatio = textArea / (grayscale.width * grayscale.height);

      final isDocument = whiteRatio > 0.7;

      // Laplacian calculation
      var totalLaplacian = 0.0;
      var validPixels = 0;

      for (var y = 1; y < grayscale.height - 1; y++) {
        for (var x = 1; x < grayscale.width - 1; x++) {
          final center = grayscale.getPixel(x, y).r;
          final left = grayscale.getPixel(x - 1, y).r;
          final right = grayscale.getPixel(x + 1, y).r;
          final top = grayscale.getPixel(x, y - 1).r;
          final bottom = grayscale.getPixel(x, y + 1).r;

          final laplacian =
          (4 * center - left - right - top - bottom).abs().toDouble();
          totalLaplacian += laplacian;
          validPixels++;
        }
      }

      var score = totalLaplacian / validPixels;

      // Adjust score for documents
      if (isDocument) {
        score *= 3.0;
      }

      final threshold = isDocument ? 15.0 : 20.0;
      final confidence = (score / threshold).clamp(0.0, 1.0);

      return AnalysisResult(
        score: score,
        hasIssues: score < threshold,
        isDocument: isDocument,
        confidence: confidence,
        threshold: threshold,
        method: 'Laplacian',
      );
    } catch (e) {
      print('Error in Laplacian blur detection: $e');

      return AnalysisResult(
        score: 0,
        hasIssues: true,
        isDocument: false,
        confidence: 0,
        threshold: 20,
        method: 'Laplacian-Error',
      );
    }
  }

  // Sobel method
  AnalysisResult detectBlurSobel(Uint8List imageBytes) {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) throw Exception('Could not decode image');

      final grayscale = img.grayscale(image);
      var totalGradient = 0.0;
      var validPixels = 0;

      for (var y = 1; y < grayscale.height - 1; y++) {
        for (var x = 1; x < grayscale.width - 1; x++) {
          // Sobel operator
          final topLeft = grayscale.getPixel(x - 1, y - 1).r;
          final top = grayscale.getPixel(x, y - 1).r;
          final topRight = grayscale.getPixel(x + 1, y - 1).r;
          final left = grayscale.getPixel(x - 1, y).r;
          final right = grayscale.getPixel(x + 1, y).r;
          final bottomLeft = grayscale.getPixel(x - 1, y + 1).r;
          final bottom = grayscale.getPixel(x, y + 1).r;
          final bottomRight = grayscale.getPixel(x + 1, y + 1).r;

          // Sobel X gradient
          final gx = (topRight + 2 * right + bottomRight) -
              (topLeft + 2 * left + bottomLeft);

          // Sobel Y gradient
          final gy = (bottomLeft + 2 * bottom + bottomRight) -
              (topLeft + 2 * top + topRight);

          // Magnitude of gradient
          final gradient = sqrt(gx * gx + gy * gy);
          totalGradient += gradient;
          validPixels++;
        }
      }

      final score = totalGradient / validPixels;
      const threshold = 100.0; // Adjust this threshold for Sobel
      final confidence = (score / threshold).clamp(0.0, 1.0);

      return AnalysisResult(
        score: score,
        hasIssues: score < threshold,
        isDocument: false,
        // Sobel doesn't do document detection
        confidence: confidence,
        threshold: threshold,
        method: 'Sobel',
      );
    } catch (e) {
      print('Error in Sobel blur detection: $e');

      return AnalysisResult(
        score: 0,
        hasIssues: true,
        isDocument: false,
        confidence: 0,
        threshold: 100,
        method: 'Sobel-Error',
      );
    }
  }

  // Hybrid method
  AnalysisResult analyzeImageHybrid(Uint8List imageBytes) {
    final laplacianResult = detectBlurLaplacian(imageBytes);
    final sobelResult = detectBlurSobel(imageBytes);

    // calculate the ratios
    final image = img.decodeImage(imageBytes);
    if (image != null) {
      final grayscale = img.grayscale(image);
      var whiteArea = 0;
      var textArea = 0;

      for (var y = 0; y < grayscale.height; y++) {
        for (var x = 0; x < grayscale.width; x++) {
          final pixel = grayscale.getPixel(x, y).r;
          if (pixel > 200) whiteArea++;
          if (pixel < 50) textArea++;
        }
      }

      final whiteRatio = whiteArea / (grayscale.width * grayscale.height);
      final textRatio = textArea / (grayscale.width * grayscale.height);

      // adjust weights and thresholds
      double finalScore;
      double threshold;

      if (laplacianResult.isDocument) {
        finalScore = (laplacianResult.score + sobelResult.score * 3) / 4;
        threshold = 20.0;

        if (whiteRatio > 0.6 && textRatio > 0.1) {
          finalScore *= 1.5;
        }
      } else {
        finalScore = (laplacianResult.score + sobelResult.score * 2) / 3;
        threshold = 25.0;
      }

      final confidence = (finalScore / threshold).clamp(0.0, 1.0);

      return AnalysisResult(
        score: finalScore,
        hasIssues: finalScore < threshold,
        isDocument: laplacianResult.isDocument,
        confidence: confidence,
        threshold: threshold,
        method: 'Hybrid',
      );
    }

    // if something goes wrong, return the Laplacian result
    return laplacianResult;
  }
}
