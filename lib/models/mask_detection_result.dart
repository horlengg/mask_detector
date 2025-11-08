
class MaskDetectionResult {

  bool hasMask;
  double withMaskScore;
  double withoutMaskScore;

  MaskDetectionResult({
    required this.hasMask,
    required this.withMaskScore,
    required this.withoutMaskScore
  });

  @override
  String toString() {
    return "MaskDetectionResult(hasMask : $hasMask, withMaskScore : $withMaskScore, withoutMaskScore : $withoutMaskScore)";
  }
  
}