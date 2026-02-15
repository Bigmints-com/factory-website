import 'package:get/get.dart';

class NavigationController extends GetxController {
  final RxInt index = 0.obs;

  void setIndex(int value) => index.value = value;
}
