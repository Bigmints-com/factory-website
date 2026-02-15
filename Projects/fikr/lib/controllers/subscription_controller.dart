import 'package:get/get.dart';

import '../services/storage_service.dart';

enum SubscriptionTier { free, plus, pro }

/// Stub controller that always returns free tier.
/// IAP logic temporarily removed for initial app store submission.
/// Re-enable in-app purchases by restoring the original implementation.
class SubscriptionController extends GetxController {
  // ignore: unused_field
  final StorageService _storage = Get.find<StorageService>();

  final Rx<SubscriptionTier> currentTier = SubscriptionTier.free.obs;
  final RxBool isLoading = false.obs;
  final RxBool isAvailable = false.obs;

  // Entitlements – sync enabled for all users
  bool get canSync => true;
  bool get hasAdvancedAI => false;
  bool get needsOwnKeys => true;
  bool get isPro => false;

  // Vertex AI Access – disabled
  bool get hasManagedVertexAI => false;
  int get tokenLimit => 0;
}
