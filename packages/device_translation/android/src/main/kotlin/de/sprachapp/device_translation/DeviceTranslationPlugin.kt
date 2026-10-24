package de.sprachapp.device_translation

import com.google.android.gms.tasks.Tasks
import com.google.mlkit.common.model.DownloadConditions
import com.google.mlkit.common.model.RemoteModelManager
import com.google.mlkit.nl.translate.TranslateRemoteModel
import com.google.mlkit.nl.translate.Translation
import com.google.mlkit.nl.translate.Translator
import com.google.mlkit.nl.translate.TranslatorOptions
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class DeviceTranslationPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private val manager = RemoteModelManager.getInstance()
    private var pending: MethodChannel.Result? = null
    private var translator: Translator? = null
    private var epoch = 0

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "device_translation")
        channel.setMethodCallHandler(this)
    }
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        cancel()
        channel.setMethodCallHandler(null)
    }
    private fun cancel() {
        epoch++
        val result = pending
        pending = null
        translator?.close(); translator = null
        result?.error("cancelled", null, null)
        // ML Kit system-managed downloads have no cancellable Task API.
        // Cancellation detaches this request; a download may finish in background.
    }
    private fun fail(code: String, generation: Int) {
        if (generation != epoch) return
        val result = pending; pending = null
        translator?.close(); translator = null
        result?.error(code, null, null)
    }
    private fun finish(value: Any?, generation: Int) {
        if (generation != epoch) return
        val result = pending; pending = null
        translator?.close(); translator = null
        result?.success(value)
    }
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "cancel") { cancel(); result.success(null); return }
        val language = call.argument<String>("lang")
        if (language !in listOf("en", "pt-BR")) {
            if (call.method == "status") result.success("unsupported")
            else result.error("unsupported", null, null)
            return
        }
        val source = if (language == "pt-BR") "pt" else "en"
        val required = if (source == "en") setOf("de") else setOf("de", "pt")
        if (call.method == "status") {
            manager.getDownloadedModels(TranslateRemoteModel::class.java)
                .addOnSuccessListener { models ->
                    result.success(if (models.map { it.language }.containsAll(required)) "installed" else "supported")
                }.addOnFailureListener { result.error("local_failure", null, null) }
            return
        }
        if (call.method !in listOf("prepare", "translate")) { result.notImplemented(); return }
        if (pending != null) { result.error("busy", null, null); return }
        pending = result
        val generation = ++epoch
        if (call.method == "prepare") {
            val conditions = DownloadConditions.Builder().requireWifi().build()
            val jobs = required.map { manager.download(TranslateRemoteModel.Builder(it).build(), conditions) }
            Tasks.whenAll(jobs).addOnSuccessListener { finish(null, generation) }
                .addOnFailureListener { fail("download_failed", generation) }
            return
        }
        val text = call.argument<String>("text")
        if (text.isNullOrBlank() || text.length > 600) { fail("invalid", generation); return }
        manager.getDownloadedModels(TranslateRemoteModel::class.java)
            .addOnSuccessListener { models ->
                if (generation != epoch) return@addOnSuccessListener
                if (!models.map { it.language }.containsAll(required)) {
                    fail("missing_model", generation); return@addOnSuccessListener
                }
                val client = Translation.getClient(TranslatorOptions.Builder()
                    .setSourceLanguage(source).setTargetLanguage("de").build())
                translator = client
                client.translate(text).addOnSuccessListener { finish(it, generation) }
                    .addOnFailureListener { fail("local_failure", generation) }
            }.addOnFailureListener { fail("local_failure", generation) }
    }
}
