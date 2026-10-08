import 'package:flutter/services.dart';

String loadCollection() => '';
void saveCollection(String value) {}
void playSound(String kind) {
  SystemSound.play(SystemSoundType.click);
}

void stopSound() {}
