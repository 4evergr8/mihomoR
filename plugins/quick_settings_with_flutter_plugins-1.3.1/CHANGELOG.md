## 1.3.1
- ✅ Fixed the regression where `onTileAdded` fired on every `onStartListening`: the handler now runs once per real tile add, while still ensuring callbacks get dispatched after cache restores. `onTileRemoved` also resets the state so the next add is reported correctly.

## 1.3.0
- 🐞 Fixed a bug where, after updating the host app, stale background callback handles could break tile callbacks. The plugin now automatically clears its stored state when the app `app_version_name` or `versionCode` changes and lets Dart re‑register fresh callbacks.

## 1.2.1
- 🛠️ `updateTile`/`syncTile` now work even when no Flutter `Activity` is attached (uses `applicationContext`), so tiles stay in sync while the app is closed.
- 📦 Small cleanup of duplicate files introduced in 1.2.0.

## 1.2.0
- ✨ Added `QuickSettings.syncTile` to push tile state updates from Flutter code and keep the tile UI aligned with the app.
- 💾 Tile state is cached on the native side and restored after process kills or device restarts; manual sync triggers an immediate refresh via `TileService.requestListeningState`.
- 🧩 The background Flutter engine now registers `GeneratedPluginRegistrant`, so invoking other Flutter plugins from tile callbacks works reliably.
- 📚 Updated README with examples of the new sync API.

## 1.1.0
- This is a fork of the original plugin [quick_settings](https://pub.dev/packages/quick_settings)
- Add support of calling functions (from tile) that use some flutter plugins;
- fixed common bug wile building an app and added namespace for AGP 7 support

## 1.0.1
- 🐛 Fix kotlin stdlib conflicts
- 📝 Update documentation


## 1.0.0+2
* Update doc image path

## 1.0.0+1
* 📝 Update documentation

## 1.0.0

* Ask to add your Tile to Quick Settings
* Handle onTileClicked, onTileAdded, onTileRemoved (even when the app is not running)
