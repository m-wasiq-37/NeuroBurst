import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'NeuroBurst',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontFamily: 'Cyberpunk',
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Final Year Project',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 32),
              Text(
                'Developers',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'Cyberpunk',
                ),
              ),
              SizedBox(height: 16),
              _DeveloperCard(
                name: 'Muhammad Wasiq',
                id: '03-134222-082',
              ),
              SizedBox(height: 16),
              _DeveloperCard(
                name: 'Muhammad Huzaifa',
                id: '03-134222-065',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeveloperCard extends StatelessWidget {
  final String name;
  final String id;

  const _DeveloperCard({
    required this.name,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontFamily: 'Cyberpunk',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            id,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
