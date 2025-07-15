import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'game.dart';

class Bit extends PositionComponent with HasGameRef {
  static const double bitSize = 20;
  static const double magnetRadius = 100;
  static const double moveSpeed = 200;

  final math.Random random = math.Random();
  Vector2? targetPosition;
  bool _isCollected = false;
  double _lifetime = 10.0; // Bits disappear after 10 seconds if not collected

  Bit({required Vector2 position})
      : super(position: position, size: Vector2(10, 10));

  @override
  void render(Canvas canvas) {
    if (!_isCollected) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = Colors.red,
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isCollected) {
      // Move towards target (player)
      if (targetPosition != null) {
        final direction = targetPosition! - position;
        if (direction.length > 5) {
          position += direction.normalized() * moveSpeed * dt;
        } else {
          // Collected
          FlameAudio.play('audio/bit_collect.mp3');
          removeFromParent();
        }
      }
    } else {
      // Check if player is within magnet radius
      final player = gameRef.children.whereType<Player>().firstOrNull;
      if (player != null) {
        final distance = (player.position - position).length;
        if (distance <= magnetRadius * player.bitMagnet) {
          _isCollected = true;
          targetPosition = player.position;
        }
      }
    }

    _lifetime -= dt;
    if (_lifetime <= 0) {
      removeFromParent();
    }
  }

  void collect() {
    _isCollected = true;
  }

  bool get isCollected => _isCollected;
}

class BitSpawner {
  static void spawnBits(Vector2 position, int count, HasGameRef gameRef) {
    final random = math.Random();
    for (var i = 0; i < count; i++) {
      // Spawn bits in a small radius around the position
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = random.nextDouble() * 20;
      final offset = Vector2(
        math.cos(angle) * distance,
        math.sin(angle) * distance,
      );

      gameRef.add(Bit(
        position: position + offset,
      ));
    }
  }
}
