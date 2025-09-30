package com.example.browserai

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.util.*

class VoiceInputPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var speechRecognizer: SpeechRecognizer? = null
    private var isListening = false
    private var activityBinding: ActivityPluginBinding? = null

    companion object {
        private const val CHANNEL_NAME = "voice_input"
        private const val PERMISSION_REQUEST_CODE = 1001
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                initializeSpeechRecognizer(call.arguments as? Map<String, Any>, result)
            }
            "startListening" -> {
                startListening(call.arguments as? Map<String, Any>, result)
            }
            "stopListening" -> {
                stopListening(result)
            }
            "cancelListening" -> {
                cancelListening(result)
            }
            "checkPermissions" -> {
                checkPermissions(result)
            }
            "requestPermissions" -> {
                requestPermissions(result)
            }
            "getAvailableLanguages" -> {
                getAvailableLanguages(result)
            }
            "getInputLevel" -> {
                getInputLevel(result)
            }
            "updateConfig" -> {
                updateConfig(call.arguments as? Map<String, Any>, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun initializeSpeechRecognizer(config: Map<String, Any>?, result: Result) {
        try {
            if (!SpeechRecognizer.isRecognitionAvailable(context)) {
                result.error("SPEECH_NOT_AVAILABLE", "Speech recognition not available", null)
                return
            }

            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)
            speechRecognizer?.setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(params: Bundle?) {
                    channel.invokeMethod("onReadyForSpeech", null)
                }

                override fun onBeginningOfSpeech() {
                    channel.invokeMethod("onBeginningOfSpeech", null)
                }

                override fun onRmsChanged(rmsdB: Float) {
                    // Convert RMS to a 0-1 scale for volume indication
                    val normalizedVolume = (rmsdB + 20) / 40 // Rough normalization
                    val clampedVolume = normalizedVolume.coerceIn(0f, 1f)
                    channel.invokeMethod("onVolumeChanged", clampedVolume.toDouble())
                }

                override fun onBufferReceived(buffer: ByteArray?) {
                    // Not used in this implementation
                }

                override fun onEndOfSpeech() {
                    channel.invokeMethod("onEndOfSpeech", null)
                }

                override fun onError(error: Int) {
                    isListening = false
                    val errorMessage = when (error) {
                        SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
                        SpeechRecognizer.ERROR_CLIENT -> "Client side error"
                        SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient permissions"
                        SpeechRecognizer.ERROR_NETWORK -> "Network error"
                        SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout"
                        SpeechRecognizer.ERROR_NO_MATCH -> "No speech matches found"
                        SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "RecognitionService busy"
                        SpeechRecognizer.ERROR_SERVER -> "Server error"
                        SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No speech input"
                        else -> "Unknown error: $error"
                    }
                    channel.invokeMethod("onError", errorMessage)
                }

                override fun onResults(results: Bundle?) {
                    isListening = false
                    val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    if (!matches.isNullOrEmpty()) {
                        channel.invokeMethod("onFinalResult", matches[0])
                    }
                }

                override fun onPartialResults(partialResults: Bundle?) {
                    val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    if (!matches.isNullOrEmpty()) {
                        channel.invokeMethod("onPartialResult", matches[0])
                    }
                }

                override fun onEvent(eventType: Int, params: Bundle?) {
                    // Not used in this implementation
                }
            })

            result.success(true)
        } catch (e: Exception) {
            result.error("INITIALIZATION_ERROR", "Failed to initialize speech recognizer", e.message)
        }
    }

    private fun startListening(params: Map<String, Any>?, result: Result) {
        try {
            if (speechRecognizer == null) {
                result.error("NOT_INITIALIZED", "Speech recognizer not initialized", null)
                return
            }

            if (isListening) {
                result.error("ALREADY_LISTENING", "Already listening", null)
                return
            }

            if (!hasPermissions()) {
                result.error("NO_PERMISSION", "Microphone permission not granted", null)
                return
            }

            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, params?.get("language") as? String ?: "en-US")
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, params?.get("partialResults") as? Boolean ?: true)
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)

                // Audio enhancement settings
                val noiseReduction = params?.get("noiseReduction") as? Boolean ?: true
                val autoGain = params?.get("autoGain") as? Boolean ?: true

                if (noiseReduction) {
                    putExtra("android.speech.extra.EXTRA_ADDITIONAL_LANGUAGES", arrayOf<String>())
                }
            }

            speechRecognizer?.startListening(intent)
            isListening = true
            result.success(true)
        } catch (e: Exception) {
            result.error("START_LISTENING_ERROR", "Failed to start listening", e.message)
        }
    }

    private fun stopListening(result: Result) {
        try {
            speechRecognizer?.stopListening()
            isListening = false
            result.success(true)
        } catch (e: Exception) {
            result.error("STOP_LISTENING_ERROR", "Failed to stop listening", e.message)
        }
    }

    private fun cancelListening(result: Result) {
        try {
            speechRecognizer?.cancel()
            isListening = false
            result.success(true)
        } catch (e: Exception) {
            result.error("CANCEL_LISTENING_ERROR", "Failed to cancel listening", e.message)
        }
    }

    private fun checkPermissions(result: Result) {
        result.success(hasPermissions())
    }

    private fun requestPermissions(result: Result) {
        if (hasPermissions()) {
            result.success(true)
            return
        }

        val activity = activityBinding?.activity
        if (activity != null) {
            ActivityCompat.requestPermissions(
                activity,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                PERMISSION_REQUEST_CODE
            )
            // Result will be handled in onRequestPermissionsResult
        } else {
            result.success(false)
        }
    }

    private fun getAvailableLanguages(result: Result) {
        try {
            // Common language codes supported by Android Speech Recognition
            val languages = listOf(
                "en-US", "en-GB", "en-AU", "en-CA", "en-IN",
                "es-ES", "es-MX", "fr-FR", "fr-CA", "de-DE",
                "it-IT", "pt-BR", "pt-PT", "ru-RU", "ja-JP",
                "ko-KR", "zh-CN", "zh-TW", "ar-SA", "hi-IN",
                "th-TH", "tr-TR", "pl-PL", "nl-NL", "sv-SE",
                "da-DK", "no-NO", "fi-FI", "he-IL", "cs-CZ"
            )
            result.success(languages)
        } catch (e: Exception) {
            result.error("GET_LANGUAGES_ERROR", "Failed to get available languages", e.message)
        }
    }

    private fun getInputLevel(result: Result) {
        // This would require access to audio input level
        // For now, return a mock value
        result.success(if (isListening) 0.5 else 0.0)
    }

    private fun updateConfig(config: Map<String, Any>?, result: Result) {
        // Configuration updates would be applied to the next listening session
        result.success(true)
    }

    private fun hasPermissions(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() &&
                         grantResults[0] == PackageManager.PERMISSION_GRANTED
            channel.invokeMethod("onPermissionResult", granted)
            return true
        }
        return false
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        speechRecognizer?.destroy()
        speechRecognizer = null
    }
}