import 'package:flutter/material.dart';
import 'package:med_intel/services/mock_data.dart';
import 'package:med_intel/theme/app_theme.dart';

class HealthInsightsScreen extends StatelessWidget {
  const HealthInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final insights = MockDataService.mockHealthInsights;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Health Insights'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Text('Smart guidance for your medicines and lifestyle', style: AppTextStyles.bodyLarge),
          const SizedBox(height: 22),
          ...insights.map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _HealthTipCard(insight: insight),
              )),
          const SizedBox(height: 4),
          _buildFooterCard(),
        ],
      ),
    );
  }

  Widget _buildFooterCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Wellness snapshot', style: AppTextStyles.headlineSmall.copyWith(color: Colors.white)),
          const SizedBox(height: 12),
          Text('Track a healthy routine and stay informed with daily medication tips.',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _HealthTipCard extends StatelessWidget {
  final Map<String, dynamic> insight;
  const _HealthTipCard({required this.insight, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(10),
                child: const Icon(Icons.lightbulb_outline, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(insight['title'] as String, style: AppTextStyles.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(insight['content'] as String, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 14),
          Row(
            children: [
              Chip(label: Text(insight['category'] as String)),
              const SizedBox(width: 8),
              Text(insight['medicineRelated'] as String, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
