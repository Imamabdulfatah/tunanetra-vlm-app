package com.example.tunanetra_apk

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.util.Log

class VoiceControlService : AccessibilityService() {

    private var speechRecognizer: SpeechRecognizer? = null
    private lateinit var recognizerIntent: Intent
    private var isListening = false

    override fun onServiceConnected() {
        super.onServiceConnected()
        startVoiceRecognition()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Triggered when screen changes, but not used to start listening (already listening continuously)
    }

    override fun onInterrupt() {
        speechRecognizer?.destroy()
    }

    private fun startVoiceRecognition() {
        if (SpeechRecognizer.isRecognitionAvailable(this)) {
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
            speechRecognizer?.setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(params: Bundle?) {}
                override fun onBeginningOfSpeech() {}
                override fun onRmsChanged(rmsdB: Float) {}
                override fun onBufferReceived(buffer: ByteArray?) {}
                override fun onEndOfSpeech() {}
                override fun onError(error: Int) {
                    restartListening() // handle error and restart
                }

                override fun onResults(results: Bundle?) {
                    val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    val spoken = matches?.get(0)?.lowercase() ?: ""

                    Log.d("VoiceCommand", "User said: $spoken")

                    when {
                        spoken.contains("panggil") || spoken.contains("call") -> {
                            clickButton("panggilan")
                        }
                        spoken.contains("kembali") || spoken.contains("back") -> {
                            performGlobalAction(GLOBAL_ACTION_BACK)
                        }
                        spoken.contains("batal") || spoken.contains("cancel") -> {
                            performGlobalAction(GLOBAL_ACTION_HOME)
                        }
                    }

                    restartListening()
                }

                override fun onPartialResults(partialResults: Bundle?) {}
                override fun onEvent(eventType: Int, params: Bundle?) {}
            })

            recognizerIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, "id-ID")
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            }

            restartListening()
        } else {
            Log.e("VoiceControl", "Speech recognition not available")
        }
    }

    private fun restartListening() {
        Handler(Looper.getMainLooper()).postDelayed({
            isListening = true
            speechRecognizer?.startListening(recognizerIntent)
        }, 500)
    }

    private fun clickButton(keyword: String) {
        val rootNode = rootInActiveWindow ?: return
        traverseAndClick(rootNode, keyword)
    }

    private fun traverseAndClick(node: AccessibilityNodeInfo?, keyword: String) {
        if (node == null) return

        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            val text = child?.text?.toString()?.lowercase()
            val desc = child?.contentDescription?.toString()?.lowercase()

            if (text?.contains(keyword) == true || desc?.contains(keyword) == true) {
                child.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                Log.d("VoiceControl", "Clicked on: $text / $desc")
                return
            }

            traverseAndClick(child, keyword)
        }
    }
}
