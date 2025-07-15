import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

class Skill {
  final String name;
  final String description;
  final int maxLevel;
  final List<int> costs;
  final List<double> values;
  int currentLevel;

  Skill({
    required this.name,
    required this.description,
    required this.maxLevel,
    required this.costs,
    required this.values,
    this.currentLevel = 0,
  });
}

class SkillTree {
  final List<Skill> skills = [
    Skill(
      name: 'Attack Power',
      description: 'Increases damage dealt to enemies',
      maxLevel: 10,
      costs: [100, 200, 400, 800, 1600, 3200, 6400, 12800, 25600, 51200],
      values: [1.2, 1.4, 1.6, 1.8, 2.0, 2.2, 2.4, 2.6, 2.8, 3.0],
    ),
    Skill(
      name: 'Fire Rate',
      description: 'Increases shooting speed',
      maxLevel: 10,
      costs: [150, 300, 600, 1200, 2400, 4800, 9600, 19200, 38400, 76800],
      values: [1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2.0, 2.1],
    ),
    Skill(
      name: 'Critical Chance',
      description: 'Increases chance of critical hits',
      maxLevel: 10,
      costs: [200, 400, 800, 1600, 3200, 6400, 12800, 25600, 51200, 102400],
      values: [0.1, 0.12, 0.14, 0.16, 0.18, 0.20, 0.22, 0.24, 0.26, 0.28],
    ),
    Skill(
      name: 'Health',
      description: 'Increases maximum health',
      maxLevel: 10,
      costs: [100, 200, 400, 800, 1600, 3200, 6400, 12800, 25600, 51200],
      values: [1.2, 1.4, 1.6, 1.8, 2.0, 2.2, 2.4, 2.6, 2.8, 3.0],
    ),
    Skill(
      name: 'Regeneration',
      description: 'Increases health regeneration rate',
      maxLevel: 10,
      costs: [150, 300, 600, 1200, 2400, 4800, 9600, 19200, 38400, 76800],
      values: [1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2.0, 2.1],
    ),
  ];

  Future<void> loadSkillLevels() async {
    final prefs = await SharedPreferences.getInstance();
    for (final skill in skills) {
      final savedLevel = prefs.getInt('skill_${skill.name}') ?? 0;
      skill.currentLevel = savedLevel;
      print('Loaded ${skill.name} level: $savedLevel'); // Debug log
    }
  }

  Future<void> saveSkillLevels() async {
    final prefs = await SharedPreferences.getInstance();
    for (final skill in skills) {
      await prefs.setInt('skill_${skill.name}', skill.currentLevel);
      print('Saved ${skill.name} level: ${skill.currentLevel}'); // Debug log
    }
  }

  bool canUpgrade(Skill skill, int bits) {
    return skill.currentLevel < skill.maxLevel &&
        bits >= skill.costs[skill.currentLevel];
  }

  Future<void> upgradeSkill(Skill skill, int bits) async {
    if (canUpgrade(skill, bits)) {
      skill.currentLevel++;
      await saveSkillLevels();
      print('Upgraded ${skill.name} to level ${skill.currentLevel}'); // Debug log
    }
  }
}

class SkillTreeScreen extends StatefulWidget {
  final int bits;
  final Function(Skill) onUpgrade;

  const SkillTreeScreen({
    super.key,
    required this.bits,
    required this.onUpgrade,
  });

  @override
  State<SkillTreeScreen> createState() => _SkillTreeScreenState();
}

class _SkillTreeScreenState extends State<SkillTreeScreen> {
  late final SkillTree _skillTree;
  late int _currentBits;

  @override
  void initState() {
    super.initState();
    _skillTree = SkillTree();
    _currentBits = widget.bits;
    _loadSkillLevels();
  }

  Future<void> _loadSkillLevels() async {
    await _skillTree.loadSkillLevels();
    // Reload bits from SharedPreferences to ensure we have the latest value
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentBits = prefs.getInt('player_bits') ?? widget.bits;
    });
  }

  Future<void> _upgradeSkill(Skill skill) async {
    if (_skillTree.canUpgrade(skill, _currentBits)) {
      final cost = skill.costs[skill.currentLevel];
      
      // Save bits first
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('player_bits', _currentBits - cost);
      
      // Then upgrade the skill
      await _skillTree.upgradeSkill(skill, _currentBits);
      
      // Update UI
      setState(() {
        _currentBits -= cost;
      });

      // Notify parent
      widget.onUpgrade(skill);
      
      print('Skill upgrade complete:'); // Debug log
      print('Skill: ${skill.name}');
      print('New Level: ${skill.currentLevel}');
      print('Remaining Bits: $_currentBits');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Skill Tree',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.deepPurple,
                blurRadius: 5,
              ),
            ],
          ),
        ),
        backgroundColor: Colors.deepPurple.shade900,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade900,
              Colors.black,
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.3),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.deepPurple.withOpacity(0.5),
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: Colors.amber,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Bits:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.deepPurple,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _currentBits.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.deepPurple,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: _skillTree.skills.map((skill) {
                      final canUpgrade = _skillTree.canUpgrade(skill, _currentBits);
                      final cost = skill.currentLevel < skill.maxLevel
                          ? skill.costs[skill.currentLevel]
                          : 0;

                      return Card(
                        color: Colors.deepPurple.withOpacity(0.2),
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(
                            color: Colors.deepPurple.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    skill.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.deepPurple,
                                          blurRadius: 5,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Level ${skill.currentLevel}/${skill.maxLevel}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                skill.description,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (skill.currentLevel < skill.maxLevel) ...[
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.trending_up,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Next level: ${skill.values[skill.currentLevel]}x',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: canUpgrade ? () => _upgradeSkill(skill) : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: canUpgrade
                                        ? Colors.deepPurple
                                        : Colors.grey.withOpacity(0.3),
                                    disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.monetization_on,
                                        color: Colors.amber,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Upgrade (${cost} bits)',
                                        style: TextStyle(
                                          color: canUpgrade
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.5),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.3),
                border: Border(
                  top: BorderSide(
                    color: Colors.deepPurple.withOpacity(0.5),
                    width: 2,
                  ),
                ),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const GameScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'START GAME',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.deepPurple,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
