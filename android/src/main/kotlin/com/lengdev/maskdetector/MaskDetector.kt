package com.lengdev.maskdetector

import android.content.Context
import android.graphics.*
import android.media.Image
import android.os.Build
import org.tensorflow.lite.Interpreter
import org.tensorflow.lite.support.image.ImageProcessor
import org.tensorflow.lite.support.image.TensorImage
import org.tensorflow.lite.support.image.ops.ResizeOp
import org.tensorflow.lite.support.image.ops.ResizeWithCropOrPadOp
import org.tensorflow.lite.support.label.TensorLabel
import org.tensorflow.lite.support.tensorbuffer.TensorBuffer
import org.tensorflow.lite.support.common.ops.NormalizeOp
import org.tensorflow.lite.support.common.FileUtil
import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.ByteBuffer
import kotlin.math.min
import android.util.Log

class MaskDetector(private val context: Context) {

    companion object {
        private const val TAG = "MaskDetector"
    }

    private var model: Interpreter? = null
    private var imageProcessor: ImageProcessor? = null
    private val labels = listOf("WithMask", "WithoutMask")

    /**
     * Initialize the model and image processor
     * Call this once when starting the detector
     */
    fun initialize() : Boolean {
        try {
            val modelFile = FileUtil.loadMappedFile(context, "mask_detector_v2.tflite")
            model = Interpreter(modelFile, Interpreter.Options())

            // Get input shape to create image processor
            val inputShape = model?.getInputTensor(0)?.shape()
            if (inputShape != null && inputShape.size >= 3) {
                imageProcessor = ImageProcessor.Builder()
                    .add(ResizeWithCropOrPadOp(inputShape[1], inputShape[2]))
                    .add(ResizeOp(inputShape[1], inputShape[2], ResizeOp.ResizeMethod.NEAREST_NEIGHBOR))
                    .add(NormalizeOp(127.5f, 127.5f))
                    .build()
            }
            
            Log.d(TAG, "Model initialized successfully")
            return true;
        } catch (e: Exception) {
            Log.e(TAG, "initialize() error: ${e.message}")
            return false;
        }
    }

    /**
     * Clean up resources
     * Call this when done with the detector
     */
    fun destroy():Boolean {
        try {
            model?.close()
            model = null
            imageProcessor = null
            Log.d(TAG, "Model destroyed successfully")
            return true;
        } catch (e: Exception) {
            Log.e(TAG, "destroy() error: ${e.message}")
            return false;
        }
    }

    /**
     * Detect mask from YUV image data (from Flutter camera)
     */
    fun detectMask(
        yuvBytes: ByteArray,
        width: Int,
        height: Int,
        rotation: Int,
        rect: FaceContour
    ): MaskDetectionResult? {
        try {
            // Check if model is initialized
            if (model == null) {
                Log.e(TAG, "Model not initialized. Call initialize() first.")
                return null
            }
            
            // Convert YUV to Bitmap
            val bitmap = yuv420ToBitmap(yuvBytes, width, height)
            
            // Rotate bitmap if needed
            val rotatedBitmap = if (rotation != 0) {
                rotateBitmap(bitmap, rotation.toFloat())
            } else {
                bitmap
            }

            // Get dimensions
            val bmpWidth = rotatedBitmap.width
            val bmpHeight = rotatedBitmap.height

            // Clamp coordinates to be within bitmap bounds
            val x = rect.left.coerceIn(0, bmpWidth - 1)
            val y = rect.top.coerceIn(0, bmpHeight - 1)
            val widthCrop = rect.width.coerceAtMost(bmpWidth - x)
            val heightCrop = rect.height.coerceAtMost(bmpHeight - y)

            val croppedFace = Bitmap.createBitmap(rotatedBitmap, x, y, widthCrop, heightCrop)


            // Predict mask
            val label = predict(croppedFace)

            val withMask = label["WithMask"] ?: 0f
            val withoutMask = label["WithoutMask"] ?: 0f

            val hasMask = withMask > withoutMask

            return MaskDetectionResult(
                hasMask = hasMask,
                withMaskScore = withMask,
                withoutMaskScore = withoutMask,
            )
            
        } catch (e: Exception) {
            Log.e(TAG, "detectMask() error: ${e.message}")
            return null
        }
    }

    /**
     * Convert YUV420 to Bitmap
     */
    private fun yuv420ToBitmap(yuvBytes: ByteArray, width: Int, height: Int): Bitmap {
        val yuvImage = YuvImage(yuvBytes, ImageFormat.NV21, width, height, null)
        val out = ByteArrayOutputStream()
        yuvImage.compressToJpeg(Rect(0, 0, width, height), 100, out)
        val imageBytes = out.toByteArray()
        return BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
    }

    /**
     * Rotate bitmap
     */
    private fun rotateBitmap(bitmap: Bitmap, degrees: Float): Bitmap {
        val matrix = Matrix()
        matrix.postRotate(degrees)
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }

    /**
     * Run prediction on the input bitmap
     */
    private fun predict(input: Bitmap): MutableMap<String, Float> {
        val currentModel = model ?: throw IllegalStateException("Model not initialized")
        val currentProcessor = imageProcessor ?: throw IllegalStateException("Image processor not initialized")

        val imageDataType = currentModel.getInputTensor(0).dataType()
        val outputDataType = currentModel.getOutputTensor(0).dataType()
        val outputShape = currentModel.getOutputTensor(0).shape()

        var inputImageBuffer = TensorImage(imageDataType)
        val outputBuffer = TensorBuffer.createFixedSize(outputShape, outputDataType)

        inputImageBuffer.load(input)
        inputImageBuffer = currentProcessor.process(inputImageBuffer)

        currentModel.run(inputImageBuffer.buffer, outputBuffer.buffer.rewind())

        val labelOutput = TensorLabel(labels, outputBuffer)
        
        return labelOutput.mapWithFloatValue
    }
}

data class FaceContour (
    val left : Int,
    val top : Int,
    val width : Int,
    val height : Int
)
