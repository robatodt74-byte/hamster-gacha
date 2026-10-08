import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'hamster_data.dart';
import 'platform_bridge.dart' as platform;
import 'stage_art.dart';

// Hallmark: playful arcade theatre; cream type, coral cabinet, mint stage.
const ink = Color(0xFF251731);
const cream = Color(0xFFFFF4DA);
const coral = Color(0xFFFF685B);
const mint = Color(0xFFBCE9D6);
const gold = Color(0xFFFFD35C);
const plum = Color(0xFF50314F);

void main() => runApp(const HamsterApp());

class HamsterApp extends StatelessWidget {
  const HamsterApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'もふもふ大放出 | HAMSTER FEVER',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: coral, surface: cream),
      scaffoldBackgroundColor: ink,
      fontFamily: 'sans-serif',
      textTheme: const TextTheme(bodyMedium: TextStyle(color: cream)),
    ),
    home: const HamsterGacha(),
  );
}

enum GachaPhase { ready, charge, reach, push, reveal, result }

class HamsterGacha extends StatefulWidget {
  const HamsterGacha({super.key, this.random});
  final Random? random;
  @override
  State<HamsterGacha> createState() => _HamsterGachaState();
}

class _HamsterGachaState extends State<HamsterGacha>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final Random _random;
  late final AnimationController _ambient, _sequence, _reveal;
  GachaPhase _phase = GachaPhase.ready;
  GachaResult? _pending, _result;
  final Map<int, int> _album = {};
  final List<GachaResult> _recent = [];
  int _plays = 0, _cheers = 0;
  bool _muted = true, _quiet = false, _reduced = false, _foreground = true;
  bool get _spinning =>
      _phase == GachaPhase.charge || _phase == GachaPhase.reach;
  bool get _busy =>
      _spinning || _phase == GachaPhase.push || _phase == GachaPhase.reveal;
  Color get _accent => _result?.rarity == 2
      ? gold
      : _result?.rarity == 1
      ? mint
      : coral;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _random = widget.random ?? Random();
    _restore();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    _sequence =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 3800),
          )
          ..addListener(() {
            if (_phase == GachaPhase.charge && _sequence.value >= .44) {
              setState(() => _phase = GachaPhase.reach);
              _sound('reach');
            }
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && _spinning) {
              setState(() => _phase = GachaPhase.push);
              _sound('push');
            }
          });
    _reveal =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1700),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed &&
              _phase == GachaPhase.reveal) {
            setState(() => _phase = GachaPhase.result);
          }
        });
  }

  void _restore() {
    try {
      final value = jsonDecode(platform.loadCollection());
      if (value is! Map<String, dynamic>) return;
      final plays = value['plays'];
      if (plays is int && plays >= 0) _plays = plays;
      final album = value['album'];
      if (album is Map<String, dynamic>) {
        for (final entry in album.entries) {
          final photo = int.tryParse(entry.key), tier = entry.value;
          if (photo != null &&
              photo >= 0 &&
              photo < hamsterPhotos.length &&
              tier is int &&
              tier >= 0 &&
              tier <= 2) {
            _album[photo] = tier;
          }
        }
      }
    } catch (_) {
      /* A new collection is valid when storage is unavailable. */
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  void _syncMotion() {
    _reduced = _quiet || MediaQuery.disableAnimationsOf(context);
    if (_reduced || !_foreground) {
      _ambient.stop();
    } else if (!_ambient.isAnimating) {
      _ambient.repeat();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      platform.stopSound();
      _sequence.stop();
      _reveal.stop();
    } else {
      if (_spinning) _sequence.forward();
      if (_phase == GachaPhase.reveal) _reveal.forward();
    }
    _syncMotion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ambient.dispose();
    _sequence.dispose();
    _reveal.dispose();
    platform.stopSound();
    super.dispose();
  }

  void _sound(String kind) {
    if (!_muted && _foreground) platform.playSound(kind);
  }

  void _spin() {
    if (_busy) return;
    _reveal.reset();
    setState(() {
      _pending = GachaResult.draw(_random);
      _result = null;
      _cheers = 0;
      _phase = GachaPhase.charge;
    });
    _sound('tap');
    if (!_reduced) HapticFeedback.lightImpact();
    _sequence.duration = Duration(milliseconds: _reduced ? 1400 : 3800);
    _sequence.forward(from: 0);
  }

  void _open({bool skip = false}) {
    if (_pending == null) return;
    if (!skip && _phase != GachaPhase.push) return;
    _sequence.stop();
    final result = _pending!;
    setState(() {
      _pending = null; // One draw can be committed only once.
      _result = result;
      _plays++;
      _album[result.photo] = max(_album[result.photo] ?? 0, result.rarity);
      _recent.insert(0, result);
      if (_recent.length > 6) _recent.removeLast();
      _phase = skip ? GachaPhase.result : GachaPhase.reveal;
    });
    platform.saveCollection(
      jsonEncode({
        'plays': _plays,
        'album': _album.map((key, value) => MapEntry('$key', value)),
      }),
    );
    _sound('win');
    if (!skip) {
      if (!_reduced) HapticFeedback.mediumImpact();
      _reveal.duration = Duration(milliseconds: _reduced ? 350 : 1700);
      _reveal.forward(from: 0);
    }
  }

  void _cheer() {
    if (!_spinning || _cheers >= 30) return;
    setState(() => _cheers++);
    _sound('tap');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: AnimatedBuilder(
        animation: Listenable.merge([_ambient, _sequence, _reveal]),
        builder: (context, _) {
          final time = _reduced ? 0.0 : _ambient.value;
          return Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: TheatrePainter(
                      time: time,
                      celebrating: _result != null,
                      reduced: _reduced,
                    ),
                  ),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 980;
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 40 : 18,
                      vertical: 16,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1240),
                        child: Column(
                          children: [
                            _header(),
                            SizedBox(height: wide ? 32 : 18),
                            if (wide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(flex: 3, child: _intro(left: true)),
                                  const SizedBox(width: 30),
                                  Expanded(flex: 5, child: _cabinet(time, 440)),
                                  const SizedBox(width: 30),
                                  Expanded(flex: 2, child: _sideNotes()),
                                ],
                              )
                            else ...[
                              _intro(),
                              const SizedBox(height: 20),
                              _cabinet(
                                time,
                                min(340, constraints.maxWidth * .86),
                              ),
                            ],
                            const SizedBox(height: 24),
                            _collectionStrip(),
                            const SizedBox(height: 20),
                            _footer(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (_phase == GachaPhase.reveal && !_reduced)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: RevealPainter(
                        progress: _reveal.value,
                        color: _accent,
                        rare: _result!.rarity == 2,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );

  Widget _header() => Row(
    children: [
      const SizedBox(
        width: 34,
        height: 34,
        child: CustomPaint(painter: HamsterPainter()),
      ),
      const SizedBox(width: 10),
      const Expanded(
        child: Text(
          'HAMSTER\nFEVER CLUB',
          style: TextStyle(
            color: cream,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 2,
            height: 1.15,
          ),
        ),
      ),
      IconButton(
        tooltip: _muted ? '音をオンにする' : '音をオフにする',
        onPressed: () {
          setState(() => _muted = !_muted);
          if (_muted) {
            platform.stopSound();
          } else {
            _sound('tap');
          }
        },
        icon: Icon(
          _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          color: cream,
          size: 21,
        ),
      ),
      IconButton(
        tooltip: _quiet ? '演出を通常にする' : '動きを控えめにする',
        onPressed: () {
          setState(() => _quiet = !_quiet);
          _syncMotion();
        },
        icon: Icon(
          _quiet ? Icons.motion_photos_off_rounded : Icons.auto_awesome_rounded,
          color: _quiet ? gold : cream,
          size: 21,
        ),
      ),
    ],
  );

  Widget _intro({bool left = false}) => Column(
    crossAxisAlignment: left
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.center,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: coral),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Text(
          'NO COINS. JUST CUTE.',
          style: TextStyle(
            color: coral,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ),
      const SizedBox(height: 13),
      Text(
        'もふもふ、\n大放出。',
        textAlign: left ? TextAlign.left : TextAlign.center,
        style: TextStyle(
          fontSize: left ? 64 : 43,
          fontWeight: FontWeight.w900,
          color: cream,
          letterSpacing: -2,
          height: 1.12,
          shadows: const [Shadow(color: coral, offset: Offset(3, 4))],
        ),
      ),
      const SizedBox(height: 14),
      Text(
        '回して、ためて、もふっと解放。\n今日の相棒、だれにする？',
        textAlign: left ? TextAlign.left : TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFC9B9CA),
          fontSize: 13,
          height: 1.8,
        ),
      ),
      if (left) ...[
        const SizedBox(height: 30),
        Row(
          children: [
            _stat('${_album.length}'.padLeft(2, '0'), '/ 53 FRIENDS'),
            const SizedBox(width: 24),
            _stat('$_plays'.padLeft(3, '0'), 'TOTAL SPINS'),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          '01  回す\n02  ほっぺをチャージ\n03  PUSHでもふっと登場',
          style: TextStyle(color: cream, fontSize: 12, height: 2.3),
        ),
      ],
    ],
  );

  Widget _stat(String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(
          color: gold,
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFFC9B9CA),
          fontSize: 8,
          letterSpacing: 1.4,
        ),
      ),
    ],
  );

  Widget _sideNotes() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Transform.rotate(
        angle: .08,
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: mint,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '本日も\nかわいい確定。',
                style: TextStyle(
                  color: ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 18),
              const SizedBox(
                height: 100,
                width: 110,
                child: CustomPaint(
                  painter: HamsterPainter(tone: Color(0xFFB89A85)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$_plays 回まわしました',
                style: const TextStyle(
                  color: ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        'R   60%\nSR  30%\nUR  10%',
        style: TextStyle(
          color: cream,
          fontSize: 12,
          height: 2,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'レア度と写真は別々に抽選。\nどの写真も同じ確率です。',
        style: TextStyle(color: Color(0xFFC9B9CA), fontSize: 10, height: 1.7),
      ),
    ],
  );

  Widget _cabinet(double time, double height) {
    final active = _phase != GachaPhase.ready;
    final shake = !_reduced && _phase == GachaPhase.reach
        ? sin(_sequence.value * 130) * 2
        : 0.0;
    final words = switch (_phase) {
      GachaPhase.ready => 'ほっぺ、充電できてます。',
      GachaPhase.charge => 'もふもふエネルギー、充電中…',
      GachaPhase.reach => 'ほっぺが…ざわついている！',
      GachaPhase.push => '準備はいい？ せーので、PUSH！',
      GachaPhase.reveal || GachaPhase.result => rarityTitles[_result!.rarity],
    };
    return Transform.translate(
      offset: Offset(shake, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        decoration: BoxDecoration(
          color: coral,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFFF9C80), width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0xFF9C393C), offset: Offset(0, 8)),
            BoxShadow(
              color: Colors.black26,
              blurRadius: 30,
              offset: Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: i == 1 ? gold : cream,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                const Expanded(
                  child: Text(
                    'THE MOFU-MOFU MACHINE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ink,
                      fontSize: 9,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(21),
              child: SizedBox(
                height: height,
                width: double.infinity,
                child: GestureDetector(
                  onTap: _spinning ? _cheer : null,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: MachinePainter(
                          time: time,
                          energy: _spinning
                              ? _sequence.value
                              : _phase == GachaPhase.push
                              ? 1
                              : 0,
                          reduced: _reduced,
                        ),
                      ),
                      if (_result == null) ...[
                        _friend(
                          .08,
                          .48,
                          66,
                          const Color(0xFFB49587),
                          time,
                          '出番まだ？',
                        ),
                        _friend(
                          .77,
                          .53,
                          62,
                          const Color(0xFFF4D395),
                          time + .3,
                          'もふ、待機。',
                        ),
                        Align(
                          alignment: const Alignment(0, .25),
                          child: Transform.translate(
                            offset: Offset(
                              0,
                              _reduced ? 0 : sin(time * pi * 4) * 7,
                            ),
                            child: SizedBox(
                              width: height * .60,
                              height: height * .61,
                              child: CustomPaint(
                                painter: HamsterPainter(
                                  tone: const Color(0xFFE5B777),
                                  happy: _spinning || _phase == GachaPhase.push,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 20,
                          left: 12,
                          right: 12,
                          child: Column(
                            children: [
                              Text(
                                _phase == GachaPhase.reach
                                    ? '激 も ふ リ ー チ'
                                    : _phase == GachaPhase.push
                                    ? 'かわいい、解放のとき。'
                                    : 'ほっぺの向こうに、運命。',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _phase == GachaPhase.reach
                                      ? coral
                                      : ink,
                                  fontSize: _phase == GachaPhase.reach
                                      ? 23
                                      : 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _spinning
                                    ? 'タップで応援 ×$_cheers'
                                    : '53 FRIENDS / EVERY SPIN IS A WIN',
                                style: const TextStyle(
                                  color: plum,
                                  fontSize: 8,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_phase == GachaPhase.push)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Text(
                              'PUSHで登場！',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: ink,
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                                shadows: [
                                  Shadow(
                                    color: cream.withValues(alpha: .8),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_spinning)
                          Positioned(
                            bottom: 14,
                            left: 34,
                            right: 34,
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(9),
                                  child: LinearProgressIndicator(
                                    value: _sequence.value,
                                    minHeight: 8,
                                    color: coral,
                                    backgroundColor: cream,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  '応援は演出のみ。抽選結果は変わりません',
                                  style: TextStyle(color: plum, fontSize: 8),
                                ),
                              ],
                            ),
                          ),
                      ] else
                        _resultCard(height),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _reels(),
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                words,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                key: const Key('spin-button'),
                onPressed: _spinning || _phase == GachaPhase.reveal
                    ? null
                    : _phase == GachaPhase.push
                    ? () => _open()
                    : _spin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _phase == GachaPhase.push ? ink : gold,
                  foregroundColor: _phase == GachaPhase.push ? cream : ink,
                  disabledBackgroundColor: const Color(0xFFB74242),
                  disabledForegroundColor: cream,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: ink, width: 2),
                  ),
                ),
                child: Text(
                  _spinning
                      ? 'もふもふ充電中…'
                      : _phase == GachaPhase.reveal
                      ? 'お迎え中…'
                      : _phase == GachaPhase.push
                      ? 'PUSH !  もふっと解放'
                      : _phase == GachaPhase.result
                      ? 'もう一回、もふる！'
                      : 'ガチャを回す',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                    letterSpacing: .4,
                  ),
                ),
              ),
            ),
            if (_busy)
              TextButton(
                key: const Key('skip-button'),
                onPressed: _pending != null
                    ? () => _open(skip: true)
                    : () {
                        _reveal.stop();
                        setState(() => _phase = GachaPhase.result);
                      },
                child: const Text(
                  '演出をスキップ →',
                  style: TextStyle(color: ink, fontSize: 11),
                ),
              ),
            if (!active || !_busy)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  '無料・回数制限なし・お金はかかりません',
                  style: TextStyle(color: ink, fontSize: 9),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _friend(
    double x,
    double y,
    double size,
    Color tone,
    double time,
    String message,
  ) => Align(
    alignment: Alignment(x * 2 - 1, y * 2 - 1),
    child: Transform.rotate(
      angle: _reduced ? 0 : sin(time * pi * 2) * .12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 9,
                color: ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(painter: HamsterPainter(tone: tone)),
          ),
        ],
      ),
    ),
  );

  Widget _reels() {
    final tick = (_sequence.value * 32).floor();
    return Row(
      children: List.generate(3, (i) {
        final stopped =
            _phase == GachaPhase.push ||
            _result != null ||
            (_spinning && _sequence.value > [.44, .68, 1.0][i]);
        final symbols = [
          Icons.pets_rounded,
          Icons.local_florist_rounded,
          Icons.star_rounded,
          Icons.favorite_rounded,
        ];
        return Expanded(
          child: Container(
            height: 48,
            margin: EdgeInsets.only(left: i == 0 ? 0 : 7),
            decoration: BoxDecoration(
              color: ink,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cream.withValues(alpha: .5)),
            ),
            child: Center(
              child: stopped
                  ? Text(
                      '7',
                      style: TextStyle(
                        color: _result?.rarity == 2 ? gold : cream,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : Icon(
                      symbols[(_spinning ? tick + i : i) % symbols.length],
                      color: gold,
                      size: 27,
                    ),
            ),
          ),
        );
      }),
    );
  }

  Widget _resultCard(double height) {
    final result = _result!;
    final reveal = _phase == GachaPhase.reveal && !_reduced;
    final progress = reveal ? _reveal.value : 1.0;
    final scale = reveal
        ? .8 + .2 * Curves.easeOutBack.transform(min(1, progress * 2))
        : 1.0;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Transform.scale(
        scale: scale,
        child: Container(
          decoration: BoxDecoration(
            color: cream,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ink, width: 2),
          ),
          padding: const EdgeInsets.all(9),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _photo(result.photo),
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _accent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            rarityNames[result.rarity],
                            style: const TextStyle(
                              color: ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Transform.rotate(
                          angle: -.10,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            color: ink,
                            child: const Text(
                              'WELCOME!',
                              style: TextStyle(
                                color: cream,
                                fontSize: 8,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${result.name} がやってきた！',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${result.id}  /  ${rarityTitles[result.rarity]}',
                style: const TextStyle(color: plum, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photo(int index) => Image.network(
    hamsterPhotos[index],
    fit: BoxFit.cover,
    loadingBuilder: (context, child, loading) => loading == null
        ? child
        : const ColoredBox(
            color: mint,
            child: Center(
              child: SizedBox(
                width: 70,
                height: 70,
                child: CustomPaint(painter: HamsterPainter()),
              ),
            ),
          ),
    errorBuilder: (context, error, stack) => ColoredBox(
      color: mint,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxHeight < 120 || constraints.maxWidth < 120;
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: min(90, constraints.maxWidth * .7),
                  height: min(90, constraints.maxHeight * .65),
                  child: const CustomPaint(painter: HamsterPainter()),
                ),
                if (!compact)
                  const Text(
                    '写真は休憩中。お迎えは完了！',
                    style: TextStyle(color: ink, fontSize: 10),
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );

  Widget _collectionStrip() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'YOUR LITTLE FRIENDS',
              style: TextStyle(
                color: cream,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
          ),
          TextButton(
            onPressed: _busy ? null : _showAlbum,
            child: Text(
              '図鑑 ${_album.length}/53 →',
              style: const TextStyle(
                color: gold,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      SizedBox(
        height: 78,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: max(6, _recent.length),
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final result = index < _recent.length ? _recent[index] : null;
            return Container(
              width: 80,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF3D2B46),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF6B506E)),
              ),
              child: result == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.pets_outlined,
                          color: Color(0xFF9B7E9D),
                          size: 22,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'NO. ${(index + 1).toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Color(0xFFB299B7),
                            fontSize: 8,
                          ),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: _photo(result.photo),
                    ),
            );
          },
        ),
      ),
    ],
  );

  void _showAlbum() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cream,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .75,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'もふもふ図鑑  ${_album.length}/53',
                        style: const TextStyle(
                          color: ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '図鑑を閉じる',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: ink),
                    ),
                  ],
                ),
                const Text(
                  'ブラウザ版はこの端末に保存。最近のお迎えは今回の訪問分。',
                  style: TextStyle(color: plum, fontSize: 10),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 170,
                          childAspectRatio: .8,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: hamsterPhotos.length,
                    itemBuilder: (context, i) => Container(
                      decoration: BoxDecoration(
                        color: mint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: _album.containsKey(i)
                                  ? _photo(i)
                                  : const Center(
                                      child: Icon(
                                        Icons.lock_outline_rounded,
                                        color: plum,
                                        size: 30,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            _album.containsKey(i)
                                ? '${hamsterNames[i % hamsterNames.length]} · ${rarityNames[_album[i]!]}  #${i + 1}'
                                : 'まだ会っていない #${i + 1}',
                            style: const TextStyle(
                              color: ink,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer() => const Column(
    children: [
      Text(
        'R 60%   /   SR 30%   /   UR 10%',
        style: TextStyle(
          color: cream,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.6,
        ),
      ),
      SizedBox(height: 6),
      Text(
        '写真53枚は同確率。レア度は独立抽選。応援で確率は変わりません。',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFFB49EB9), fontSize: 9, height: 1.8),
      ),
      SizedBox(height: 16),
      Text(
        'A LITTLE SPIN, A LOT OF FLUFF.',
        style: TextStyle(
          color: Color(0xFF9C809F),
          fontSize: 8,
          letterSpacing: 2,
        ),
      ),
    ],
  );
}
