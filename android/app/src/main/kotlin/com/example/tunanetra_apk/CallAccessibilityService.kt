package com.example.tunanetra_apk

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.os.Handler
import android.os.Looper
import android.util.Log

class CallAccessibilityService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED ||
            event?.eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) {

            val root = rootInActiveWindow ?: return

            Handler(Looper.getMainLooper()).postDelayed({
                findAndClickCallButton(root)
            }, 1500) // Delay agar UI sempat muncul
        }
    }

    private fun findAndClickCallButton(node: AccessibilityNodeInfo?) {
        if (node == null) return

        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            val desc = child?.contentDescription?.toString()?.lowercase()
            val text = child?.text?.toString()?.lowercase()

            if (desc != null && (desc.contains("panggilan") || desc.contains("call"))) {
                Log.d("ACC_CALL", "Klik tombol via contentDescription: $desc")
                child.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                return
            }

            if (text != null && (text.contains("panggilan") || text.contains("call") || text.contains("sim 1"))) {
                Log.d("ACC_CALL", "Klik tombol via text: $text")
                child.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                return
            }

            findAndClickCallButton(child)
        }
    }

    override fun onInterrupt() {}
}
