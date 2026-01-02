package com.example.browserai

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.accessibilityservice.GestureDescription
import android.content.Intent
import android.graphics.Path
import android.graphics.Rect
import android.os.Build
import android.os.Bundle
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import org.json.JSONArray
import org.json.JSONObject

class UkkinAccessibilityService : AccessibilityService() {

    companion object {
        var instance: UkkinAccessibilityService? = null
        var isRunning = false

        // Screen content cache
        private var lastScreenContent: JSONObject? = null
        private var currentPackage: String = ""
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        isRunning = true

        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPES_ALL_MASK
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                    AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS or
                    AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            notificationTimeout = 100
        }
        serviceInfo = info
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event?.let {
            if (it.packageName != null) {
                currentPackage = it.packageName.toString()
            }
        }
    }

    override fun onInterrupt() {
        // Service interrupted
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        isRunning = false
    }

    // Get full screen content as structured JSON
    fun getScreenContent(): JSONObject {
        val result = JSONObject()
        val elements = JSONArray()

        val rootNode = rootInActiveWindow ?: return result.apply {
            put("package", currentPackage)
            put("elements", elements)
            put("error", "No active window")
        }

        traverseNode(rootNode, elements, 0)
        rootNode.recycle()

        result.put("package", currentPackage)
        result.put("elements", elements)
        result.put("timestamp", System.currentTimeMillis())

        lastScreenContent = result
        return result
    }

    private fun traverseNode(node: AccessibilityNodeInfo, elements: JSONArray, depth: Int) {
        if (depth > 30) return // Prevent infinite recursion

        val element = JSONObject()

        // Basic properties
        element.put("class", node.className?.toString() ?: "")
        element.put("text", node.text?.toString() ?: "")
        element.put("contentDescription", node.contentDescription?.toString() ?: "")
        element.put("viewId", node.viewIdResourceName ?: "")

        // Bounds
        val bounds = Rect()
        node.getBoundsInScreen(bounds)
        element.put("bounds", JSONObject().apply {
            put("left", bounds.left)
            put("top", bounds.top)
            put("right", bounds.right)
            put("bottom", bounds.bottom)
            put("centerX", bounds.centerX())
            put("centerY", bounds.centerY())
        })

        // State
        element.put("clickable", node.isClickable)
        element.put("enabled", node.isEnabled)
        element.put("focusable", node.isFocusable)
        element.put("scrollable", node.isScrollable)
        element.put("editable", node.isEditable)
        element.put("checkable", node.isCheckable)
        element.put("checked", node.isChecked)

        // Only add meaningful elements
        val hasContent = element.getString("text").isNotEmpty() ||
                        element.getString("contentDescription").isNotEmpty() ||
                        node.isClickable || node.isEditable

        if (hasContent) {
            elements.put(element)
        }

        // Traverse children
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            traverseNode(child, elements, depth + 1)
            child.recycle()
        }
    }

    // Find element by text (exact or contains)
    fun findElementByText(text: String, exact: Boolean = false): AccessibilityNodeInfo? {
        val rootNode = rootInActiveWindow ?: return null
        return findNodeByText(rootNode, text, exact)
    }

    private fun findNodeByText(node: AccessibilityNodeInfo, text: String, exact: Boolean): AccessibilityNodeInfo? {
        val nodeText = node.text?.toString() ?: ""
        val contentDesc = node.contentDescription?.toString() ?: ""

        val matches = if (exact) {
            nodeText == text || contentDesc == text
        } else {
            nodeText.contains(text, ignoreCase = true) ||
            contentDesc.contains(text, ignoreCase = true)
        }

        if (matches) {
            return AccessibilityNodeInfo.obtain(node)
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val result = findNodeByText(child, text, exact)
            child.recycle()
            if (result != null) return result
        }

        return null
    }

    // Find element by resource ID
    fun findElementById(resourceId: String): AccessibilityNodeInfo? {
        val rootNode = rootInActiveWindow ?: return null
        val nodes = rootNode.findAccessibilityNodeInfosByViewId(resourceId)
        return if (nodes.isNotEmpty()) nodes[0] else null
    }

    // Click on element
    fun clickElement(node: AccessibilityNodeInfo): Boolean {
        return node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
    }

    // Click at coordinates
    fun clickAt(x: Float, y: Float): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return false

        val path = Path().apply {
            moveTo(x, y)
        }

        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, 100))
            .build()

        return dispatchGesture(gesture, null, null)
    }

    // Type text into focused field
    fun typeText(text: String): Boolean {
        val rootNode = rootInActiveWindow ?: return false
        val focusedNode = rootNode.findFocus(AccessibilityNodeInfo.FOCUS_INPUT)

        if (focusedNode != null && focusedNode.isEditable) {
            val arguments = Bundle().apply {
                putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text)
            }
            val result = focusedNode.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, arguments)
            focusedNode.recycle()
            return result
        }

        rootNode.recycle()
        return false
    }

    // Set text on specific element
    fun setTextOnElement(node: AccessibilityNodeInfo, text: String): Boolean {
        if (!node.isEditable) return false

        val arguments = Bundle().apply {
            putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text)
        }
        return node.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, arguments)
    }

    // Scroll in direction
    fun scroll(direction: String): Boolean {
        val rootNode = rootInActiveWindow ?: return false
        val scrollable = findScrollableNode(rootNode)

        if (scrollable != null) {
            val action = when (direction.lowercase()) {
                "up", "backward" -> AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD
                "down", "forward" -> AccessibilityNodeInfo.ACTION_SCROLL_FORWARD
                else -> return false
            }
            val result = scrollable.performAction(action)
            scrollable.recycle()
            return result
        }

        rootNode.recycle()
        return false
    }

    private fun findScrollableNode(node: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        if (node.isScrollable) {
            return AccessibilityNodeInfo.obtain(node)
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val result = findScrollableNode(child)
            child.recycle()
            if (result != null) return result
        }

        return null
    }

    // Swipe gesture
    fun swipe(startX: Float, startY: Float, endX: Float, endY: Float, duration: Long = 300): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return false

        val path = Path().apply {
            moveTo(startX, startY)
            lineTo(endX, endY)
        }

        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, duration))
            .build()

        return dispatchGesture(gesture, null, null)
    }

    // Long press at coordinates
    fun longPressAt(x: Float, y: Float): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return false

        val path = Path().apply {
            moveTo(x, y)
        }

        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, 1000))
            .build()

        return dispatchGesture(gesture, null, null)
    }

    // Press back button
    fun pressBack(): Boolean {
        return performGlobalAction(GLOBAL_ACTION_BACK)
    }

    // Press home button
    fun pressHome(): Boolean {
        return performGlobalAction(GLOBAL_ACTION_HOME)
    }

    // Open recents
    fun openRecents(): Boolean {
        return performGlobalAction(GLOBAL_ACTION_RECENTS)
    }

    // Open notifications
    fun openNotifications(): Boolean {
        return performGlobalAction(GLOBAL_ACTION_NOTIFICATIONS)
    }

    // Get current package name
    fun getCurrentPackage(): String {
        return currentPackage
    }

    // Wait for specific element to appear
    fun waitForElement(text: String, timeoutMs: Long = 5000): AccessibilityNodeInfo? {
        val startTime = System.currentTimeMillis()
        while (System.currentTimeMillis() - startTime < timeoutMs) {
            val element = findElementByText(text)
            if (element != null) return element
            Thread.sleep(200)
        }
        return null
    }

    // Extract all text from screen
    fun extractAllText(): List<String> {
        val texts = mutableListOf<String>()
        val rootNode = rootInActiveWindow ?: return texts
        extractTexts(rootNode, texts)
        rootNode.recycle()
        return texts
    }

    private fun extractTexts(node: AccessibilityNodeInfo, texts: MutableList<String>) {
        node.text?.toString()?.let { if (it.isNotBlank()) texts.add(it) }
        node.contentDescription?.toString()?.let { if (it.isNotBlank()) texts.add(it) }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            extractTexts(child, texts)
            child.recycle()
        }
    }
}
