class AnalysisResult {
  AnalysisResult({
    required this.score,
    required this.hasIssues,
    required this.isDocument,
    required this.confidence,
    required this.threshold,
    required this.method,
    this.shadowScore,
    this.hasShadows = false,
  });

  final double score;
  final bool hasIssues;
  final bool isDocument;
  final double confidence;
  final double threshold;
  final String method;
  final double? shadowScore;
  final bool hasShadows;

  @override
  String toString() {
    return 'BlurAnalysisResult(score: $score, isBlurry: $hasIssues, '
        'isDocument: $isDocument, '
        'confidence: ${confidence.toStringAsFixed(2)}, '
        'threshold: $threshold, method: $method), '
        'shadowScore: ${shadowScore?.toStringAsFixed(2)}, '
        'hasShadows: $hasShadows)';
  }

  // Helper method to create a copy with modified values
  AnalysisResult copyWith({
    double? score,
    bool? isBlurry,
    bool? isDocument,
    double? confidence,
    double? threshold,
    String? method,
    double? shadowScore,
    bool? hasShadows,
  }) {
    return AnalysisResult(
      score: score ?? this.score,
      hasIssues: isBlurry ?? hasIssues,
      isDocument: isDocument ?? this.isDocument,
      confidence: confidence ?? this.confidence,
      threshold: threshold ?? this.threshold,
      method: method ?? this.method,
      shadowScore: shadowScore ?? this.shadowScore,
      hasShadows: hasShadows ?? this.hasShadows,
    );
  }
}