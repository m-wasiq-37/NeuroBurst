import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'enemy.dart';
import 'bit.dart';
import 'level_manager.dart';

class NeuroBurstGame extends FlameGame
    with TapDetector, KeyboardEvents, HasCollisionDetection {
  static const String _bitsKey = 'player_bits';

  late final Player player;
  late final TextComponent fpsText;
  late final TextComponent healthText;
  late final TextComponent attackText;
  late final TextComponent bitsText;
  late final EnemySpawner enemySpawner;
  late final LevelManager levelManager;
  int bits = 0;
  bool isGameOver = false;
  bool _audioInitialized = false;

  Future<void> _initializeAudio() async {
    if (_audioInitialized) return;

    try {
      // Initialize audio cache without prefix since assets are already in audio/
      FlameAudio.audioCache = AudioCache();

      // Load all audio files
      await FlameAudio.audioCache.loadAll([
        'audio/shoot.mp3',
        'audio/hit.mp3',
        'audio/bit_collect.mp3',
        'audio/enemy_death.mp3',
        'audio/boss_spawn.mp3',
        'audio/level_up.mp3',
        'audio/game_over.mp3',
        'audio/background.mp3',
      ]);

      _audioInitialized = true;
    } catch (e) {
      print('Error initializing audio: $e');
      // Continue without audio
    }
  }

  void _playSound(String sound) {
    if (!_audioInitialized) return;
    try {
      FlameAudio.play('audio/$sound');
    } catch (e) {
      print('Error playing sound $sound: $e');
    }
  }

  void _playBackgroundMusic() {
    if (!_audioInitialized) return;
    try {
      FlameAudio.bgm.play('audio/background.mp3');
    } catch (e) {
      print('Error playing background music: $e');
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize audio first
    await _initializeAudio();

    // Load saved bits
    final prefs = await SharedPreferences.getInstance();
    bits = prefs.getInt(_bitsKey) ?? 0;

    // Start background music on platform thread
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playBackgroundMusic();
    });

    // Load skill levels
    final attackLevel = prefs.getInt('skill_Attack Power') ?? 0;
    final fireRateLevel = prefs.getInt('skill_Fire Rate') ?? 0;
    final critLevel = prefs.getInt('skill_Critical Chance') ?? 0;
    final healthLevel = prefs.getInt('skill_Health') ?? 0;
    final regenLevel = prefs.getInt('skill_Regeneration') ?? 0;

    print('Loading skill levels:'); // Debug log
    print('Attack Power: $attackLevel');
    print('Fire Rate: $fireRateLevel');
    print('Critical Chance: $critLevel');
    print('Health: $healthLevel');
    print('Regeneration: $regenLevel');

    // Calculate skill values
    final attackMultiplier =
        1.0 + (attackLevel * 0.2); // 20% increase per level
    final fireRateMultiplier =
        1.0 + (fireRateLevel * 0.1); // 10% increase per level
    final critChance = 0.05 + (critLevel * 0.02); // 2% increase per level
    final healthMultiplier =
        1.0 + (healthLevel * 0.2); // 20% increase per level
    final regenMultiplier = 1.0 + (regenLevel * 0.1); // 10% increase per level

    print('Applied multipliers:'); // Debug log
    print('Attack: $attackMultiplier');
    print('Fire Rate: $fireRateMultiplier');
    print('Critical: $critChance');
    print('Health: $healthMultiplier');
    print('Regeneration: $regenMultiplier');

    // Initialize components with skill upgrades
    player = Player(
      onShoot: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _playSound('shoot.mp3');
        });
      },
      onHit: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _playSound('hit.mp3');
        });
      },
      attackPower: 10 * attackMultiplier,
      fireRate: 1.0 * fireRateMultiplier,
      criticalChance: critChance,
      health: 500 * healthMultiplier,
      regeneration: 0.1 * regenMultiplier,
    );

    print('Player stats after skill application:'); // Debug log
    print('Attack Power: ${player.attackPower}');
    print('Fire Rate: ${player.fireRate}');
    print('Critical Chance: ${player.criticalChance}');
    print('Health: ${player.health}');
    print('Regeneration: ${player.regeneration}');

    add(player);

    enemySpawner = EnemySpawner();
    add(enemySpawner);

    levelManager = LevelManager();
    add(levelManager);

    // Add UI components with white text
    fpsText = TextComponent(
      text: 'FPS: 0',
      position: Vector2(10, 10),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(fpsText);

    healthText = TextComponent(
      text: 'HP: ${player.health}',
      position: Vector2(10, 100),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(healthText);

    attackText = TextComponent(
      text: 'Attack: ${player.attackPower}',
      position: Vector2(10, 130),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(attackText);

    // Add bits text component
    bitsText = TextComponent(
      text: 'Bits: $bits',
      position: Vector2(10, 160),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(bitsText);

    // Show FPS overlay
    overlays.add('fps');
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update FPS counter with safety check
    final fps = dt > 0 ? (1 / dt).round() : 0;
    fpsText.text = 'FPS: $fps';

    // Update UI
    healthText.text = 'HP: ${player.health.round()}';
    attackText.text = 'Attack: ${player.attackPower.round()}';
    bitsText.text = 'Bits: $bits';

    // Check collisions
    final enemies = children.whereType<Enemy>();
    for (final enemy in enemies) {
      if (player.overlapsWith(enemy)) {
        // Only take damage if not already game over
        if (!isGameOver) {
          player.takeDamage(10); // Reduced from 50 to 10
          enemy.takeDamage(player.attackPower);

          // Check if player died from this hit
          if (player.health <= 0) {
            // Stop background music
            FlameAudio.bgm.stop();
            // Play game over sound
            FlameAudio.play('audio/game_over.mp3');
            // Save bits before showing game over
            saveBits();
            overlays.add('gameOver');
            pauseEngine();
            return;
          }
        }
      }
    }

    // Level complete check
    if (levelManager.isLevelComplete) {
      // Save bits before showing level complete
      saveBits();
      // TODO: Show level complete screen
    }
  }

  @override
  void onTapDown(TapDownInfo info) {
    super.onTapDown(info);
    if (!isGameOver) {
      player.moveTo(info.eventPosition.global);
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        // Handle right arrow key press
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  Future<void> saveBits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_bitsKey, bits);
      print('Bits saved: $bits');
    } catch (e) {
      print('Error saving bits: $e');
    }
  }

  void addBits(int amount) {
    bits += amount;
    saveBits(); // Save bits immediately when collected
    print('Bits added: $amount, Total: $bits'); // Debug log
  }

  @override
  void onRemove() {
    // Stop background music when leaving the game
    FlameAudio.bgm.stop();
    super.onRemove();
  }
}

class Player extends PositionComponent with HasGameRef {
  double health;
  double attackPower;
  double fireRate; // Shots per second
  double criticalChance; // Base critical chance
  double regeneration; // HP per second
  double bitMagnet = 1.0; // Bit collection radius multiplier
  double splashDamage = 0.0; // Additional splash damage
  double shield = 0.0; // Temporary shield HP
  late final double maxHealth; // Store max health for regeneration

  final VoidCallback onShoot;
  final VoidCallback onHit;

  double _lastShot = 0;
  final math.Random _random = math.Random();

  Player({
    required this.onShoot,
    required this.onHit,
    required this.attackPower,
    required this.fireRate,
    required this.criticalChance,
    required this.health,
    required this.regeneration,
  }) : super(size: Vector2(120, 120)) {
    position = Vector2(400, 300); // Center of screen
    maxHealth = health; // Initialize max health
  }

  @override
  void render(Canvas canvas) {
    // Draw crosshair
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Draw outer rectangle
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      paint,
    );

    // Draw inner crosshair lines
    canvas.drawLine(
      Offset(size.x / 2, 0),
      Offset(size.x / 2, size.y),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.y / 2),
      Offset(size.x, size.y / 2),
      paint,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Auto-fire logic
    final currentTime = gameRef.currentTime();
    if (currentTime - _lastShot >= 1 / fireRate) {
      shoot();
      _lastShot = currentTime;
    }

    // Regeneration
    health = (health + regeneration * dt).clamp(0, maxHealth);

    // Bit collection
    final bits = gameRef.children.whereType<Bit>();
    for (final bit in bits) {
      final distance = (bit.position - position).length;
      if (distance <= 50 * bitMagnet) {
        // Collection radius * magnet multiplier
        bit.collect();
        (gameRef as NeuroBurstGame).addBits(1);
      }
    }
  }

  void moveTo(Vector2 target) {
    position = target - size / 2;
  }

  void shoot() {
    onShoot();

    // Check for critical hit
    final isCritical = _random.nextDouble() < criticalChance;
    final damage = (attackPower * (isCritical ? 2 : 1))
        .clamp(0, double.infinity)
        .toDouble();

    // Find enemies in range
    final enemies = gameRef.children.whereType<Enemy>();
    for (final enemy in enemies) {
      if (overlapsWith(enemy)) {
        enemy.takeDamage(damage);

        // Apply splash damage to nearby enemies
        if (splashDamage > 0) {
          for (final other in enemies) {
            if (other != enemy) {
              final distance = (other.position - enemy.position).length;
              if (distance <= 50) {
                // Splash radius
                final splashAmount = (damage * splashDamage)
                    .clamp(0, double.infinity)
                    .toDouble();
                other.takeDamage(splashAmount);
              }
            }
          }
        }
      }
    }
  }

  void takeDamage(double amount) {
    if (shield > 0) {
      shield = (shield - amount).clamp(0, double.infinity);
    } else {
      health = (health - amount).clamp(0, maxHealth);
      onHit();
    }
  }

  bool overlapsWith(PositionComponent other) {
    return Rect.fromLTWH(position.x, position.y, size.x, size.y).overlaps(
        Rect.fromLTWH(
            other.position.x, other.position.y, other.size.x, other.size.y));
  }
}
