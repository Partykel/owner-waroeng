package com.ghepek_in

import android.media.AudioAttributes
import android.media.AudioManager
import android.media.SoundPool
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var sounds: SoundPool? = null
    private var clickId = 0
    private var successId = 0
    private var resumed = false
    private val loaded = mutableSetOf<Int>()
    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        val pool = SoundPool.Builder().setMaxStreams(2).setAudioAttributes(
            AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build()).build()
        sounds = pool
        pool.setOnLoadCompleteListener { _, id, status -> if (status == 0) loaded.add(id) }
        clickId = pool.load(this, R.raw.feedback_click, 1)
        successId = pool.load(this, R.raw.feedback_success, 1)
        MethodChannel(engine.dartExecutor.binaryMessenger, "com.ghepek_in/feedback").setMethodCallHandler { call, result ->
            if (call.method != "play") { result.notImplemented(); return@setMethodCallHandler }
            val audio = getSystemService(AUDIO_SERVICE) as AudioManager
            if (resumed && audio.ringerMode == AudioManager.RINGER_MODE_NORMAL && audio.getStreamVolume(AudioManager.STREAM_SYSTEM) > 0) {
                val id = if (call.arguments == "success") successId else clickId
                if (loaded.contains(id)) sounds?.play(id, .5f, .5f, 1, 0, 1f)
            }
            result.success(null)
        }
    }
    override fun onResume() { super.onResume(); resumed = true }
    override fun onPause() { resumed = false; sounds?.autoPause(); super.onPause() }
    override fun onDestroy() { sounds?.release(); sounds = null; loaded.clear(); super.onDestroy() }
}
