import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const CyberStrikeApp());

class CyberStrikeApp extends StatelessWidget {
  const CyberStrikeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Cyber Strike',
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          scaffoldBackgroundColor: const Color(0xFF050816),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00F5FF),
            secondary: Color(0xFFFF2BD6),
          ),
        ),
        home: const GameScreen(),
      );
}

enum EnemyKind { scout, interceptor, tank, phantom }
enum PickupKind { twinLaser, spreadShot, rapidFire, shield }

class Enemy {
  Offset position;
  final EnemyKind kind;
  final double speed;
  final double radius;
  final double drift;
  double phase = 0;
  int hp;
  bool dead = false;

  Enemy(this.position, this.kind, this.speed, this.radius, this.drift, this.hp);
}

class Bullet {
  Offset position;
  final Offset velocity;
  final double radius;
  bool dead = false;
  Bullet(this.position, {this.velocity = const Offset(0, -10), this.radius = 3});
}

class Pickup {
  Offset position;
  final PickupKind kind;
  final double speed;
  double spin = 0;
  bool dead = false;
  Pickup(this.position, this.kind, this.speed);
}

class Particle {
  Offset position;
  final Offset velocity;
  final Color color;
  int life;
  Particle(this.position, this.velocity, this.color, this.life);
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final math.Random _random = math.Random();
  final FocusNode _keyboardFocus = FocusNode(debugLabel: 'Cyber Strike controls');
  final List<Enemy> _enemies = [];
  final List<Bullet> _bullets = [];
  final List<Pickup> _pickups = [];
  final List<Particle> _particles = [];
  Timer? _timer;
  Size _size = Size.zero;
  Offset _player = const Offset(.5, .82);
  bool _running = false;
  bool _gameOver = false;
  bool _paused = false;
  int _score = 0;
  int _level = 1;
  int _health = 3;
  int _frame = 0;
  int _shootCooldown = 0;
  int _weaponTier = 1;
  int _weaponTicks = 0;
  int _shieldTicks = 0;
  int _damageCooldown = 0;
  String _notice = '';
  int _noticeTicks = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _keyboardFocus.dispose();
    super.dispose();
  }

  int _levelForScore(int score) {
    if (score >= 100) return 4;
    if (score >= 50) return 3;
    if (score >= 20) return 2;
    return 1;
  }

  void _startGame() {
    setState(() {
      _enemies.clear();
      _bullets.clear();
      _pickups.clear();
      _particles.clear();
      _score = 0;
      _level = 1;
      _health = 3;
      _player = const Offset(.5, .82);
      _frame = 0;
      _shootCooldown = 0;
      _weaponTier = 1;
      _weaponTicks = 0;
      _shieldTicks = 0;
      _damageCooldown = 0;
      _notice = 'MISSION START';
      _noticeTicks = 100;
      _gameOver = false;
      _paused = false;
      _running = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _keyboardFocus.requestFocus();
    });
  }

  void _announce(String text) {
    _notice = text;
    _noticeTicks = 100;
  }

  void _burst(Offset at, Color color, {int count = 12}) {
    for (int i = 0; i < count; i++) {
      final a = _random.nextDouble() * math.pi * 2;
      final speed = .8 + _random.nextDouble() * 3.5;
      _particles.add(Particle(
        at,
        Offset(math.cos(a) * speed, math.sin(a) * speed),
        color,
        16 + _random.nextInt(20),
      ));
    }
  }

  void _fire(Offset ship) {
    final x = ship.dx;
    final y = ship.dy - 23;
    if (_weaponTier <= 1) {
      _bullets.add(Bullet(Offset(x, y)));
    } else if (_weaponTier == 2) {
      _bullets
        ..add(Bullet(Offset(x - 8, y), radius: 3.2))
        ..add(Bullet(Offset(x + 8, y), radius: 3.2));
    } else if (_weaponTier == 3) {
      _bullets
        ..add(Bullet(Offset(x, y), radius: 3.5))
        ..add(Bullet(Offset(x - 5, y), velocity: const Offset(-2.4, -9.2), radius: 3))
        ..add(Bullet(Offset(x + 5, y), velocity: const Offset(2.4, -9.2), radius: 3));
    } else {
      _bullets
        ..add(Bullet(Offset(x - 10, y), radius: 3.5))
        ..add(Bullet(Offset(x, y - 5), radius: 4.2))
        ..add(Bullet(Offset(x + 10, y), radius: 3.5))
        ..add(Bullet(Offset(x - 4, y), velocity: const Offset(-3.5, -9.0), radius: 3))
        ..add(Bullet(Offset(x + 4, y), velocity: const Offset(3.5, -9.0), radius: 3));
    }
  }

  void _spawnEnemy() {
    final x = 24.0 + _random.nextDouble() * math.max(1.0, _size.width - 48.0).toDouble();
    EnemyKind kind;
    if (_level == 1) {
      kind = EnemyKind.scout;
    } else if (_level == 2) {
      kind = _random.nextDouble() < .65 ? EnemyKind.interceptor : EnemyKind.scout;
    } else if (_level == 3) {
      final r = _random.nextDouble();
      kind = r < .45 ? EnemyKind.interceptor : (r < .78 ? EnemyKind.tank : EnemyKind.scout);
    } else {
      final r = _random.nextDouble();
      kind = r < .30 ? EnemyKind.phantom : (r < .62 ? EnemyKind.tank : EnemyKind.interceptor);
    }
    final radius = switch (kind) {
      EnemyKind.scout => 14.0,
      EnemyKind.interceptor => 17.0,
      EnemyKind.tank => 22.0,
      EnemyKind.phantom => 19.0,
    };
    final speed = switch (kind) {
      EnemyKind.scout => 2.0 + _level * .25 + _random.nextDouble(),
      EnemyKind.interceptor => 2.3 + _level * .30 + _random.nextDouble(),
      EnemyKind.tank => 1.1 + _level * .18 + _random.nextDouble() * .5,
      EnemyKind.phantom => 2.5 + _level * .28 + _random.nextDouble(),
    };
    final hp = switch (kind) {
      EnemyKind.scout => 1,
      EnemyKind.interceptor => 2,
      EnemyKind.tank => 4,
      EnemyKind.phantom => 3,
    };
    _enemies.add(Enemy(Offset(x, -35), kind, speed, radius,
        kind == EnemyKind.phantom ? 2.8 : 1.4, hp));
  }

  void _spawnPickup() {
    final available = <PickupKind>[
      if (_level >= 2) PickupKind.twinLaser,
      if (_level >= 3) PickupKind.spreadShot,
      if (_level >= 4) PickupKind.rapidFire,
      PickupKind.shield,
    ];
    final kind = available[_random.nextInt(available.length)];
    _pickups.add(Pickup(
      Offset(22.0 + _random.nextDouble() * math.max(1.0, _size.width - 44.0).toDouble(), -25.0),
      kind,
      1.8 + _random.nextDouble() * .8,
    ));
  }

  void _collect(Pickup pickup) {
    switch (pickup.kind) {
      case PickupKind.twinLaser:
        _weaponTier = math.max(_weaponTier, 2).toInt();
        _weaponTicks = 60 * 12;
        _announce('TWIN LASERS UNLOCKED');
        _burst(pickup.position, const Color(0xFF00F5FF));
        break;
      case PickupKind.spreadShot:
        _weaponTier = math.max(_weaponTier, 3).toInt();
        _weaponTicks = 60 * 12;
        _announce('SPREAD SHOT UNLOCKED');
        _burst(pickup.position, const Color(0xFFFF2BD6));
        break;
      case PickupKind.rapidFire:
        _weaponTier = 4;
        _weaponTicks = 60 * 12;
        _announce('OVERDRIVE CANNON UNLOCKED');
        _burst(pickup.position, const Color(0xFFFFB347));
        break;
      case PickupKind.shield:
        _shieldTicks = 60 * 7;
        _announce('SHIELD ACTIVATED');
        _burst(pickup.position, const Color(0xFF62FFB5));
        break;
    }
  }


  KeyEventResult _handleKeyEvent(KeyEvent event) {
    // React to presses and OS key-repeat, not key-release events.
    if (event is KeyUpEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    if (!_running) {
      if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter ||
          key == LogicalKeyboardKey.space ||
          key == LogicalKeyboardKey.keyR) {
        _startGame();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (key == LogicalKeyboardKey.keyR) {
      _startGame();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyP ||
        key == LogicalKeyboardKey.escape) {
      setState(() => _paused = !_paused);
      return KeyEventResult.handled;
    }

    if (_paused) {
      if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.space) {
        setState(() => _paused = false);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    double dx = 0;
    double dy = 0;
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      dx = -24;
    } else if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyD) {
      dx = 24;
    } else if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      dy = -19;
    } else if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) {
      dy = 19;
    }

    if (dx != 0 || dy != 0) {
      // Movement is sampled every frame below for smooth held-key control.
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _applyKeyboardMovement() {
    if (!_keyboardFocus.hasFocus || _size == Size.zero) return;
    final keyboard = HardwareKeyboard.instance;
    final left = keyboard.isLogicalKeyPressed(LogicalKeyboardKey.arrowLeft) ||
        keyboard.isLogicalKeyPressed(LogicalKeyboardKey.keyA);
    final right = keyboard.isLogicalKeyPressed(LogicalKeyboardKey.arrowRight) ||
        keyboard.isLogicalKeyPressed(LogicalKeyboardKey.keyD);
    final up = keyboard.isLogicalKeyPressed(LogicalKeyboardKey.arrowUp) ||
        keyboard.isLogicalKeyPressed(LogicalKeyboardKey.keyW);
    final down = keyboard.isLogicalKeyPressed(LogicalKeyboardKey.arrowDown) ||
        keyboard.isLogicalKeyPressed(LogicalKeyboardKey.keyS);

    var dx = (right ? 1.0 : 0.0) - (left ? 1.0 : 0.0);
    var dy = (down ? 1.0 : 0.0) - (up ? 1.0 : 0.0);
    if (dx == 0 && dy == 0) return;

    // Normalize diagonal movement so it is not faster than horizontal movement.
    if (dx != 0 && dy != 0) {
      dx *= 0.7071;
      dy *= 0.7071;
    }
    const speedPerFrame = 5.2;
    _player = Offset(
      (_player.dx + dx * speedPerFrame / _size.width)
          .clamp(.055, .945).toDouble(),
      // Keep the ship below the HUD and above the status/control area.
      (_player.dy + dy * speedPerFrame / _size.height)
          .clamp(.16, .88).toDouble(),
    );
  }

  void _tick() {
    if (!_running || _paused || _size == Size.zero) return;
    setState(() {
      _frame++;
      _applyKeyboardMovement();
      final previousLevel = _level;
      _level = _levelForScore(_score);
      if (_level > previousLevel) {
        _announce(switch (_level) {
          2 => 'LEVEL 2  •  INTERCEPTORS INBOUND',
          3 => 'LEVEL 3  •  ARMORED THREATS',
          _ => 'LEVEL 4  •  PHANTOM FLEET',
        });
        _burst(Offset(_size.width / 2, _size.height * .35),
            const Color(0xFF00F5FF), count: 28);
      }

      if (_noticeTicks > 0) _noticeTicks--;
      if (_weaponTicks > 0) {
        _weaponTicks--;
        if (_weaponTicks == 0) {
          _weaponTier = 1;
          _announce('WEAPON BOOST EXPIRED');
        }
      }
      if (_shieldTicks > 0) _shieldTicks--;
      if (_damageCooldown > 0) _damageCooldown--;
      if (_shootCooldown > 0) _shootCooldown--;
      if (_shootCooldown == 0) {
        final playerPx = Offset(_player.dx * _size.width, _player.dy * _size.height);
        _fire(playerPx);
        _shootCooldown = _weaponTier == 4 ? 5 : (_weaponTier == 3 ? 8 : 11);
      }

      final spawnRate = math.max(15, 52 - _level * 7);
      if (_frame % spawnRate == 0) _spawnEnemy();
      if (_frame % 520 == 0) _spawnPickup();

      for (final bullet in _bullets) {
        bullet.position += bullet.velocity;
      }
      _bullets.removeWhere((b) => b.position.dy < -25);

      for (final enemy in _enemies) {
        enemy.phase += .045;
        enemy.position = Offset(
          enemy.position.dx + math.sin(enemy.phase) * enemy.drift,
          enemy.position.dy + enemy.speed,
        );
      }

      final playerPx = Offset(_player.dx * _size.width, _player.dy * _size.height);
      for (final enemy in _enemies) {
        for (final bullet in _bullets) {
          if (!bullet.dead && !enemy.dead &&
              (enemy.position - bullet.position).distance < enemy.radius + bullet.radius) {
            bullet.dead = true;
            enemy.hp--;
            _burst(bullet.position, const Color(0xFF00F5FF), count: 4);
            if (enemy.hp <= 0) {
              enemy.dead = true;
              _score += switch (enemy.kind) {
                EnemyKind.scout => 10,
                EnemyKind.interceptor => 15,
                EnemyKind.tank => 25,
                EnemyKind.phantom => 30,
              };
              _burst(enemy.position, _enemyColor(enemy.kind));
            }
          }
        }
        // Hull damage can ONLY happen on an actual enemy/ship collision.
        // Enemies that escape off-screen are removed without hurting the player.
        if (!enemy.dead && (enemy.position - playerPx).distance < enemy.radius + 17) {
          enemy.dead = true;
          if (_shieldTicks > 0) {
            _shieldTicks = math.max(0, _shieldTicks - 80).toInt();
            _burst(playerPx, const Color(0xFF62FFB5), count: 16);
          } else if (_damageCooldown == 0) {
            _health = math.max(0, _health - 1);
            _damageCooldown = 55; // Brief hit grace period prevents unfair chain damage.
            _burst(playerPx, const Color(0xFFFF4D9D), count: 24);
            _announce('HULL IMPACT');
          } else {
            _burst(enemy.position, const Color(0xFFFF4D9D), count: 7);
          }
        }
        if (enemy.position.dy > _size.height + 35) {
          enemy.dead = true;
        }
      }
      _enemies.removeWhere((e) => e.dead);
      _bullets.removeWhere((b) => b.dead);

      for (final pickup in _pickups) {
        pickup.position = Offset(pickup.position.dx, pickup.position.dy + pickup.speed);
        pickup.spin += .07;
        if ((pickup.position - playerPx).distance < 29) {
          pickup.dead = true;
          _collect(pickup);
        }
      }
      _pickups.removeWhere((p) => p.dead || p.position.dy > _size.height + 30);

      for (final particle in _particles) {
        particle.position += particle.velocity;
        particle.life--;
      }
      _particles.removeWhere((p) => p.life <= 0);

      if (_health <= 0) {
        _health = 0;
        _running = false;
        _gameOver = true;
      }
    });
  }

  Color _enemyColor(EnemyKind kind) => switch (kind) {
        EnemyKind.scout => const Color(0xFFFF4D9D),
        EnemyKind.interceptor => const Color(0xFFB45CFF),
        EnemyKind.tank => const Color(0xFFFF654A),
        EnemyKind.phantom => const Color(0xFFFFD166),
      };

  void _movePlayer(Offset local) {
    if (_size == Size.zero) return;
    setState(() {
      _player = Offset((local.dx / _size.width).clamp(.06, .94).toDouble(), .82);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            _size = Size(constraints.maxWidth, constraints.maxHeight);
            return KeyboardListener(
              focusNode: _keyboardFocus,
              autofocus: true,
              onKeyEvent: _handleKeyEvent,
              child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (d) {
                if (_running && !_paused) _movePlayer(d.localPosition);
              },
              onPanUpdate: (d) {
                if (_running && !_paused) _movePlayer(d.localPosition);
              },
              child: Stack(children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: GamePainter(
                      enemies: _enemies,
                      bullets: _bullets,
                      pickups: _pickups,
                      particles: _particles,
                      player: _player,
                      frame: _frame,
                      running: _running,
                      shieldActive: _shieldTicks > 0,
                      invulnerable: _damageCooldown > 0,
                      weaponTier: _weaponTier,
                    ),
                  ),
                ),
                Positioned(
                  left: 12, right: 12, top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xE8172640), Color(0xD90B1124)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0x6658F4FF)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x1900EFFF), blurRadius: 22, spreadRadius: 1),
                      ],
                    ),
                    child: Row(children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0x2200F5FF),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: const Color(0x6600F5FF)),
                        ),
                        child: const Icon(Icons.bolt_rounded,
                          color: Color(0xFF00F5FF), size: 21),
                      ),
                      const SizedBox(width: 9),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('CYBER STRIKE', style: TextStyle(
                              letterSpacing: 1.7, fontWeight: FontWeight.w900, fontSize: 11)),
                            SizedBox(height: 2),
                            Text('NEBULA DEFENSE SYSTEMS',
                              style: TextStyle(color: Color(0xFF8098B9),
                                letterSpacing: 1.1, fontSize: 7, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      _chip('LVL $_level'),
                      const SizedBox(width: 6),
                      _chip('$_score PTS'),
                    ]),
                  ),
                ),
                Positioned(
                  left: 18, top: 52,
                  child: Row(children: [
                    ...List.generate(3, (i) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(i < _health ? Icons.favorite : Icons.favorite_border,
                        size: 17, color: i < _health
                          ? const Color(0xFFFF2BD6) : Colors.white24),
                    )),
                    const SizedBox(width: 10),
                    if (_weaponTier > 1)
                      _chip(switch (_weaponTier) {
                        2 => 'TWIN LASER',
                        3 => 'SPREAD SHOT',
                        _ => 'OVERDRIVE',
                      }),
                    if (_shieldTicks > 0) ...[
                      const SizedBox(width: 5),
                      _chip('SHIELD'),
                    ],
                  ]),
                ),
                if (_running)
                  Positioned(
                    left: 16, right: 68, top: 82,
                    child: _levelProgress(),
                  ),
                if (_running && !_paused)
                  Positioned(right: 14, top: 45,
                    child: IconButton.filledTonal(
                      onPressed: () => setState(() => _paused = true),
                      icon: const Icon(Icons.pause_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0x3322E6F2),
                        foregroundColor: const Color(0xFF00F5FF),
                      ),
                    )),
                if (_noticeTicks > 0 && _running && !_paused)
                  Positioned(
                    left: 12, right: 12, top: 122,
                    child: IgnorePointer(child: Text(_notice,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF8EFFFF), fontSize: 11,
                        fontWeight: FontWeight.w900, letterSpacing: 2,
                        shadows: [Shadow(color: Color(0xFF00F5FF), blurRadius: 12)],
                      )),
                    ),
                  ),
                if (!_running)
                  _overlay(
                    title: _gameOver ? 'SHIP DESTROYED' : 'READY, PILOT?',
                    subtitle: _gameOver
                        ? 'Final score: $_score  •  Level $_level'
                        : 'Survive the swarm. Collect weapon drops. Own the void.',
                    button: _gameOver ? 'REDEPLOY' : 'START MISSION',
                    onPressed: _startGame,
                  ),
                if (_paused)
                  _overlay(
                    title: 'MISSION PAUSED',
                    subtitle: 'Threats temporarily suspended.',
                    button: 'RESUME',
                    onPressed: () => setState(() => _paused = false),
                    secondary: 'RESTART',
                    onSecondary: _startGame,
                  ),
                if (_running && !_paused)
                  Positioned(
                    bottom: 14, left: 0, right: 0,
                    child: IgnorePointer(child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 15),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xB30B1124),
                        border: Border.all(color: const Color(0x3325E8F2)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'MOVE  WASD / ARROWS     •     AUTO-FIRE     •     P / ESC PAUSE',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF8EA6C8),
                          letterSpacing: 1.0, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    )),
                  ),
              ]),
              ),
            );
          }),
        ),
      );


  Widget _levelProgress() {
    final currentFloor = switch (_level) { 1 => 0, 2 => 20, 3 => 50, _ => 100 };
    final nextGoal = switch (_level) { 1 => 20, 2 => 50, 3 => 100, _ => 150 };
    final progress = (( _score - currentFloor) / (nextGoal - currentFloor))
        .clamp(0.0, 1.0).toDouble();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xA60B1124),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x3326E6F0)),
      ),
      child: Row(children: [
        Text(_level >= 4 ? 'OVERDRIVE' : 'NEXT LVL',
          style: const TextStyle(color: Color(0xFF87A4C9),
            fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: _level >= 4 ? 1 : progress,
              minHeight: 4,
              backgroundColor: const Color(0xFF25314A),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00F5FF)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(_level >= 4 ? 'MAX' : '$_score / $nextGoal',
          style: const TextStyle(color: Color(0xFFB9F9FF),
            fontSize: 8, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xAA10172B),
          border: Border.all(color: const Color(0x5549EAF2)),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(label, style: const TextStyle(
          color: Color(0xFFB9F9FF), fontSize: 9,
          fontWeight: FontWeight.w800, letterSpacing: .8)),
      );

  Widget _overlay({
    required String title,
    required String subtitle,
    required String button,
    required VoidCallback onPressed,
    String? secondary,
    VoidCallback? onSecondary,
  }) => Positioned.fill(
        child: Container(
          color: const Color(0xCC050816),
          child: Center(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Container(
              width: 430,
              padding: const EdgeInsets.all(27),
              decoration: BoxDecoration(
                color: const Color(0xEE0B1124),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0x9900F5FF)),
                boxShadow: const [BoxShadow(
                  color: Color(0x3300F5FF), blurRadius: 35, spreadRadius: 2)],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0x2200F5FF),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0x6655F6FF)),
                  ),
                  child: const Text('SECTOR 09  /  LIVE COMBAT',
                    style: TextStyle(color: Color(0xFF70F8FF),
                      fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ),
                const SizedBox(height: 18),
                const Icon(Icons.rocket_launch_rounded,
                  size: 47, color: Color(0xFF00F5FF)),
                const SizedBox(height: 16),
                Text(title, textAlign: TextAlign.center, style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 12),
                Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(
                  color: Color(0xFF9AAAC7), height: 1.5, fontSize: 13)),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x66151F37),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x2227EAF3)),
                  ),
                  child: const Column(children: [
                    Text('FLIGHT CONTROLS',
                      style: TextStyle(color: Color(0xFF8EA6C8),
                        fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.8)),
                    SizedBox(height: 8),
                    Text('WASD / ARROWS  •  MOVE\nP / ESC  •  PAUSE    R  •  RESTART',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFCCDAEF),
                        fontSize: 10, height: 1.7, fontWeight: FontWeight.w700)),
                  ]),
                ),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, height: 48,
                  child: FilledButton(
                    onPressed: onPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00DDE8),
                      foregroundColor: const Color(0xFF04101C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(button, style: const TextStyle(
                      fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  )),
                if (secondary != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(width: double.infinity, height: 44,
                    child: OutlinedButton(
                      onPressed: onSecondary,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF62DF),
                        side: const BorderSide(color: Color(0x88FF2BD6))),
                      child: Text(secondary,
                        style: const TextStyle(letterSpacing: 1.5)),
                    )),
                ],
              ]),
            ),
          )),
        ),
      );
}

class GamePainter extends CustomPainter {
  final List<Enemy> enemies;
  final List<Bullet> bullets;
  final List<Pickup> pickups;
  final List<Particle> particles;
  final Offset player;
  final int frame;
  final bool running;
  final bool shieldActive;
  final bool invulnerable;
  final int weaponTier;

  GamePainter({
    required this.enemies,
    required this.bullets,
    required this.pickups,
    required this.particles,
    required this.player,
    required this.frame,
    required this.running,
    required this.shieldActive,
    required this.invulnerable,
    required this.weaponTier,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF080D24), Color(0xFF050816), Color(0xFF10051E)],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final grid = Paint()..color = const Color(0x1400EFFF)..strokeWidth = .7;
    for (double y = 0; y < size.height; y += 44) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (double x = 0; x < size.width; x += 44) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    final rng = math.Random(42);
    for (int i = 0; i < 100; i++) {
      final x = rng.nextDouble() * size.width;
      final y = (rng.nextDouble() * size.height + frame * (.4 + (i % 4) * .17)) % size.height;
      canvas.drawCircle(Offset(x, y), i % 10 == 0 ? 1.6 : .8,
        Paint()..color = Colors.white.withValues(alpha: .24 + (i % 4) * .12));
    }

    for (final b in bullets) {
      final p = Paint()
        ..color = (weaponTier >= 4
            ? const Color(0xFFFFB347)
            : const Color(0xFF00F5FF))
        ..strokeWidth = b.radius
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(b.position, b.position - b.velocity * 1.5, p);
      canvas.drawCircle(b.position, b.radius + 2,
        Paint()..color = p.color.withValues(alpha: .18));
    }

    for (final e in enemies) {
      final p = e.position;
      final color = switch (e.kind) {
        EnemyKind.scout => const Color(0xFFFF4D9D),
        EnemyKind.interceptor => const Color(0xFFB45CFF),
        EnemyKind.tank => const Color(0xFFFF654A),
        EnemyKind.phantom => const Color(0xFFFFD166),
      };
      canvas.drawCircle(p, e.radius + 8,
        Paint()..color = color.withValues(alpha: .12));
      final path = Path();
      switch (e.kind) {
        case EnemyKind.scout:
          path
            ..moveTo(p.dx, p.dy - e.radius)
            ..lineTo(p.dx + e.radius, p.dy + e.radius * .65)
            ..lineTo(p.dx, p.dy + e.radius * .25)
            ..lineTo(p.dx - e.radius, p.dy + e.radius * .65)
            ..close();
          break;
        case EnemyKind.interceptor:
          path
            ..moveTo(p.dx, p.dy - e.radius)
            ..lineTo(p.dx + e.radius, p.dy - 2)
            ..lineTo(p.dx + e.radius * .55, p.dy + e.radius)
            ..lineTo(p.dx, p.dy + e.radius * .45)
            ..lineTo(p.dx - e.radius * .55, p.dy + e.radius)
            ..lineTo(p.dx - e.radius, p.dy - 2)
            ..close();
          break;
        case EnemyKind.tank:
          path
            ..moveTo(p.dx - e.radius * .7, p.dy - e.radius * .75)
            ..lineTo(p.dx + e.radius * .7, p.dy - e.radius * .75)
            ..lineTo(p.dx + e.radius, p.dy)
            ..lineTo(p.dx + e.radius * .7, p.dy + e.radius * .75)
            ..lineTo(p.dx - e.radius * .7, p.dy + e.radius * .75)
            ..lineTo(p.dx - e.radius, p.dy)
            ..close();
          break;
        case EnemyKind.phantom:
          path
            ..moveTo(p.dx, p.dy - e.radius)
            ..lineTo(p.dx + e.radius * .8, p.dy - e.radius * .2)
            ..lineTo(p.dx + e.radius * .55, p.dy + e.radius * .75)
            ..lineTo(p.dx, p.dy + e.radius * .4)
            ..lineTo(p.dx - e.radius * .55, p.dy + e.radius * .75)
            ..lineTo(p.dx - e.radius * .8, p.dy - e.radius * .2)
            ..close();
          break;
      }
      canvas.drawPath(path, Paint()..color = color);
      canvas.drawPath(path, Paint()
        ..style = PaintingStyle.stroke..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: .85));
      canvas.drawCircle(p, e.kind == EnemyKind.tank ? 5 : 3,
        Paint()..color = const Color(0xFF160D29));
      if (e.hp > 1) {
        final barWidth = e.radius * 1.5;
        final rect = Rect.fromLTWH(p.dx - barWidth / 2, p.dy - e.radius - 7, barWidth, 3);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          Paint()..color = Colors.white24);
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(rect.left, rect.top, barWidth * (e.hp / (e.kind == EnemyKind.tank ? 4 : 3)), 3),
          const Radius.circular(2)), Paint()..color = color);
      }
    }

    for (final pickup in pickups) {
      final p = pickup.position;
      final color = switch (pickup.kind) {
        PickupKind.twinLaser => const Color(0xFF00F5FF),
        PickupKind.spreadShot => const Color(0xFFFF2BD6),
        PickupKind.rapidFire => const Color(0xFFFFB347),
        PickupKind.shield => const Color(0xFF62FFB5),
      };
      canvas.drawCircle(p, 19, Paint()..color = color.withValues(alpha: .13));
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(pickup.spin);
      final diamond = Path()
        ..moveTo(0, -13)..lineTo(13, 0)..lineTo(0, 13)..lineTo(-13, 0)..close();
      canvas.drawPath(diamond, Paint()..color = color);
      canvas.drawPath(diamond, Paint()
        ..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.white);
      canvas.restore();
      final label = switch (pickup.kind) {
        PickupKind.twinLaser => 'II',
        PickupKind.spreadShot => 'S',
        PickupKind.rapidFire => 'R',
        PickupKind.shield => '+',
      };
      final tp = TextPainter(
        text: TextSpan(text: label, style: const TextStyle(
          color: Color(0xFF07101D), fontSize: 11, fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy - tp.height / 2));
    }

    for (final particle in particles) {
      canvas.drawCircle(particle.position, math.max(1.0, particle.life / 7),
        Paint()..color = particle.color.withValues(alpha: (particle.life / 36).clamp(0.0, 1.0)));
    }

    if (running && (!invulnerable || frame % 8 < 5)) {
      final p = Offset(player.dx * size.width, player.dy * size.height);
      final flamePath = Path()
        ..moveTo(p.dx - 8, p.dy + 13)
        ..lineTo(p.dx, p.dy + 31 + (frame % 4) * 2)
        ..lineTo(p.dx + 8, p.dy + 13)
        ..close();
      canvas.drawPath(flamePath, Paint()..color = const Color(0xFFFF8A36));
      canvas.drawPath(flamePath, Paint()..color = const Color(0xFFFFD166).withValues(alpha: .7)
        ..style = PaintingStyle.stroke..strokeWidth = 1.2);

      if (shieldActive) {
        canvas.drawCircle(p, 32, Paint()
          ..color = const Color(0xFF62FFB5).withValues(alpha: .10));
        canvas.drawCircle(p, 29, Paint()
          ..style = PaintingStyle.stroke..strokeWidth = 2
          ..color = const Color(0xFF62FFB5).withValues(alpha: .8));
        canvas.drawArc(Rect.fromCircle(center: p, radius: 34),
          frame * .04, math.pi * 1.2, false,
          Paint()..style = PaintingStyle.stroke..strokeWidth = 2
            ..color = const Color(0xFFB5FFE0));
      }

      // Sharper, layered fighter silhouette with wing fins, cockpit, and engine glow.
      final wing = Path()
        ..moveTo(p.dx, p.dy - 27)
        ..lineTo(p.dx + 24, p.dy + 13)
        ..lineTo(p.dx + 10, p.dy + 9)
        ..lineTo(p.dx + 7, p.dy + 18)
        ..lineTo(p.dx, p.dy + 13)
        ..lineTo(p.dx - 7, p.dy + 18)
        ..lineTo(p.dx - 10, p.dy + 9)
        ..lineTo(p.dx - 24, p.dy + 13)
        ..close();
      canvas.drawCircle(p, 28, Paint()..color = const Color(0x2200F5FF));
      canvas.drawPath(wing, Paint()..shader = const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFF61F8FF), Color(0xFF1475CF)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ).createShader(Rect.fromCenter(center: p, width: 50, height: 50)));
      canvas.drawPath(wing, Paint()
        ..style = PaintingStyle.stroke..strokeWidth = 1.7
        ..color = const Color(0xFFD9FFFF));
      final centerHull = Path()
        ..moveTo(p.dx, p.dy - 28)
        ..lineTo(p.dx + 7, p.dy + 7)
        ..lineTo(p.dx, p.dy + 14)
        ..lineTo(p.dx - 7, p.dy + 7)
        ..close();
      canvas.drawPath(centerHull, Paint()..color = const Color(0xFF087CBA));
      canvas.drawOval(Rect.fromCenter(center: Offset(p.dx, p.dy - 7),
        width: 7, height: 13), Paint()..color = const Color(0xFFFFFFFF));
      canvas.drawCircle(Offset(p.dx, p.dy - 7), 2,
        Paint()..color = const Color(0xFF00F5FF));
      if (weaponTier >= 2) {
        for (final dx in [-10.0, 10.0]) {
          canvas.drawCircle(Offset(p.dx + dx, p.dy + 8), 3,
            Paint()..color = const Color(0xFF00F5FF));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => true;
}
