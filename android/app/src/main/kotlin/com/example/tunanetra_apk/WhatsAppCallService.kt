package com.example.tunanetra_apk

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.os.Handler
import android.os.Looper
import android.util.Log

class WhatsAppCallService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val root = rootInActiveWindow ?: return

        Handler(Looper.getMainLooper()).postDelayed({
            findAndClickCallButton(root)
        }, 2000) // Delay 2 detik agar UI stabil
    }

    private fun findAndClickCallButton(node: AccessibilityNodeInfo?) {
        if (node == null) return

        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            val desc = child?.contentDescription?.toString()?.lowercase()

            if (desc != null && (
                desc.contains("voice call") ||
                desc.contains("panggilan suara")
            )) {
                Log.d("WA_CALL", "Tombol ditemukan: $desc")
                child.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                return
            }

            findAndClickCallButton(child)
        }
    }

    override fun onInterrupt() {}
}
