import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'enemy.dart';

class LevelManager extends Component with HasGameRef {
  static const double bossSpawnTime = 60.0; // 60 seconds until boss spawn
  static const double levelCompleteTime =
      90.0; // 90 seconds for level completion

  double _progress = 0;
  bool _bossSpawned = false;
  bool _levelComplete = false;
  late final TextComponent _progressText;
  late final ProgressBar _progressBar;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add progress text
    _progressText = TextComponent(
      text: 'Progress: 0%',
      position: Vector2(10, 40),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    );
    add(_progressText);

    // Add progress bar
    _progressBar = ProgressBar(
      position: Vector2(10, 70),
      size: Vector2(gameRef.size.x - 20, 20),
    );
    add(_progressBar);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_levelComplete) {
      _progress += dt / levelCompleteTime;
      _progress = _progress.clamp(0, 1);

      // Update progress text
      _progressText.text = 'Progress: ${(_progress * 100).round()}%';

      // Update progress bar
      _progressBar.progress = _progress;

      // Spawn boss at 66% progress
      if (_progress >= 0.66 && !_bossSpawned) {
        _bossSpawned = true;
        final spawner = gameRef.children.whereType<EnemySpawner>().firstOrNull;
        if (spawner != null) {
          spawner.spawnBoss();
        }
      }

      // Level complete at 100% progress
      if (_progress >= 1 && !_levelComplete) {
        _levelComplete = true;
        FlameAudio.play('audio/level_up.mp3');
        // TODO: Show level complete screen
      }
    }
  }

  bool get isLevelComplete => _levelComplete;
}

class ProgressBar extends PositionComponent {
  double _progress = 0;

  ProgressBar({
    required Vector2 position,
    required Vector2 size,
  }) : super(
          position: position,
          size: size,
        );

  set progress(double value) {
    _progress = value.clamp(0, 1);
  }

  @override
  void render(Canvas canvas) {
    // Draw background
    final bgPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      bgPaint,
    );

    // Draw progress
    final progressPaint = Paint()
      ..color = Colors.deepPurple
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x * _progress, size.y),
      progressPaint,
    );

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      borderPaint,
    );
  }
}
