import 'package:clashroot/service/control.dart';
import 'package:quick_settings_with_flutter_plugins/quick_settings.dart';

@pragma('vm:entry-point')
Tile onTileClicked(Tile tile) {
  final oldStatus = tile.tileStatus;
  if (oldStatus == TileStatus.active) {
    try {
      clashKill();
      tile
        ..tileStatus = TileStatus.inactive
        ..label = "ClashRoot"
        ..drawableName = "alarm_off"
        ..contentDescription = "Clash核心已停止";
    } catch (e) {
      return tile;
    }
  } else {
    try {
      clashStart();
      tile
        ..tileStatus = TileStatus.active
        ..label = "ClashRoot"
        ..drawableName = "alarm_on"
        ..contentDescription = "Clash核心已启动";
    } catch (e) {
      return tile;
    }
  }

  return tile;
}

@pragma('vm:entry-point')
Tile onTileAdded(Tile tile) {
  tile
    ..tileStatus = TileStatus.inactive
    ..label = "ClashRoot"
    ..drawableName = "alarm_off"
    ..contentDescription = "Clash核心已停止";
  return tile;
}

@pragma('vm:entry-point')
void onTileRemoved() {}
