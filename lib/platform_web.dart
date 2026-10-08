import 'dart:js_interop';

@JS('hamsterBridge.load')
external JSString _load();
@JS('hamsterBridge.save')
external void _save(JSString value);
@JS('hamsterBridge.play')
external void _play(JSString kind);
@JS('hamsterBridge.stop')
external void _stop();
String loadCollection() => _load().toDart;
void saveCollection(String value) => _save(value.toJS);
void playSound(String kind) => _play(kind.toJS);
void stopSound() => _stop();
