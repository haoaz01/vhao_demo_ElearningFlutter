// lib/controllers/auth_flow_controller.dart
import 'package:get/get.dart';
import 'auth_controller.dart';
import 'user_activity_controller.dart';

class AuthFlowController extends GetxController {
  late final AuthController _auth;
  late final UserActivityController _activity;

  @override
  void onInit() {
    super.onInit();
    _auth = Get.find<AuthController>();
    _activity = Get.find<UserActivityController>();

    // Tự động quan sát trạng thái đăng nhập
    ever<bool>(_auth.isLoggedIn, (loggedIn) async {
      if (loggedIn == true) {
        await _handlePostLogin();
      } else {
        await _handlePostLogout();
      }
    });
  }

  /// Gọi thủ công sau khi signup thành công (nếu flow signup không toggle isLoggedIn ngay)
  Future<void> onSignupSuccess({int? userId}) async {
    // Nếu có userId truyền vào thì set vào AuthController trước (tuỳ flow của bạn)
    if (userId != null && userId > 0) {
      _auth.userId.value = userId;
      _auth.isLoggedIn.value = true; // nếu bạn muốn tự bật

      final flow = Get.find<AuthFlowController>();
      await flow.onLoginSuccess(); // hoặc onSignupSuccess();
    }
    await _handlePostLogin(); // reset + refresh
  }

  /// Gọi thủ công sau khi login thành công (nếu bạn không muốn dùng ever ở onInit)
  Future<void> onLoginSuccess() async {
    await _handlePostLogin();
  }

  /// Gọi thủ công khi logout
  Future<void> onLogout() async {
    _auth.isLoggedIn.value = false; // nếu flow của bạn không tự set
    await _handlePostLogout();
  }

  Future<void> _handlePostLogin() async {
    final uid = _auth.userId.value;
    if (uid <= 0) return;

    // XÓA trạng thái local của session & streak cho user vừa vào
    await _activity.resetSessionForNewUser();

    // Nạp dữ liệu 0 từ server (nếu server chưa có record sẽ trả 0)
    await _activity.refreshData(uid);

    // Bật auto session đếm thời gian (nếu bạn muốn)
    await _activity.ensureAutoSessionStarted(uid);
  }

  Future<void> _handlePostLogout() async {
    // Khi logout thì dừng session, xoá snapshot local
    // Không gọi API accumulate nữa
    final uid = _auth.userId.value;
    if (uid > 0) {
      await _activity.endStudySession(uid);
    } else {
      await _activity.persistSessionSnapshot(); // hoặc _activity.resetSessionForNewUser();
    }
  }
}
