import 'package:flutter/material.dart';
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

  void _submitFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Thank you for your feedback!'),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Feedback & Ratings'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Text('Help us improve your pharmacy experience', style: AppTextStyles.bodyLarge),
          const SizedBox(height: 22),
          _buildRatingCard(),
          const SizedBox(height: 18),
          _buildCommentField(),
          const SizedBox(height: 20),
          AppPrimaryButton(label: 'Submit feedback', onPressed: _submitFeedback),
        ],
      ),
    );
  }

  Widget _buildRatingCard() {
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
          Text('Rate your experience', style: AppTextStyles.headlineSmall),
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
          Text('Selected: $_rating stars', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildCommentField() {
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
        decoration: const InputDecoration(
          hintText: 'Leave your comments here',
          border: InputBorder.none,
        ),
      ),
    );
  }
}
