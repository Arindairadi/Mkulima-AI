import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/shared_widgets.dart';
import '../../domain/entities/disease_result.dart';
import '../providers/disease_detection_provider.dart';

class DiseaseDetectionScreen extends ConsumerStatefulWidget {
  const DiseaseDetectionScreen({super.key});

  @override
  ConsumerState<DiseaseDetectionScreen> createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends ConsumerState<DiseaseDetectionScreen> {
  String _selectedCrop = AppConstants.supportedCrops.first;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diseaseDetectionProvider);
    final controller = ref.read(diseaseDetectionProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Disease Detection'),
        actions: [
          if (state.image != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: controller.reset,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Choose your crop', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppConstants.spaceSm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.supportedCrops.map((crop) {
                final selected = crop == _selectedCrop;
                return ChoiceChip(
                  label: Text(crop),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedCrop = crop),
                );
              }).toList(),
            ),
            const SizedBox(height: AppConstants.spaceLg),
            Text('2. Take or upload a photo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppConstants.spaceSm),
            _ImagePreview(imageFile: state.image),
            const SizedBox(height: AppConstants.spaceMd),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.pickFromCamera,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: AppConstants.spaceMd),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.pickFromGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spaceLg),
            if (state.image != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.isAnalyzing ? null : () => controller.analyze(_selectedCrop),
                  child: state.isAnalyzing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Analyze photo'),
                ),
              ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: AppConstants.spaceMd),
              AppAlertBanner(message: state.errorMessage!, color: AppColors.danger, icon: Icons.error_outline),
            ],
            if (state.result != null) ...[
              const SizedBox(height: AppConstants.spaceLg),
              if (state.usedOfflineFallback)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppConstants.spaceMd),
                  child: AppAlertBanner(
                    message: 'Could not reach the AI service — showing an offline estimate. '
                        'Connect to the internet and try again for a real diagnosis.',
                    color: AppColors.warning,
                    icon: Icons.cloud_off_outlined,
                  ),
                ),
              _DiseaseResultCard(result: state.result!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final dynamic imageFile;
  const _ImagePreview({required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceDim,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageFile != null
          ? Image.file(imageFile, fit: BoxFit.cover)
          : const Center(
              child: Icon(Icons.image_outlined, size: 48, color: AppColors.textSecondary),
            ),
    );
  }
}

class _DiseaseResultCard extends StatelessWidget {
  final DiseaseResult result;
  const _DiseaseResultCard({required this.result});

  Color get _confidenceColor {
    if (result.isHealthy) return AppColors.diseaseLowConfidence;
    if (result.confidence >= 0.85) return AppColors.diseaseHighConfidence;
    if (result.confidence >= 0.6) return AppColors.diseaseMedConfidence;
    return AppColors.diseaseLowConfidence;
  }

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: result.diseaseName,
      icon: result.isHealthy ? Icons.check_circle_outline : Icons.bug_report_outlined,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _confidenceColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${(result.confidence * 100).round()}%',
          style: TextStyle(color: _confidenceColor, fontWeight: FontWeight.w600),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cause', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(result.cause, style: Theme.of(context).textTheme.bodyMedium),
          if (result.treatments.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spaceMd),
            Text('Treatment', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            ...result.treatments.map((t) => _BulletLine(text: t)),
          ],
          if (result.preventionTips.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spaceMd),
            Text('Prevention', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            ...result.preventionTips.map((t) => _BulletLine(text: t)),
          ],
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  final String text;
  const _BulletLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
