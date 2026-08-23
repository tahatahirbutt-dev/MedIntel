import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:med_intel/l10n/app_localizations.dart';
import 'package:med_intel/theme/app_theme.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _rating = 4;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  static const _prefsKey = 'submitted_feedback';

  Future<void> _submitFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    final existing = raw != null ? (jsonDecode(raw) as List) : [];
    existing.add({
      'rating': _rating,
      'comment': _commentController.text.trim(),
      'date': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_prefsKey, jsonEncode(existing));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.feedbackThankYou),
        backgroundColor: AppColors.success,
      ),
    );
    setState(() {
      _rating = 4;
      _commentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.feedbackTitle),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Text(l10n.feedbackSubtitle, style: AppTextStyles.bodyLarge),
          const SizedBox(height: 22),
          _buildRatingCard(l10n),
          const SizedBox(height: 18),
          _buildCommentField(l10n),
          const SizedBox(height: 20),
          AppPrimaryButton(label: l10n.feedbackSubmit, onPressed: _submitFeedback),
        ],
      ),
    );
  }

  Widget _buildRatingCard(AppLocalizations l10n) {
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
          Text(l10n.feedbackRateExperience, style: AppTextStyles.headlineSmall),
          const SizedBox(height: 14),
          Row(
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: AppColors.warning,
                ),
                onPressed: () => setState(() => _rating = index + 1),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(l10n.feedbackSelectedStars(_rating), style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildCommentField(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _commentController,
        maxLines: 6,
        decoration: InputDecoration(
          hintText: l10n.feedbackCommentHint,
          border: InputBorder.none,
        ),
      ),
    );
  }
}
