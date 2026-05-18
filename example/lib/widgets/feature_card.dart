import 'package:flutter/material.dart';

class AppFeature {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const AppFeature(this.icon, this.title, this.subtitle,
      {this.color = const Color(0xFF00E5FF)});
}

class FeatureCard extends StatelessWidget {
  final AppFeature feature;
  const FeatureCard({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16161F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: feature.color.withAlpha(30),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  feature.color.withAlpha(40),
                  feature.color.withAlpha(15),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: feature.color.withAlpha(50), width: 1),
            ),
            child: Icon(feature.icon, color: feature.color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            feature.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            feature.subtitle,
            style: TextStyle(
                color: Colors.white.withAlpha(80), fontSize: 9, height: 1.2),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
