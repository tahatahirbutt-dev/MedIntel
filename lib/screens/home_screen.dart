import 'package:flutter/material.dart';
import 'package:med_intel/screens/upload_screen.dart';
import 'package:med_intel/screens/schedule_screen.dart';
import 'package:med_intel/screens/health_insights_screen.dart';
import 'package:med_intel/screens/feedback_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:med_intel/services/mock_data.dart';
import 'package:med_intel/services/schedule_service.dart';
import 'package:med_intel/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScheduleService _service = ScheduleService.instance;
  final Set<String> _optimisticTaken = {};
  final Set<String> _removedIds = {};

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
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data ?? FirebaseAuth.instance.currentUser;
        final userName = _formatUserName(user);
        final welcomeText = userName.isEmpty
            ? 'Welcome back!'
            : 'Welcome back, $userName!';

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.headerGradientStart, AppColors.headerGradientEnd],
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
                      welcomeText,
                      style: AppTextStyles.displaySmall.copyWith(
                        color: Colors.white,
                      ),
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
      },
    );
  }

  String _formatUserName(User? user) {
    if (user == null) return '';
    final rawName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : user.email?.split('@').first ?? '';
    if (rawName.isEmpty) return '';
    final firstName = rawName.split(' ').first;
    return firstName.toUpperCase();
  }

  Widget _buildPillReminderWidget(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.getUpcomingDosesStream(
        limit: 10,
      ), // fetch more so we can show up to 5 after filtering
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.95),
                  AppColors.secondary.withOpacity(0.85),
                ],
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
            child: Text(
              'Error loading upcoming pills: ${snapshot.error}',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
            ),
          );
        }

        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final upcoming = snapshot.data ?? [];

        // Remove any ids we've already removed optimistically and compute display list
        final upcomingFiltered = upcoming
            .where((p) => !_removedIds.contains(p['id'] as String))
            .toList();
        final displayList = upcomingFiltered.take(5).toList();

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.95),
                AppColors.secondary.withOpacity(0.85),
              ],
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
                    child: const Icon(
                      Icons.notifications_active,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upcoming Pills',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Don\'t miss your dose',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isLoading ? '…' : '${displayList.length} next',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              else if (upcoming.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    'No upcoming pills',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                )
              else
                ...displayList.map((pill) {
                  final id = pill['id'] as String? ?? '';
                  final medicine =
                      pill['medicineName'] as String? ?? 'Medicine';
                  final dosage = pill['dosage'] as String? ?? '';
                  final time = pill['time'] as String? ?? '';
                  final isOptimistic = _optimisticTaken.contains(id);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 360),
                      opacity: isOptimistic ? 0.6 : 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isOptimistic
                              ? Colors.white.withOpacity(0.1)
                              : Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
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
                              child: Icon(
                                isOptimistic
                                    ? Icons.check_circle
                                    : Icons.medication,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    medicine,
                                    style: AppTextStyles.titleMedium.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '$dosage • $time',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: isOptimistic
                                  ? null
                                  : () async {
                                      setState(() {
                                        _optimisticTaken.add(id);
                                      });

                                      // quick visual delay before removing the item from view
                                      Future.delayed(
                                        const Duration(milliseconds: 600),
                                        () {
                                          setState(() {
                                            _removedIds.add(id);
                                          });
                                        },
                                      );

                                      try {
                                        await _service.markDoseAsTaken(id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '$medicine marked as taken!',
                                              ),
                                              backgroundColor:
                                                  AppColors.success,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              duration: const Duration(
                                                seconds: 2,
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        // rollback optimistic state on error
                                        setState(() {
                                          _optimisticTaken.remove(id);
                                          _removedIds.remove(id);
                                        });
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Error: $e'),
                                            ),
                                          );
                                        }
                                      }
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isOptimistic ? 'Taken' : 'Take',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.getAllTodaysDosesStream(DateTime.now()),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final allDoses = snapshot.data ?? [];
        final upcomingDoses = allDoses
            .where((dose) => dose['isTaken'] == false)
            .toList();
        final nextDose = upcomingDoses.isNotEmpty
            ? upcomingDoses.first['time'] as String
            : '--:--';
        final completedCount = allDoses
            .where((dose) => dose['isTaken'] == true)
            .length;

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
                  _buildBadge('Next dose', nextDose, AppColors.primary),
                  const SizedBox(width: 10),
                  _buildBadge(
                    'Completed',
                    '$completedCount',
                    AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (allDoses.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    'No medicine doses scheduled for today.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: allDoses.map((dose) {
                    final medicine =
                        dose['medicineName'] as String? ?? 'Medicine';
                    final dosage = dose['dosage'] as String? ?? '';
                    final time = dose['time'] as String? ?? '';
                    final isTaken = dose['isTaken'] as bool? ?? false;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '• $medicine $dosage • $time${isTaken ? ' (taken)' : ''}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isTaken
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                          decoration: isTaken
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: allDoses.isEmpty
                    ? 0
                    : (completedCount / allDoses.length),
                color: AppColors.primary,
                backgroundColor: AppColors.primaryLight,
                minHeight: 8,
              ),
              const SizedBox(height: 10),
              Text(
                allDoses.isEmpty
                    ? 'No doses for today'
                    : 'Adherence today: ${(allDoses.isEmpty ? 0 : (completedCount / allDoses.length * 100)).round()}%',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        );
      },
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
              child: _FeatureCard(
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
              child: _FeatureCard(
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
              child: _FeatureCard(
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
              child: _FeatureCard(
                icon: Icons.local_pharmacy_outlined,
                title: 'Find and Register pharmacies',
                subtitle: 'Find nearby pharmacies and register your stores',
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
              child: _FeatureCard(
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
              child: _FeatureCard(
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

}

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          elevation: _pressed ? 1 : 4,
          shadowColor: widget.color.withOpacity(0.25),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 180,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 22),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.title,
                    style: AppTextStyles.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.subtitle,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
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
