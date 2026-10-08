import 'dart:math';

const hamsterPhotos = <String>[
  'https://kmc2400.github.io/hamster-images/acidfern-_ASImGUewVM-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/adela-monczkova-IvJa_c8THWg-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/adela-monczkova-qmiID5T8_uA-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/alex-konokh-6MKJbkZ0qNY-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/andy-holmes-fyc0u7SoBOQ-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/bjorn-antonissen-YkRRIEkVajk-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/bonnie-kittle-MUcxe_wDurE-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/denis-bayer-4KC4hUWCtJI-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/doina-gavrilov-BpAnE1DVWEs-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/finney-kFh7PHBKWd0-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/frances-goldberg-mnOVgsxg-8E-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/frenjamin-benklin-2Px6-jGGH_w-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/frenjamin-benklin-6yKTcxJhbQ8-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/frenjamin-benklin-8gOu6m_tj-0-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/frenjamin-benklin-i0OwUyZ4QW0-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/frenjamin-benklin-KIXHGKPswE0-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/frenjamin-benklin-waKf09YkDcw-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/guillermo-velarde-JlI9qNsD-Uw-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/gustavo-zambelli-mwwRDU_ekjw-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/henry-lai-2uTVeLDQQkk-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/henry-lai-ZKLsj6xruAk-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/jaroslaw-slodkiewicz-SDIIfq6nhFU-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/jay-nlper-Tpff0kOfhYw-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/juliya-sidorova-FOxMZK1VQS8-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/katherine-mcadoo-vSS2_KfzbLY-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/kim-green-1VY30CTcsqE-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/kim-green-D_pXn7cueOs-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/leslie-soto-Py1iPnpzLoo-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/matt-bero-wMXetxdXeZM-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/melissa-keizer-2Qs3kvXGwjg-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/melissa-keizer-UTv7cPiNsug-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/nick-fewings--dtKoaHpi9M-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/nikolett-emmert-4WDzXJrPNLE-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/nikolett-emmert-FsBKr0AOirM-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/nikolett-emmert-WiBYpESTwb8-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/nikolett-emmert-ZSc4X_rqjL8-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/nils-schirmer-cKYM8KMwaUQ-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/peter-steiner-1973-fcXMGrmk64o-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/raychan-8IW8f37QAYA-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/ricky-kharawala-adK3Vu70DEQ-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/silje-roseneng-cMp84C0fPSg-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/sunira-moses-aXK_a0xxmW0-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/sunira-moses-r149yvhlJ4Q-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/yosei-g-OVgE3m4MHKM-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/zdenek-machacek-WZC1_6ChfMs-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/zhaoli-jin-57ePgTDfwWM-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/zhaoli-jin-83lFoPXYbkA-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/zhaoli-jin-cgnDJkzWkTg-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/zhaoli-jin-g6q1ko1ghos-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/zhaoli-jin-MwJ-VkhxOBs-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/zhaoli-jin-ntpFNTy_XzY-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/zhaoli-jin-u33lLlcLoys-unsplash.jpg',
  'https://kmc2400.github.io/hamster-images/zhaoli-jin-Xtb_lO_9r6Q-unsplash.jpg',
];

const rarityNames = ['R', 'SR', 'UR'];
const rarityTitles = ['ほっぺの住人', 'ひまわりの王様', '伝説のもふ神'];
const hamsterNames = [
  'おもち',
  'きなこ',
  'まめ',
  'こむぎ',
  'しらたま',
  'ぽてと',
  'くるみ',
  'だいふく',
  'ちくわ',
  'わたあめ',
  'あんこ',
  'むぎ',
];

int rollRarity(int roll) {
  if (roll < 0 || roll >= 100) throw RangeError.range(roll, 0, 99);
  return roll < 10
      ? 2
      : roll < 40
      ? 1
      : 0;
}

class GachaResult {
  const GachaResult(this.photo, this.rarity);
  final int photo;
  final int rarity;
  String get name => hamsterNames[photo % hamsterNames.length];
  String get id =>
      '${rarityNames[rarity]}-${(photo + 1).toString().padLeft(3, '0')}';
  static GachaResult draw(Random random) => GachaResult(
    random.nextInt(hamsterPhotos.length),
    rollRarity(random.nextInt(100)),
  );
}
