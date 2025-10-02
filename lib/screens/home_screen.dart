import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:flutter_elearning_application/controllers/auth_controller.dart';
import '../app/routes/app_routes.dart';
import 'package:flutter_elearning_application/widgets/home_top_summary.dart';


class HomeScreen extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();

  HomeScreen({super.key});

  final Map<String, dynamic> subjectIcons = {
    'Toán': 'assets/icon/toan.png',
    'Khoa Học Tự Nhiên': 'assets/icon/khoahoctunhien.png',
    'Ngữ Văn': 'assets/icon/nguvan.png',
    'Tiếng Anh': 'assets/icon/tienganh.png',
  };

  final Map<String, Color> subjectColors = {
    'Toán': Colors.blue,
    'Khoa Học Tự Nhiên': Colors.green,
    'Ngữ Văn': Colors.orange,
    'Tiếng Anh': Colors.purple,
  };

  void _showClassSelector() {
    Get.bottomSheet(
      Obx(() {
        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Chọn lớp học của bạn",
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20.h),
              Wrap(
                spacing: 12.w,
                runSpacing: 12.h,
                children: authController.classes.map((String value) {
                  final isSelected = authController.selectedClass.value == value;
                  return GestureDetector(
                    onTap: () {
                      authController.setSelectedClass(value);
                      Get.back();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blueAccent : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ]
                            : [],
                      ),
                      child: Text(
                        "Lớp $value",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 20.h),
              if (!authController.isClassSelected.value)
                Text(
                  "⚠ Bạn phải chọn lớp để tiếp tục",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        );
      }),
      isDismissible: false,
      enableDrag: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!authController.isClassSelected.value) {
        _showClassSelector();
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(() {
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h + 56.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== Thanh tìm kiếm =====
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/icon/icon_search.png',
                        width: 22.w,
                        height: 22.h,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: "Tìm kiếm bài học...",
                            border: InputBorder.none,
                          ),
                          style: TextStyle(fontSize: 14.sp),
                          readOnly: true,
                          onTap: () => Get.toNamed(AppRoutes.search),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                // ===== Tiêu đề =====
                Text(
                  "Xin chào, ${authController.username.value} 👋",
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  "Chào mừng bạn quay trở lại E-learning App!",
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                ),
                SizedBox(height: 12.h),

                // ===== 3 card tổng quan (responsive) =====
                // HomeTopSummary đã tự responsive & không cuộn, chỉ việc gắn vào là chạy
                const HomeTopSummary(),

                SizedBox(height: 20.h),

                // ===== Danh sách môn học =====
                if (authController.isClassSelected.value) ...[
                  Text(
                    "Lớp ${authController.selectedClass.value}",
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _buildSubjectsGrid(),
                ],
                SizedBox(height: 8.h), // đệm thêm một chút là đẹp
              ],
            ),
          );
        }),
      ),
    );
  }

  // ===== Dashboard dạng list cho màn hình nhỏ (giữ lại nếu sau này dùng) =====
  Widget _buildDashboardList() {
    return Column(
      children: [
        _buildDashboardCard(title: "Quiz", value: "12", icon: Icons.quiz, color: Colors.blue, isListMode: true),
        SizedBox(height: 12.h),
        _buildDashboardCard(title: "Videos", value: "8", icon: Icons.play_circle_fill, color: Colors.green, isListMode: true),
        SizedBox(height: 12.h),
        _buildDashboardCard(title: "Điểm cao", value: "95", icon: Icons.star, color: Colors.orange, isListMode: true),
      ],
    );
  }

  // ===== Dashboard dạng grid cho màn hình bình thường (giữ lại nếu sau này dùng) =====
  Widget _buildDashboardGrid() {
    return Row(
      children: [
        Expanded(child: _buildDashboardCard(title: "Quiz", value: "12", icon: Icons.quiz, color: Colors.blue)),
        SizedBox(width: 10.w),
        Expanded(child: _buildDashboardCard(title: "Videos", value: "8", icon: Icons.play_circle_fill, color: Colors.green)),
        SizedBox(width: 10.w),
        Expanded(child: _buildDashboardCard(title: "Điểm cao", value: "95", icon: Icons.star, color: Colors.orange)),
      ],
    );
  }

  // ===== Dashboard Card - ĐÃ ĐIỀU CHỈNH =====
  Widget _buildDashboardCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isListMode = false,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, double scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: isListMode ? double.infinity : null,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: isListMode ? 28.sp : 32.sp),
                SizedBox(height: 8.h),
                Text(
                  value,
                  style: TextStyle(fontSize: isListMode ? 18.sp : 20.sp, fontWeight: FontWeight.bold, color: color),
                ),
                SizedBox(height: 4.h),
                Text(title, style: TextStyle(fontSize: isListMode ? 12.sp : 14.sp, color: Colors.black87), textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== GridView môn học responsive =====
  Widget _buildSubjectsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final crossAxisCount = screenWidth < 300 ? 1 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: authController.subjects.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 14.h,
            crossAxisSpacing: 14.w,
            childAspectRatio: crossAxisCount == 1 ? 3.5 : 0.9,
          ),
          itemBuilder: (context, index) {
            final subject = authController.subjects[index];
            return _buildSubjectCard(subject, crossAxisCount == 1);
          },
        );
      },
    );
  }

  // ===== Card môn học responsive =====
  Widget _buildSubjectCard(String subject, bool isListMode) {
    return GestureDetector(
      onTap: () {
        final grade = int.tryParse(authController.selectedClass.value) ?? 0;
        Get.toNamed(AppRoutes.subjectDetail, arguments: {'grade': grade, 'subject': subject});
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isListMode ? 16.h : 12.h,
          horizontal: isListMode ? 20.w : 10.w,
        ),
        decoration: BoxDecoration(
          color: subjectColors[subject]!.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: subjectColors[subject]!.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: subjectColors[subject]!.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: isListMode
            ? Row(
          children: [
            subjectIcons[subject] is IconData
                ? Icon(subjectIcons[subject], color: subjectColors[subject], size: 32.sp)
                : Image.asset(subjectIcons[subject], width: 32.w, height: 32.h, fit: BoxFit.contain),
            SizedBox(width: 12.w),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  subject,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: subjectColors[subject],
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16.w, color: Colors.grey),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            subjectIcons[subject] is IconData
                ? Icon(subjectIcons[subject], color: subjectColors[subject], size: 35.sp)
                : Image.asset(subjectIcons[subject], width: 35.w, height: 35.h, fit: BoxFit.contain),
            SizedBox(height: 8.h),
            Text(
              subject,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.bold, color: subjectColors[subject], fontSize: 13.sp),
            ),
          ],
        ),
      ),
    );
  }
}
