package com.lengdev.maskdetector

data class MaskDetectionResult(
    val hasMask: Boolean,
    val withMaskScore: Float,
    val withoutMaskScore: Float,
    val durationInMilliseconds : Float
)
