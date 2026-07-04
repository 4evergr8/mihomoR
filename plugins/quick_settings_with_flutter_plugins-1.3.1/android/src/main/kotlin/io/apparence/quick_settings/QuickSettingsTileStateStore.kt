package io.apparence.quick_settings

import android.content.Context
import io.apparence.quick_settings.pigeon.Tile
import io.apparence.quick_settings.pigeon.TileStatus

object QuickSettingsTileStateStore {
    private const val PREFS_NAME = "quick_settings_tile_state"
    private const val KEY_LABEL = "label"
    private const val KEY_STATUS = "status"
    private const val KEY_CONTENT_DESCRIPTION = "content_description"
    private const val KEY_STATE_DESCRIPTION = "state_description"
    private const val KEY_DRAWABLE = "drawable_name"
    private const val KEY_SUBTITLE = "subtitle"
    private const val KEY_ADDED_REPORTED = "added_reported"

    fun save(context: Context, tile: Tile) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putString(KEY_LABEL, tile.label)
            .putString(KEY_STATUS, tile.tileStatus.name)
            .putString(KEY_CONTENT_DESCRIPTION, tile.contentDescription)
            .putString(KEY_STATE_DESCRIPTION, tile.stateDescription)
            .putString(KEY_DRAWABLE, tile.drawableName)
            .putString(KEY_SUBTITLE, tile.subtitle)
            .apply()
    }

    fun load(context: Context): Tile? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        if (!prefs.contains(KEY_LABEL) || !prefs.contains(KEY_STATUS)) {
            return null
        }
        val label = prefs.getString(KEY_LABEL, null) ?: return null
        val statusName = prefs.getString(KEY_STATUS, null) ?: return null
        val status = try {
            TileStatus.valueOf(statusName)
        } catch (e: IllegalArgumentException) {
            null
        } ?: return null
        val contentDescription = prefs.getString(KEY_CONTENT_DESCRIPTION, null)
        val stateDescription = prefs.getString(KEY_STATE_DESCRIPTION, null)
        val drawableName = prefs.getString(KEY_DRAWABLE, null)
        val subtitle = prefs.getString(KEY_SUBTITLE, null)
        return Tile(
            label,
            status,
            contentDescription,
            stateDescription,
            drawableName,
            subtitle
        )
    }

    fun clear(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().clear().apply()
    }

    fun wasTileAddedReported(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getBoolean(KEY_ADDED_REPORTED, false)
    }

    fun setTileAddedReported(context: Context, reported: Boolean) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putBoolean(KEY_ADDED_REPORTED, reported).apply()
    }
}

