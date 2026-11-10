package com.kount.sdk.flutter

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.kount.api.KountSDK
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

/** KountPlugin - Flutter plugin that bridges the Kount Data Collector SDK */
class KountPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null

    private var pendingCollectResult: Result? = null
    private var pendingPermissionResult: Result? = null

    companion object {
        private const val TAG = "KountPlugin"
        private const val CHANNEL_NAME = "DataCollector"
        private const val METHOD_COLLECT_FOR_SESSION = "collectForSession"
        private const val METHOD_GET_SESSION_ID = "getSessionID"
        private const val METHOD_SET_MERCHANT_ID = "setMerchantId"
        private const val METHOD_SET_ENVIRONMENT = "setEnvironment"

        // Not exposed as a public constant by KountSDK; the data collector maps
        // 999999 to the internal QA endpoint (mbl.kaptcha.com).
        private const val ENVIRONMENT_QA = 999999
        private const val METHOD_SET_COLLECT_ANALYTICS = "setCollectAnalytics"
        private const val METHOD_SET_SESSION_ID = "setSessionId"
        private const val METHOD_CONFIGURE_AND_COLLECT = "configureAndCollect"
        private const val METHOD_REQUEST_LOCATION_PERMISSION = "requestLocationPermission"
        private const val RC_LOCATION = 0x4B4D
    }

    // ── FlutterPlugin ────────────────────────────────────────────────────────

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // ── ActivityAware ────────────────────────────────────────────────────────

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        activity = null
    }

    // ── MethodCallHandler ────────────────────────────────────────────────────

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            METHOD_SET_MERCHANT_ID -> {
                KountSDK.setMerchantId(call.argument<String>("merchantId") ?: "")
                result.success(null)
            }
            METHOD_SET_ENVIRONMENT -> {
                KountSDK.setEnvironment(resolveEnvironment(call.argument("environment")))
                result.success(null)
            }
            METHOD_SET_COLLECT_ANALYTICS -> {
                // Note: Analytics collection is not supported in Flutter wrappers
                // KountAnalyticsTracker depends on native view/touch hierarchy observation,
                // which Flutter's canvas-based rendering (Skia/Impeller) does not expose.
                // This is a no-op to maintain API compatibility with shared Dart code.
                // Re-enable when native analytics collection path is available (tentatively Q4 2026/Q1 2027)
                val _enabled = call.argument<Boolean>("enabled") // Intentionally unused
                result.success(null)
            }
            METHOD_SET_SESSION_ID -> {
                val sessionId = call.argument<String>("sessionId")?.replace("-", "") ?: ""
                KountSDK.setSessionId(sessionId)
                result.success(null)
            }
            METHOD_COLLECT_FOR_SESSION -> {
                call.argument<String>("merchantId")?.let { KountSDK.setMerchantId(it) }
                call.argument<String>("sessionId")?.let { KountSDK.setSessionId(it) }
                call.argument<String>("environment")?.let {
                    KountSDK.setEnvironment(resolveEnvironment(it))
                }
                KountSDK.setDebuggable(true)
                collectData(result)
            }
            METHOD_CONFIGURE_AND_COLLECT -> {
                KountSDK.setMerchantId(call.argument<String>("merchantId") ?: "")
                KountSDK.setEnvironment(resolveEnvironment(call.argument("environment") ?: "TEST"))
                val sessionID = call.argument<String>("sessionId")?.replace("-", "") ?: ""
                KountSDK.setSessionId(sessionID)
                // Note: collectAnalytics parameter is accepted but ignored (no-op)
                // See METHOD_SET_COLLECT_ANALYTICS comment above for details
                val _collectAnalytics = call.argument<Boolean>("collectAnalytics") // Intentionally unused
                KountSDK.setDebuggable(true)
                collectData(result)
            }
            METHOD_GET_SESSION_ID -> {
                val sid = KountSDK.getSessionId()
                if (sid != null) {
                    Log.d(TAG, "Session ID: $sid")
                    result.success(sid)
                } else {
                    result.error("SESSION_ID_ERROR", "Session ID is null", null)
                }
            }
            METHOD_REQUEST_LOCATION_PERMISSION -> {
                val ctx = activity
                if (ctx == null) {
                    result.error("NO_ACTIVITY", "Activity not available", null)
                    return
                }
                if (hasLocationPermission(ctx)) {
                    Log.d(TAG, "Location permission already granted")
                    result.success(true)
                } else if (ActivityCompat.shouldShowRequestPermissionRationale(
                        ctx, Manifest.permission.ACCESS_FINE_LOCATION)) {
                    // El usuario ya denegó antes → abrir Settings para que lo active manualmente
                    Log.d(TAG, "Permission denied before — opening app settings")
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.fromParts("package", ctx.packageName, null)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    ctx.startActivity(intent)
                    result.success(false)
                } else {
                    // Primera solicitud o "Don't ask again" no marcado → diálogo del sistema
                    Log.d(TAG, "Requesting location permission via system dialog")
                    pendingPermissionResult = result
                    ActivityCompat.requestPermissions(
                        ctx,
                        arrayOf(
                            Manifest.permission.ACCESS_FINE_LOCATION,
                            Manifest.permission.ACCESS_COARSE_LOCATION
                        ),
                        RC_LOCATION
                    )
                }
            }
            else -> result.notImplemented()
        }
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private fun hasLocationPermission(ctx: Activity): Boolean =
        ContextCompat.checkSelfPermission(ctx, Manifest.permission.ACCESS_FINE_LOCATION) ==
                PackageManager.PERMISSION_GRANTED ||
        ContextCompat.checkSelfPermission(ctx, Manifest.permission.ACCESS_COARSE_LOCATION) ==
                PackageManager.PERMISSION_GRANTED

    private fun resolveEnvironment(env: String?): Int = when (env) {
        "PROD" -> KountSDK.ENVIRONMENT_PRODUCTION
        "QA"   -> ENVIRONMENT_QA
        else   -> KountSDK.ENVIRONMENT_TEST
    }

    private fun collectData(result: Result) {
        val ctx = activity
        if (ctx == null) {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        if (!hasLocationPermission(ctx)) {
            Log.d(TAG, "No location permission — requesting before collect")
            pendingCollectResult = result
            ActivityCompat.requestPermissions(
                ctx,
                arrayOf(
                    Manifest.permission.ACCESS_FINE_LOCATION,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                ),
                RC_LOCATION
            )
            return
        }

        KountSDK.collectForSession(
            ctx,
            { sessionId ->
                Log.d(TAG, "Collection succeeded – sessionId: $sessionId, status: ${KountSDK.getCollectionStatus()}")
                result.success(KountSDK.getCollectionStatus())
            },
            { sessionId, error ->
                Log.e(TAG, "Collection failed – sessionId: $sessionId, error: $error, status: ${KountSDK.getCollectionStatus()}")
                result.error("COLLECTION_ERROR", "Data collection failed: $error", null)
            }
        )
    }

    // ── PermissionsResultListener ─────────────────────────────────────────────

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode != RC_LOCATION) return false

        val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
        Log.d(TAG, "onRequestPermissionsResult: granted=$granted")

        // Flujo 1: requestLocationPermission standalone → retornar bool a Dart
        pendingPermissionResult?.let { res ->
            pendingPermissionResult = null
            res.success(granted)
        }

        // Flujo 2: collectData esperando permiso → reanudar o cancelar
        pendingCollectResult?.let { res ->
            pendingCollectResult = null
            if (granted) {
                collectData(res)
            } else {
                res.error("PERMISSION_DENIED", "Location permission denied by user", null)
            }
        }

        return true
    }
}
