import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl; // tránh trùng tên với intl DateFormat nếu bạn dùng
import '../controllers/auth_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  final _currentPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();

  bool _saving = false;
  bool _changingPw = false;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _auth = Get.find<AuthController>();

    // Prefill từ AuthController nếu có
    _nameCtrl.text = _auth.username.value.isNotEmpty ? _auth.username.value : '';
    _emailCtrl.text = _auth.email.value; // <— thêm dòng này

    // Nếu bạn có sẵn email/phone trong SharedPreferences hay controller,
    // có thể set vào _emailCtrl.text / _phoneCtrl.text ở đây.
    // Ví dụ:
    // _emailCtrl.text = _auth.email.value; // nếu có
    _phoneCtrl.text = _auth.phone.value; // nếu có
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _currentPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  // ======= Validators =======
  String? _nameV(String? v) {
    if (v == null || v.trim().isEmpty) return 'Tên không được để trống';
    if (v.trim().length < 2) return 'Tên quá ngắn';
    return null;
  }

  String? _emailV(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email không được để trống';
    final ok = RegExp(r"^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$").hasMatch(v.trim());
    return ok ? null : 'Email không hợp lệ';
  }

  String? _phoneV(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    final ok = RegExp(r"^(0|\+?84)[0-9]{9,10}$").hasMatch(v.trim());
    return ok ? null : 'Số điện thoại không hợp lệ';
  }

  String? _currentPwdV(String? v) {
    if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu hiện tại';
    return null;
  }

  String? _newPwdV(String? v) {
    if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu mới';
    if (v.length < 8) return 'Mật khẩu mới tối thiểu 8 ký tự';
    if (v == _currentPwdCtrl.text) return 'Mật khẩu mới phải khác mật khẩu hiện tại';
    return null;
  }

  String? _confirmPwdV(String? v) {
    if (v == null || v.isEmpty) return 'Vui lòng nhập lại mật khẩu mới';
    if (v != _newPwdCtrl.text) return 'Xác nhận mật khẩu không khớp';
    return null;
  }

  // ======= Submit handlers =======
  Future<void> _submitProfile() async {
    FocusScope.of(context).unfocus();
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      // Gọi controller (bạn sẽ implement ở AuthController)
      await _auth.updateMe(
        username: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );
      // ✅ Lưu phone cục bộ
      await _auth.saveLocalPhone(_phoneCtrl.text.trim());

      if (mounted) Get.back(); // quay lại sau khi lưu
    } catch (e) {
      // AuthController đã snackbar, ở đây không cần gì thêm
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submitPassword() async {
    FocusScope.of(context).unfocus();
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _changingPw = true);
    try {
      await _auth.changePassword(
        current: _currentPwdCtrl.text,
        next: _newPwdCtrl.text,
      );
      if (mounted) {
        _currentPwdCtrl.clear();
        _newPwdCtrl.clear();
        _confirmPwdCtrl.clear();
      }
    } catch (e) {
      // AuthController đã snackbar
    } finally {
      if (mounted) setState(() => _changingPw = false);
    }
  }

  // ======= UI helpers =======
  InputDecoration _dec({
    required String label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: Colors.blue, width: 1.2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chỉnh sửa hồ sơ', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _submitProfile,
            icon: _saving
                ? SizedBox(width: 16.w, height: 16.w, child: const CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_circle_outline),
            label: Text('Lưu', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ====== Profile form ======
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Form(
                    key: _profileFormKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Thông tin cá nhân', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
                        SizedBox(height: 14.h),

                        // Name
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: _dec(
                            label: 'Họ và tên',
                            hint: 'Nhập họ tên',
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: _nameV,
                        ),
                        SizedBox(height: 12.h),

                        // Email
                        TextFormField(
                          controller: _emailCtrl,
                          decoration: _dec(
                            label: 'Email',
                            hint: 'name@example.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: _emailV,
                        ),
                        SizedBox(height: 12.h),

                        // Phone
                        TextFormField(
                          controller: _phoneCtrl,
                          decoration: _dec(
                            label: 'Số điện thoại',
                            hint: '0xxxxxxxxx hoặc +84xxxxxxxxx',
                            prefixIcon: const Icon(Icons.phone_outlined),
                          ),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9\+]')),
                          ],
                          validator: _phoneV,
                        ),

                        SizedBox(height: 16.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _submitProfile,
                            icon: _saving
                                ? SizedBox(width: 16.w, height: 16.w, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.save_outlined),
                            label: Text('Lưu thay đổi', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              minimumSize: Size(double.infinity, 44.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 18.h),

              // ====== Change password ======
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Form(
                    key: _passwordFormKey,
                    autovalidateMode: AutovalidateMode.disabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Đổi mật khẩu', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
                        SizedBox(height: 14.h),

                        // Current password
                        TextFormField(
                          controller: _currentPwdCtrl,
                          decoration: _dec(
                            label: 'Mật khẩu hiện tại',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_showCurrent ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _showCurrent = !_showCurrent),
                            ),
                          ),
                          obscureText: !_showCurrent,
                          textInputAction: TextInputAction.next,
                          validator: _currentPwdV,
                        ),
                        SizedBox(height: 12.h),

                        // New password
                        TextFormField(
                          controller: _newPwdCtrl,
                          decoration: _dec(
                            label: 'Mật khẩu mới',
                            prefixIcon: const Icon(Icons.lock_reset_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(_showNew ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _showNew = !_showNew),
                            ),
                          ),
                          obscureText: !_showNew,
                          textInputAction: TextInputAction.next,
                          validator: _newPwdV,
                        ),
                        SizedBox(height: 12.h),

                        // Confirm password
                        TextFormField(
                          controller: _confirmPwdCtrl,
                          decoration: _dec(
                            label: 'Xác nhận mật khẩu mới',
                            prefixIcon: const Icon(Icons.verified_user_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _showConfirm = !_showConfirm),
                            ),
                          ),
                          obscureText: !_showConfirm,
                          textInputAction: TextInputAction.done,
                          validator: _confirmPwdV,
                        ),

                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _changingPw ? null : _submitPassword,
                                icon: _changingPw
                                    ? SizedBox(width: 16.w, height: 16.w, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.password_outlined),
                                label: Text('Đổi mật khẩu', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  foregroundColor: Colors.white,
                                  minimumSize: Size(double.infinity, 44.h),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 8.h),
              Center(
                child: Text(
                  'Lưu ý: Email thay đổi có thể cần xác thực theo chính sách hệ thống.',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }
}
