package com.lengdev.maskdetector

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*
import java.io.ByteArrayOutputStream
import java.io.File
import kotlin.coroutines.CoroutineContext
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch



/** MaskDetectorPlugin */
class MaskDetectorPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private var maskDetector : MaskDetector? = null
  private var TAG = "MaskDetector"
  private lateinit var context : Context

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.lengdev.maskdetector")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> handleInitialize(call, result)
            "detectMask" -> handleDetectMask(call, result)
            "destroy" -> handleDestroy(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleDetectMask(call: MethodCall, result: Result) {
        
        val yuvBytes = call.argument<ByteArray>("yuvBytes") 
            ?: throw IllegalArgumentException("Missing yuvBytes")
        val width = call.argument<Int>("imageWidth") 
            ?: throw IllegalArgumentException("Missing width")
        val height = call.argument<Int>("imageHeight") 
            ?: throw IllegalArgumentException("Missing height")
        val rotation = call.argument<Int>("rotation") 
            ?: throw IllegalArgumentException("Missing rotation")
        val faceContour = call.argument<Map<String, Int>>("faceContour") ?: throw IllegalArgumentException("Missing faceBoundingBox")

        val left = faceContour["left"] ?: 0
        val top = faceContour["top"] ?: 0
        val right = faceContour["right"] ?: 0
        val bottom = faceContour["bottom"] ?: 0

        val faceBoundingBox = FaceContour(
            left = left,
            top = top,
            width = right - left,
            height = bottom - top
        )

        // Perform heavy mask detection
        val response = maskDetector?.detectMask(
            yuvBytes, 
            width, 
            height, 
            rotation,
            faceBoundingBox
        )

        if(response == null){
            result.error("PREDICTION_ERROR", "Detect mask failed", null)
        }else {
            result.success(mapOf(
                "hasMask" to response.hasMask,
                "withMaskScore" to String.format("%.4f", response.withMaskScore).toDouble(),
                "withoutMaskScore" to String.format("%.4f", response.withoutMaskScore).toDouble(),
            ))

        }
        
    }
    fun handleInitialize(call: MethodCall, result: Result){

        if(maskDetector != null){
            maskDetector?.destroy()
            maskDetector = null
        }

        maskDetector = MaskDetector(context)
        val status = maskDetector?.initialize()

        if(status == true){
            result.success(mapOf(
                "status" to true,
                "message" to "Initialize mask detector success!."
            ))
        }else {
            result.error("INITIALIZE_FAIL","Failed to initialize mask detector!.",null)
        }


    }

    fun handleDestroy(call: MethodCall, result: Result){
        if(maskDetector != null){
            val status = maskDetector?.destroy()
            if(status == true){
                result.success(mapOf(
                    "status" to true,
                    "message" to "Mask detector was destroyed!."
                ))
            }else {
                result.error("DESTROY_FAILED","Failed to destroy mask detector!.",null)
            }
        }else {
            result.error("DESTROY_FAILED","Failed to destroy mask detector!.",null)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
