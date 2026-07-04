package io.apparence.quick_settings

import android.app.Activity
import android.app.StatusBarManager
import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.service.quicksettings.TileService
import android.util.Log
import androidx.core.graphics.drawable.IconCompat
import io.apparence.quick_settings.pigeon.AddTileResult
import io.apparence.quick_settings.pigeon.QuickSettingsInterface
import io.apparence.quick_settings.pigeon.Tile
import io.flutter.embedding.engine.FlutterShellArgs

class QuickSettingsImpl : QuickSettingsInterface {
    var activity: Activity? = null
    var applicationContext: Context? = null

    override fun addTileToQuickSettings(
        title: String,
        drawableName: String,
        callback: (Result<AddTileResult>) -> Unit
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val currentActivity = activity
            if (currentActivity == null) {
                callback(
                    Result.failure(
                        IllegalStateException("Activity not attached, cannot request tile addition.")
                    )
                )
                return
            }
            val componentName = ComponentName(
                currentActivity, QuickSettingsService::class.java
            )
            // Enable the service if it has not been enabled yet
            val enableFlag: Int = PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            currentActivity.packageManager.setComponentEnabledSetting(
                componentName, enableFlag, PackageManager.DONT_KILL_APP
            )

            val drawableResourceId =
                QuickSettingsPlugin.drawableResourceIdFromName(currentActivity, drawableName)
            if (drawableResourceId == 0) {
                return callback(
                    Result.success(
                        AddTileResult(
                            false,
                            "Icon $drawableName not found"
                        )
                    )
                );
            }

            val icon = IconCompat.createWithResource(
                activity!!, drawableResourceId
            )

            val statusBarService = activity!!.getSystemService(
                StatusBarManager::class.java
            )
            statusBarService.requestAddTileService(componentName,
                title,
                icon.toIcon(activity),
                {}) { result ->
                Log.d("QS", "requestAddTileService result: $result")
            }
            // TODO Android API is broken, the callback is never called so we can't know for sure if it worked or not
            return callback(Result.success(AddTileResult(true)));
        }
    }

    /**
     * Enable the Quick Settings service and its associated Tile.
     */
    override fun enableTile() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val ctx = requireContext()
            val componentName = ComponentName(
                ctx, QuickSettingsService::class.java
            )
            val enableFlag: Int = PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            ctx.packageManager.setComponentEnabledSetting(
                componentName, enableFlag, PackageManager.DONT_KILL_APP
            )
        }
    }

    /**
     * Disable the Quick Settings service and its associated Tile.
     */
    override fun disableTile() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val ctx = requireContext()
            val componentName = ComponentName(
                ctx, QuickSettingsService::class.java
            )
            val disableFlag: Int = PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            ctx.packageManager.setComponentEnabledSetting(
                componentName, disableFlag, PackageManager.DONT_KILL_APP
            )
        }
    }

    override fun updateTile(tile: Tile) {
        val ctx = requireContext()
        QuickSettingsTileStateStore.save(ctx, tile)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val componentName = ComponentName(ctx, QuickSettingsService::class.java)
            TileService.requestListeningState(ctx, componentName)
        }
    }

    /**
     * This method starts the background isolate which will be able to handle callbacks from
     * the TileService associated with your QuickSettings Tile.
     */
    override fun startBackgroundIsolate(
        pluginCallbackHandle: Long,
        onStatusChangedHandle: Long?,
        onTileAddedHandle: Long?,
        onTileRemovedHandle: Long?
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val ctx = requireContext()
            var shellArgs: FlutterShellArgs? = null
            if (activity != null) {
                // Supports both Flutter Activity types:
                //    io.flutter.embedding.android.FlutterFragmentActivity
                //    io.flutter.embedding.android.FlutterActivity
                // We could use `getFlutterShellArgs()` but this is only available on `FlutterActivity`.
                shellArgs = FlutterShellArgs.fromIntent(activity!!.intent)
            }
            QuickSettingsService.setCallbackDispatcher(
                ctx,
                pluginCallbackHandle
            )

            onStatusChangedHandle?.apply {
                QuickSettingsExecutor.setOnStatusChangedHandle(
                    ctx,
                    this
                )
            }
            onTileAddedHandle?.apply {
                QuickSettingsExecutor.setOnTileAddedHandle(
                    ctx,
                    this
                )
            }
            onTileRemovedHandle?.apply {
                QuickSettingsExecutor.setOnTileRemovedHandle(
                    ctx,
                    this
                )
            }
            QuickSettingsService.startBackgroundIsolate(
                ctx,
                pluginCallbackHandle, shellArgs
            )
        }
    }

    private fun requireContext(): Context {
        return activity?.applicationContext ?: applicationContext
        ?: throw IllegalStateException("QuickSettingsPlugin is not attached to a context.")
    }
}