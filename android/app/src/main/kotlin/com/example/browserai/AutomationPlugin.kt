package com.example.browserai

import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class AutomationPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private val scope = CoroutineScope(Dispatchers.Main)

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.ukkin/automation")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        scope.launch {
            try {
                when (call.method) {
                    "isAccessibilityEnabled" -> {
                        result.success(UkkinAccessibilityService.isRunning)
                    }

                    "openAccessibilitySettings" -> {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        context.startActivity(intent)
                        result.success(true)
                    }

                    "getScreenContent" -> {
                        val service = UkkinAccessibilityService.instance
                        if (service == null) {
                            result.error("SERVICE_NOT_RUNNING", "Accessibility service not enabled", null)
                        } else {
                            withContext(Dispatchers.IO) {
                                val content = service.getScreenContent()
                                result.success(content.toString())
                            }
                        }
                    }

                    "findElementByText" -> {
                        val text = call.argument<String>("text") ?: ""
                        val exact = call.argument<Boolean>("exact") ?: false
                        val service = UkkinAccessibilityService.instance

                        if (service == null) {
                            result.error("SERVICE_NOT_RUNNING", "Accessibility service not enabled", null)
                        } else {
                            withContext(Dispatchers.IO) {
                                val element = service.findElementByText(text, exact)
                                if (element != null) {
                                    val bounds = android.graphics.Rect()
                                    element.getBoundsInScreen(bounds)
                                    result.success(mapOf(
                                        "found" to true,
                                        "text" to (element.text?.toString() ?: ""),
                                        "bounds" to mapOf(
                                            "left" to bounds.left,
                                            "top" to bounds.top,
                                            "right" to bounds.right,
                                            "bottom" to bounds.bottom,
                                            "centerX" to bounds.centerX(),
                                            "centerY" to bounds.centerY()
                                        )
                                    ))
                                    element.recycle()
                                } else {
                                    result.success(mapOf("found" to false))
                                }
                            }
                        }
                    }

                    "clickOnText" -> {
                        val text = call.argument<String>("text") ?: ""
                        val service = UkkinAccessibilityService.instance

                        if (service == null) {
                            result.error("SERVICE_NOT_RUNNING", "Accessibility service not enabled", null)
                        } else {
                            withContext(Dispatchers.IO) {
                                val element = service.findElementByText(text)
                                if (element != null) {
                                    val success = service.clickElement(element)
                                    element.recycle()
                                    result.success(success)
                                } else {
                                    result.success(false)
                                }
                            }
                        }
                    }

                    "clickAt" -> {
                        val x = call.argument<Double>("x")?.toFloat() ?: 0f
                        val y = call.argument<Double>("y")?.toFloat() ?: 0f
                        val service = UkkinAccessibilityService.instance

                        if (service == null) {
                            result.error("SERVICE_NOT_RUNNING", "Accessibility service not enabled", null)
                        } else {
                            result.success(service.clickAt(x, y))
                        }
                    }

                    "typeText" -> {
                        val text = call.argument<String>("text") ?: ""
                        val service = UkkinAccessibilityService.instance

                        if (service == null) {
                            result.error("SERVICE_NOT_RUNNING", "Accessibility service not enabled", null)
                        } else {
                            result.success(service.typeText(text))
                        }
                    }

                    "scroll" -> {
                        val direction = call.argument<String>("direction") ?: "down"
                        val service = UkkinAccessibilityService.instance

                        if (service == null) {
                            result.error("SERVICE_NOT_RUNNING", "Accessibility service not enabled", null)
                        } else {
                            result.success(service.scroll(direction))
                        }
                    }

                    "swipe" -> {
                        val startX = call.argument<Double>("startX")?.toFloat() ?: 0f
                        val startY = call.argument<Double>("startY")?.toFloat() ?: 0f
                        val endX = call.argument<Double>("endX")?.toFloat() ?: 0f
                        val endY = call.argument<Double>("endY")?.toFloat() ?: 0f
                        val duration = call.argument<Int>("duration")?.toLong() ?: 300L
                        val service = UkkinAccessibilityService.instance

                        if (service == null) {
                            result.error("SERVICE_NOT_RUNNING", "Accessibility service not enabled", null)
                        } else {
                            result.success(service.swipe(startX, startY, endX, endY, duration))
                        }
                    }

                    "pressBack" -> {
                        val service = UkkinAccessibilityService.instance
                        if (service == null) {
                            result.error("SERVICE_NOT_RUNNING", "Accessibility service not enabled", null)
                        } else {
                            result.success(service.pressBack())
                        }
                    }

                    "pressHome" -> {
                        val service = UkkinAccessibilityService.instance
                        if (service == null) {
                            result.error("SERVICE_NOT_RUNNING", "Accessibility service not enabled", null)
                        } else {
                            result.success(service.pressHome())
                        }
                    }

                    "getCurrentPackage" -> {
                        val service = UkkinAccessibilityService.instance
                        if (service == null) {
                            result.error("SERVICE_NOT_RUNNING", "Accessibility service not enabled", null)
                        } else {
                            result.success(service.getCurrentPackage())
                        }
                    }

                    "extractAllText" -> {
                        val service = UkkinAccessibilityService.instance
                        if (service == null) {
                            result.error("SERVICE_NOT_RUNNING", "Accessibility service not enabled", null)
                        } else {
                            withContext(Dispatchers.IO) {
                                result.success(service.extractAllText())
                            }
                        }
                    }

                    "waitForElement" -> {
                        val text = call.argument<String>("text") ?: ""
                        val timeout = call.argument<Int>("timeout")?.toLong() ?: 5000L
                        val service = UkkinAccessibilityService.instance

                        if (service == null) {
                            result.error("SERVICE_NOT_RUNNING", "Accessibility service not enabled", null)
                        } else {
                            withContext(Dispatchers.IO) {
                                val element = service.waitForElement(text, timeout)
                                result.success(element != null)
                                element?.recycle()
                            }
                        }
                    }

                    "launchApp" -> {
                        val packageName = call.argument<String>("packageName") ?: ""
                        val launchIntent = context.packageManager.getLaunchIntentForPackage(packageName)
                        if (launchIntent != null) {
                            launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            context.startActivity(launchIntent)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }

                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("ERROR", e.message, e.stackTraceToString())
            }
        }
    }
}
