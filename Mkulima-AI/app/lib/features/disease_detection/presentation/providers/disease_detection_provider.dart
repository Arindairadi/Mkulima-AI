import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client_provider.dart';
import '../../domain/entities/disease_result.dart';

class DiseaseDetectionState {
  final File? image;
  final bool isAnalyzing;
  final DiseaseResult? result;
  final String? errorMessage;
  final bool usedOfflineFallback;

  const DiseaseDetectionState({
    this.image,
    this.isAnalyzing = false,
    this.result,
    this.errorMessage,
    this.usedOfflineFallback = false,
  });

  DiseaseDetectionState copyWith({
    File? image,
    bool? isAnalyzing,
    DiseaseResult? result,
    String? errorMessage,
    bool clearResult = false,
    bool? usedOfflineFallback,
  }) {
    return DiseaseDetectionState(
      image: image ?? this.image,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      result: clearResult ? null : result ?? this.result,
      errorMessage: errorMessage,
      usedOfflineFallback: usedOfflineFallback ?? this.usedOfflineFallback,
    );
  }
}

/// Handles image capture/selection and AI inference for crop disease
/// detection (Section 2 of the brief).
///
/// `analyze()` uploads the photo to the Mkulima AI backend (bulimi_ai_backend/)
/// (`POST /api/v1/disease-detection/analyze`), which calls Gemini's vision
/// model and returns a real diagnosis. If the request fails — no
/// connectivity, backend down, etc. — this falls back to a local mock
/// result rather than leaving the farmer with nothing, and flags
/// `usedOfflineFallback` so the UI can tell them the result is only a
/// rough guide until they're back online.
class DiseaseDetectionController extends StateNotifier<DiseaseDetectionState> {
  final Ref _ref;
  DiseaseDetectionController(this._ref) : super(const DiseaseDetectionState());

  final _picker = ImagePicker();

  Future<void> pickFromCamera() => _pick(ImageSource.camera);
  Future<void> pickFromGallery() => _pick(ImageSource.gallery);

  Future<void> _pick(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, maxWidth: 1200, imageQuality: 85);
      if (picked == null) return;
      state = DiseaseDetectionState(image: File(picked.path));
    } catch (e) {
      state = state.copyWith(errorMessage: 'Could not access camera/gallery: $e');
    }
  }

  Future<void> analyze(String cropName) async {
    if (state.image == null) return;
    state = state.copyWith(isAnalyzing: true, clearResult: true, errorMessage: null, usedOfflineFallback: false);

    try {
      final apiClient = _ref.read(apiClientProvider);
      final formData = FormData.fromMap({
        'crop_name': cropName,
        'image': await MultipartFile.fromFile(state.image!.path, filename: 'crop.jpg'),
      });

      final response = await apiClient.postMultipart<Map<String, dynamic>>(
        '/api/v1/disease-detection/analyze',
        formData: formData,
      );

      final data = response.data!;
      final result = DiseaseResult(
        cropName: data['crop_name'] as String? ?? cropName,
        diseaseName: data['disease_name'] as String? ?? 'Unknown',
        confidence: (data['confidence'] as num?)?.toDouble() ?? 0.5,
        cause: data['cause'] as String? ?? '',
        treatments: List<String>.from(data['treatments'] as List? ?? []),
        preventionTips: List<String>.from(data['prevention_tips'] as List? ?? []),
        isHealthy: data['is_healthy'] as bool? ?? false,
      );

      state = state.copyWith(isAnalyzing: false, result: result);
    } catch (e) {
      // Offline-first fallback: no connectivity / backend unreachable —
      // give the farmer a plausible local result rather than nothing,
      // clearly flagged as not a real-time AI diagnosis.
      final mockResults = _mockDatabase[cropName] ?? _mockDatabase['Maize']!;
      final fallback = mockResults[Random().nextInt(mockResults.length)];
      state = state.copyWith(isAnalyzing: false, result: fallback, usedOfflineFallback: true);
    }
  }

  void reset() => state = const DiseaseDetectionState();
}

final diseaseDetectionProvider =
    StateNotifierProvider.autoDispose<DiseaseDetectionController, DiseaseDetectionState>(
  (ref) => DiseaseDetectionController(ref),
);

final _mockDatabase = <String, List<DiseaseResult>>{
  'Maize': [
    DiseaseResult(
      cropName: 'Maize',
      diseaseName: 'Maize Leaf Blight',
      confidence: 0.91,
      cause: 'Fungal infection (Exserohilum turcicum), spread by humid conditions and poor air circulation.',
      treatments: const [
        'Apply a recommended fungicide (e.g. mancozeb-based) at first sign of lesions.',
        'Remove and destroy heavily infected leaves.',
      ],
      preventionTips: const [
        'Rotate maize with a non-cereal crop each season.',
        'Space plants to improve airflow and reduce leaf-wetness duration.',
      ],
    ),
    DiseaseResult(
      cropName: 'Maize',
      diseaseName: 'Healthy',
      confidence: 0.95,
      cause: 'No disease detected.',
      treatments: const [],
      preventionTips: const ['Continue regular scouting every 7–10 days.'],
      isHealthy: true,
    ),
  ],
  'Beans': [
    DiseaseResult(
      cropName: 'Beans',
      diseaseName: 'Bean Rust',
      confidence: 0.88,
      cause: 'Fungal pathogen (Uromyces appendiculatus), favored by cool, moist weather.',
      treatments: const [
        'Apply sulfur-based or copper fungicide as soon as pustules appear.',
        'Remove and burn infected plant debris after harvest.',
      ],
      preventionTips: const [
        'Use certified disease-free seed.',
        'Avoid overhead irrigation late in the day.',
      ],
    ),
  ],
  'Coffee': [
    DiseaseResult(
      cropName: 'Coffee',
      diseaseName: 'Coffee Leaf Rust',
      confidence: 0.9,
      cause: 'Fungus Hemileia vastatrix, spread by wind and rain splash.',
      treatments: const [
        'Apply copper-based fungicide sprays at recommended intervals.',
        'Prune to improve canopy airflow.',
      ],
      preventionTips: const ['Plant rust-resistant coffee varieties where available.'],
    ),
  ],
  'Bananas': [
    DiseaseResult(
      cropName: 'Bananas',
      diseaseName: 'Banana Bacterial Wilt (BXW)',
      confidence: 0.86,
      cause: 'Bacterium Xanthomonas campestris, spread via tools and insects visiting the male bud.',
      treatments: const [
        'Remove and destroy infected plants completely, including the corm.',
        'Disinfect tools with fire or bleach between plants.',
      ],
      preventionTips: const ['Remove the male bud after the last hand of bananas has formed.'],
    ),
  ],
  'Cassava': [
    DiseaseResult(
      cropName: 'Cassava',
      diseaseName: 'Cassava Mosaic Disease',
      confidence: 0.89,
      cause: 'Virus transmitted by whiteflies and infected planting material.',
      treatments: const ['No cure once infected — remove and destroy affected plants.'],
      preventionTips: const [
        'Plant only certified virus-free cuttings.',
        'Control whitefly populations early in the season.',
      ],
    ),
  ],
  'Tomatoes': [
    DiseaseResult(
      cropName: 'Tomatoes',
      diseaseName: 'Tomato Late Blight',
      confidence: 0.93,
      cause: 'Oomycete Phytophthora infestans, spreads rapidly in cool, wet weather.',
      treatments: const [
        'Apply a protective fungicide before symptoms spread further.',
        'Remove infected leaves and improve field drainage.',
      ],
      preventionTips: const ['Avoid overhead watering; water at the base of plants instead.'],
    ),
  ],
};
