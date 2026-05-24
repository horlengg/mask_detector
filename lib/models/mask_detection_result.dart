
class MaskDetectionResult {

  bool hasMask;
  double withMaskScore;
  double withoutMaskScore;
  double durationInMilliseconds;

  MaskDetectionResult({
    required this.hasMask,
    required this.withMaskScore,
    required this.withoutMaskScore,
    required this.durationInMilliseconds
  });

  @override
  String toString() {
    return "MaskDetectionResult(hasMask=$hasMask, withMaskScore=$withMaskScore=withoutMaskScore=$withoutMaskScore,durationInMilliseconds=$durationInMilliseconds)";
  }

  String get confidenceScore => (hasMask ? withMaskScore : withoutMaskScore).toStringAsFixed(2);
  
}