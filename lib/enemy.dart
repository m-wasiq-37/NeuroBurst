import 'package:flame/components.dart';
import 'package:flame/geometry.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'bit.dart';

class Enemy extends PositionComponent with HasGameRef {
  static const double enemySize = 30;
  static const double speed = 100;

  final bool isBoss;
  double health;
  Vector2 velocity;
  final math.Random random = math.Random();

  Enemy({
    required this.isBoss,
    required Vector2 position,
  })  : health = isBoss ? 500 : 50,
        velocity = Vector2.zero(),
        super(
          position: position,
          size: Vector2.all(isBoss ? enemySize * 2 : enemySize),
        ) {
    _randomizeVelocity();
  }

  void _randomizeVelocity() {
    final angle = random.nextDouble() * 2 * math.pi;
    velocity = Vector2(
      math.cos(angle) * speed,
      math.sin(angle) * speed,
    );
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = isBoss ? Colors.blue : Colors.red
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      paint,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move enemy
    position += velocity * dt;

    // Bounce off screen edges
    final screenSize = gameRef.size;
    if (position.x <= 0 || position.x + size.x >= screenSize.x) {
      velocity.x *= -1;
    }
    if (position.y <= 0 || position.y + size.y >= screenSize.y) {
      velocity.y *= -1;
    }

    // Keep enemy within screen bounds
    position.x = position.x.clamp(0, screenSize.x - size.x);
    position.y = position.y.clamp(0, screenSize.y - size.y);

    // Randomly change direction occasionally
    if (random.nextDouble() < 0.01) {
      _randomizeVelocity();
    }
  }

  void takeDamage(double amount) {
    health -= amount;
    if (health <= 0) {
      if (!isBoss) {
        // Drop bits when enemy dies
        final numBits = random.nextInt(5) + 3; // Drop 3-7 bits
        for (var i = 0; i < numBits; i++) {
          final offset = Vector2(
            random.nextDouble() * 40 - 20, // Random offset between -20 and 20
            random.nextDouble() * 40 - 20,
          );
          gameRef.add(Bit(position: position + offset));
        }
        FlameAudio.play('audio/enemy_death.mp3');
      }
      removeFromParent();
    }
  }

  bool overlapsWith(PositionComponent other) {
    return Rect.fromLTWH(position.x, position.y, size.x, size.y).overlaps(
        Rect.fromLTWH(
            other.position.x, other.position.y, other.size.x, other.size.y));
  }
}

class EnemySpawner extends Component with HasGameRef {
  final math.Random random = math.Random();
  double _spawnTimer = 0;
  static const double spawnInterval =
      0.2; // Spawn every 0.2 seconds (5 times per second)

  @override
  void update(double dt) {
    super.update(dt);

    _spawnTimer += dt;
    if (_spawnTimer >= spawnInterval) {
      _spawnTimer = 0;
      _spawnEnemy();
    }
  }

  void _spawnEnemy() {
    final screenSize = gameRef.size;
    Vector2 spawnPosition;

    // Randomly choose spawn side (top, right, bottom, left)
    final side = random.nextInt(4);
    switch (side) {
      case 0: // Top
        spawnPosition = Vector2(
          random.nextDouble() * screenSize.x,
          -Enemy.enemySize,
        );
        break;
      case 1: // Right
        spawnPosition = Vector2(
          screenSize.x,
          random.nextDouble() * screenSize.y,
        );
        break;
      case 2: // Bottom
        spawnPosition = Vector2(
          random.nextDouble() * screenSize.x,
          screenSize.y,
        );
        break;
      case 3: // Left
        spawnPosition = Vector2(
          -Enemy.enemySize,
          random.nextDouble() * screenSize.y,
        );
        break;
      default:
        spawnPosition = Vector2.zero();
    }

    gameRef.add(Enemy(
      isBoss: false,
      position: spawnPosition,
    ));
  }

  void spawnBoss() {
    final screenSize = gameRef.size;
    final spawnPosition = Vector2(
      screenSize.x / 2 - Enemy.enemySize,
      screenSize.y / 2 - Enemy.enemySize,
    );

    FlameAudio.play('audio/boss_spawn.mp3');
    gameRef.add(Enemy(
      isBoss: true,
      position: spawnPosition,
    ));
  }
}
