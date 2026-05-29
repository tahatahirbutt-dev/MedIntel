import 'package:flutter/material.dart';
import 'package:med_intel/screens/upload_screen.dart';
import 'package:med_intel/screens/schedule_screen.dart';
import 'package:med_intel/screens/health_insights_screen.dart';
import 'package:med_intel/screens/feedback_screen.dart';
import 'package:med_intel/services/mock_data.dart';
import 'package:med_intel/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _buildHeader(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _buildPillReminderWidget(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _buildSummaryCard(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _buildActionGrid(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: const _InsightSection(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.home_filled, size: 26, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Welcome back!',
                  style: AppTextStyles.displaySmall.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Track your medicines, insights and appointments in one place.',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPillReminderWidget(BuildContext context) {
    final nextPills = [
      {'medicine': 'Panadol', 'dose': '500mg', 'time': '1:00 PM', 'color': AppColors.primary},
      {'medicine': 'Metformin', 'dose': '500mg', 'time': '8:00 PM', 'color': AppColors.secondary},
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.95), AppColors.secondary.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_active, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Upcoming Pills', style: AppTextStyles.titleMedium.copyWith(color: Colors.white)),
                    Text('Don\'t miss your dose', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '2 next',
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...nextPills.map((pill) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.medication, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pill['medicine'] as String,
                            style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
                          ),
                          Text(
                            '${pill['dose']} • ${pill['time']}',
                            style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${pill['medicine']} marked as taken!'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Take',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScheduleScreen()),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Text(
                'View all schedule',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today’s schedule', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildBadge('Next dose', '1:00 PM', AppColors.primary),
              const SizedBox(width: 10),
              _buildBadge('Missed', '1', AppColors.danger),
            ],
          ),
          const SizedBox(height: 18),
          Text('• Panadol 500mg • 9am, 1pm, 6pm', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
          Text('• Metformin 500mg • 8am, 8pm', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: 0.72,
            color: AppColors.primary,
            backgroundColor: AppColors.primaryLight,
            minHeight: 8,
          ),
          const SizedBox(height: 10),
          Text('Adherence this week: 72%', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildBadge(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.bodySmall.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSmallCard(
                icon: Icons.document_scanner_outlined,
                title: 'Scan prescription',
                subtitle: 'Upload & analyze',
                color: AppColors.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UploadScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSmallCard(
                icon: Icons.schedule_outlined,
                title: 'Medicine schedule',
                subtitle: 'View doses & reminders',
                color: AppColors.secondary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScheduleScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSmallCard(
                icon: Icons.health_and_safety_outlined,
                title: 'Health tips',
                subtitle: 'AI-powered insights',
                color: AppColors.success,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HealthInsightsScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSmallCard(
                icon: Icons.local_pharmacy_outlined,
                title: 'Find pharmacy',
                subtitle: 'Browse nearby stores',
                color: AppColors.info,
                onTap: () => Navigator.pushNamed(context, '/pharmacy'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSmallCard(
                icon: Icons.rate_review_outlined,
                title: 'Feedback',
                subtitle: 'Share your experience',
                color: AppColors.warning,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSmallCard(
                icon: Icons.medical_services_outlined,
                title: 'Medical profile',
                subtitle: 'Your health records',
                color: AppColors.secondary,
                onTap: () => Navigator.pushNamed(context, '/medical-profile'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.titleMedium),
            const SizedBox(height: 6),
            Text(subtitle, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _InsightSection extends StatelessWidget {
  const _InsightSection();

  @override
  Widget build(BuildContext context) {
    final insights = MockDataService.mockHealthInsights.take(2).toList();
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Latest health insight', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 14),
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: insights.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _InsightCard(insight: insights[index]),
              );
            },
          ),
          _buildViewAll(context),
        ],
      ),
    );
  }

  Widget _buildViewAll(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HealthInsightsScreen()),
        ),
        child: const Text('View all insights'),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final Map<String, dynamic> insight;
  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(insight['title'] as String, style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary)),
          const SizedBox(height: 8),
          Text(insight['content'] as String, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
